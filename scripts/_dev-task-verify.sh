#!/usr/bin/env bash
# _dev-task-verify.sh — evidence-check (LD-03) + review-check (LD-04) của scripts/dev-task.sh (`source`, KHÔNG chạy
# trực tiếp). Tách 2026-10-10 vì dev-task.sh vượt 400 dòng (radar). Dùng hàm/biến của dev-task.sh lúc GỌI:
# log, blocked, gate_context, worktree_snapshot, worktree_id, ROOT. Phát sang dự án đích cùng dev-task.sh (manifest, TRAPS mục 19).

# --- evidence-check: đối chiếu evidence với phiên bản HIỆN TẠI ---------------
# Bắt evidence cũ (HEAD/config/working tree đã đổi), evidence thiếu task hoặc không PASS.
# KHÔNG phải chữ ký: file viết tay khớp cây hiện tại vẫn không bị phát hiện — nghiệm thu
# tích hợp dựa trên CI của đúng commit; lệnh này để không tin lời "đã PASS" cũ/thiếu.
evidence_current_mismatch() {  # $1=file → in tên trường lệch so với hiện tại
  local field want got
  for field in head config_sha worktree; do
    want="$(jq -r ".$field" "$1")"
    case "$field" in
      head) got="${GATE_CONTEXT%%:*}" ;;
      config_sha) got="${GATE_CONTEXT#*:}" ;;
      worktree) got="$(worktree_id)" ;;
    esac
    [ "$want" = "$got" ] || printf '%s ' "$field"
  done
}
evidence_check() {
  local f="${1:-}" status stale
  [ -n "$f" ] && [ -f "$f" ] || { blocked "không có file evidence: ${f:-<thiếu đường dẫn>}"; return 2; }
  command -v jq >/dev/null 2>&1 || { blocked 'thiếu jq để đọc evidence'; return 2; }
  jq -e '.schema == "gate-evidence/1"' "$f" >/dev/null 2>&1 || { blocked "evidence hỏng hoặc sai schema: $f"; return 2; }
  status="$(jq -r .status "$f")"
  [ "$status" = PASS ] || { log "REJECTED: evidence không phải PASS (status=$status)"; return 1; }
  jq -e '([.checks[].task] == ["build","typecheck","lint","test"])
    and all(.checks[]; .status == "PASS" or (.status == "N/A" and (.reason // "") != ""))
    and any(.checks[]; .status == "PASS")' "$f" >/dev/null \
    || { log 'INCOMPLETE: evidence phải có đủ build/typecheck/lint/test, mỗi task PASS hoặc N/A có lý do'; return 1; }
  [ "$(jq -r .worktree "$f")" != no-git ] || { blocked 'evidence tạo ngoài git — không gắn được phiên bản'; return 2; }
  GATE_CONTEXT="$(gate_context)" && worktree_snapshot || { blocked 'không đọc được phiên bản hiện tại'; return 2; }
  stale="$(evidence_current_mismatch "$f")"
  [ -z "$stale" ] || { log "STALE: evidence không thuộc phiên bản hiện tại (lệch: $stale) — chạy lại gate"; return 1; }
  log "VERIFIED: evidence PASS khớp HEAD/config/working tree hiện tại. Không phải chữ ký; CI của đúng commit là nguồn nghiệm thu tích hợp."
}

# --- review-check: finding phải có căn cứ, repair theo đúng nguyên nhân (LD-04) --
# Schema review-findings/1: {findings:[{id,kind,location,scenario,evidence}]}. kind:
#   defect           → REPAIR-CODE: lỗi code thật; bắt buộc path:line có trong repo, test đỏ trước khi sửa
#   missing-evidence → RERUN-EVIDENCE: bằng chứng thiếu/cũ (vd evidence-check STALE) — chạy lại, KHÔNG sửa code
#   missing-input    → ASK-UPSTREAM: spec/AC/thiết kế thiếu — hỏi hoặc sửa tầng trên, KHÔNG sửa code
#   cleanup          → OPTIONAL: gợi ý không chặn
# Finding thiếu kịch bản/bằng chứng, kind lạ, hoặc defect không trỏ được dòng có thật → UNSUPPORTED (exit 1).
location_exists() {  # $1=path:line → true nếu path nằm trong ROOT và có dòng đó
  local path="${1%:*}" line="${1##*:}" n
  case "$path" in ''|/*|../*|*/../*) return 1 ;; esac
  [[ "$line" =~ ^[1-9][0-9]*$ ]] && [ -f "$ROOT/$path" ] || return 1
  n="$(awk 'END { print NR }' "$ROOT/$path")"; [ "$line" -le "$n" ]
}
review_action() {  # $1=kind $2=location → nhãn hành động; rỗng nếu finding không có căn cứ
  case "$1" in
    defect) location_exists "$2" && echo REPAIR-CODE ;;
    missing-evidence) echo RERUN-EVIDENCE ;;
    missing-input) echo ASK-UPSTREAM ;;
    cleanup) echo OPTIONAL ;;
  esac
}
review_check() {
  local f="${1:-}" id kind loc action rejected=0 total=0
  [ -n "$f" ] && [ -f "$f" ] || { blocked "không có file findings: ${f:-<thiếu đường dẫn>}"; return 2; }
  command -v jq >/dev/null 2>&1 || { blocked 'thiếu jq để đọc findings'; return 2; }
  jq -e '.schema == "review-findings/1" and (.findings | type == "array")' "$f" >/dev/null 2>&1 \
    || { blocked "findings hỏng hoặc sai schema (cần review-findings/1): $f"; return 2; }
  while IFS=$'\x1f' read -r id kind loc; do   # \x1f không phải khoảng trắng: trường rỗng không bị gộp
    total=$((total + 1)); action="$(review_action "$kind" "$loc")"
    [ "$id" != '-' ] && [ -n "$action" ] || { rejected=$((rejected + 1)); log "UNSUPPORTED $id: thiếu căn cứ (kind/kịch bản/bằng chứng/path:line có thật)"; continue; }
    log "$action $id${loc:+ @ $loc}"
  done < <(jq -r '.findings[] | [(if ((.id // "") | tostring) == "" then "-" else .id end),
      (if ((.scenario // "") | length) > 0 and ((.evidence // "") | length) > 0 then (.kind // "") else "" end),
      (.location // "")] | map(tostring | gsub("[\u001f\r\n]"; " ")) | join("\u001f")' "$f" | tr -d '\r')
  # tr: jq trên Windows in CRLF; `$(...)` của Git Bash bỏ \r nhưng `read` từ process substitution thì không.
  [ "$rejected" -eq 0 ] || { log "REJECTED: $rejected/$total finding không có căn cứ — bổ sung bằng chứng, không sửa code theo chúng"; return 1; }
  [ "$total" -gt 0 ] || log 'CLEAN: không có finding'
}
