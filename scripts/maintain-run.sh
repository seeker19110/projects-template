#!/usr/bin/env bash
# maintain-run.sh — Chạy agent bảo trì `maintainer` bằng TÀI KHOẢN SUBSCRIPTION CỤC BỘ, mọi
# nhà cung cấp AI (harness), không cần API key, không cần Claude Code.
#
# Vì sao tồn tại: `/maintain` chỉ chạy được trong Claude Code. Người dùng vận hành bảo trì bằng
# CLI đã đăng nhập gói tháng trên máy mình (Claude Code `claude -p`, Hermes Agent `hermes chat`
# với pool provider/OAuth của nó — tham chiếu donghanhcungban/hermes-agents provider
# `claude-code-cli`/`antigravity`, OpenAI Codex `codex exec`, OpenCode `opencode run`). Script này
# GOM 3 bước: (1) đo bằng `maintenance-sweep.sh` → (2) dựng prompt vai `maintainer` bằng
# `subagent-dispatch.sh` (nạp đúng .claude/agents/maintainer.md) → (3) giao cho CLI cục bộ đang có,
# rồi ghi telemetry. Không có CLI nào → in prompt ra file để dán vào bất kỳ chat nào (`print`).
#
# CÚ PHÁP CLI DƯỚI ĐÂY LÀ CÚ PHÁP ĐÃ XÁC MINH (hermes-agents/skills/cli-provider-bridges +
# doubt-driven-development + opencode; 2026-09-14). Harness chưa xác minh cú pháp (Gemini CLI,
# Cursor…) KHÔNG được kê — dùng `print` rồi dán tay. Không bịa cờ (CLAUDE.md §4).
#   claude   : claude -p --model <alias> < prompt       (đăng nhập `claude auth login`; KHÔNG --bare)
#   hermes   : hermes chat -q "<prompt>" [--provider P] [-m M]
#   codex    : codex exec -C <repo> - < prompt
#   opencode : opencode run "<prompt>"
#   gemini   : = hermes --provider antigravity -m gemini-3.7-flash  (Gemini đi QUA Hermes + bridge
#              Antigravity OAuth của hermes-agents; model expose: gemini-3.7-flash[-medium|-low],
#              gemini-3.6-flash, gemini-3.5-flash, gemini-3.1-pro — xem plugin/__init__.py ở repo đó)
#
# Dùng: scripts/maintain-run.sh [--harness auto|claude|hermes|gemini|codex|opencode|print]
#         [--model M] [--provider P] [--mode quick|default|full] [--dry-run] [--prompt-out FILE]
#   --harness   auto (mặc định) = CLI đầu tiên tìm thấy theo thứ tự claude→hermes→codex→opencode→print
#   --model     alias/model truyền cho CLI (claude: sonnet|opus|haiku; hermes: -m; mặc định theo agent)
#   --provider  chỉ hermes: --provider (vd claude-code-cli, antigravity, openai-codex)
#   --mode      quick = sweep --no-deps · full = sweep --gate · default = sweep thường
#   --dry-run   in lệnh sẽ chạy + đường dẫn prompt, KHÔNG gọi CLI, KHÔNG ghi telemetry
#   Biến môi trường: MAINT_HARNESS, MAINT_MODEL, MAINT_PROVIDER (tương đương cờ);
#   MAINT_BIN_<HARNESS> = đường dẫn CLI thay cho PATH (vd MAINT_BIN_CLAUDE=/opt/claude).
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
HARNESS="${MAINT_HARNESS:-auto}"; MODEL="${MAINT_MODEL:-}"; PROVIDER="${MAINT_PROVIDER:-}"
MODE="default"; DRY=0; PROMPT_OUT=""
REPORT="docs/ops/MAINTENANCE-REPORT.md"

log() { printf '[maintain-run] %s\n' "$*" >&2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --harness)    HARNESS="${2:-}"; shift 2 ;;
    --model)      MODEL="${2:-}"; shift 2 ;;
    --provider)   PROVIDER="${2:-}"; shift 2 ;;
    --mode)       MODE="${2:-}"; shift 2 ;;
    --dry-run)    DRY=1; shift ;;
    --prompt-out) PROMPT_OUT="${2:-}"; shift 2 ;;
    -h|--help)    sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log "tham số lạ: $1"; exit 2 ;;
  esac
done
case "$HARNESS" in auto|claude|hermes|gemini|codex|opencode|print) ;; *) log "harness không hỗ trợ: '$HARNESS' (auto|claude|hermes|gemini|codex|opencode|print)"; exit 2 ;; esac
# gemini = alias: Gemini không có CLI subscription riêng ở đây; nó đi qua Hermes + provider antigravity.
if [ "$HARNESS" = gemini ]; then HARNESS=hermes; PROVIDER="${PROVIDER:-antigravity}"; MODEL="${MODEL:-gemini-3.7-flash}"; log "gemini → hermes --provider $PROVIDER -m $MODEL"; fi
case "$MODE" in quick|default|full) ;; *) log "mode không hợp lệ: '$MODE' (quick|default|full)"; exit 2 ;; esac

cd "$ROOT" || exit 2
for need in scripts/maintenance-sweep.sh scripts/subagent-dispatch.sh .claude/agents/maintainer.md; do
  [ -f "$need" ] || { log "thiếu $need — chạy lại copy-framework.sh từ repo khung"; exit 3; }
done

# CLI của một harness: ưu tiên MAINT_BIN_<HARNESS>, rồi PATH. In đường dẫn hoặc rỗng.
cli_of() {
  local h="$1" override
  override="$(eval "printf '%s' \"\${MAINT_BIN_${h^^}:-}\"")"
  if [ -n "$override" ]; then [ -x "$override" ] && printf '%s' "$override"; return 0; fi
  command -v "$h" 2>/dev/null || true
}
if [ "$HARNESS" = auto ]; then
  HARNESS=print
  for h in claude hermes codex opencode; do [ -n "$(cli_of "$h")" ] && { HARNESS="$h"; break; }; done
  log "harness tự chọn: $HARNESS"
fi
BIN=""
if [ "$HARNESS" != print ]; then
  BIN="$(cli_of "$HARNESS")"
  [ -n "$BIN" ] || { log "không tìm thấy CLI '$HARNESS' trong PATH (hoặc MAINT_BIN_${HARNESS^^}). Cài + đăng nhập subscription, hoặc dùng --harness print."; exit 3; }
fi

# ── (1) Đo ───────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$REPORT")"
sweep_args=(--out "$REPORT")
case "$MODE" in quick) sweep_args+=(--no-deps) ;; full) sweep_args+=(--gate) ;; esac
bash scripts/maintenance-sweep.sh "${sweep_args[@]}"   # luôn exit 0 (không --strict)
counts="$(grep -m1 -oE '🔴 [0-9]+ · 🟡 [0-9]+' "$REPORT" || echo '?')"
log "sweep xong: $counts → $REPORT"

# ── (2) Dựng prompt vai maintainer (đọc thẳng .claude/agents/maintainer.md) ─────
PROMPT_FILE="${PROMPT_OUT:-$(mktemp "${TMPDIR:-/tmp}/maintainer-prompt.XXXXXX")}"
TASK="Bạn đang chạy KHÔNG trong Claude Code mà qua CLI '$HARNESS' bằng tài khoản subscription cục bộ của người dùng, trong thư mục $ROOT. \
Làm đúng mục 'Bạn LÀM' theo thứ tự: báo cáo quét ĐÃ có sẵn ở $REPORT (nội dung đính kèm dưới) — KHÔNG chạy lại sweep trừ khi cần xác minh một dòng. \
Triage từng phát hiện, rồi viết docs/ops/MAINTENANCE-PLAN.md theo mẫu và DỪNG chờ duyệt. Không sửa source, không commit. \
Kết thúc bằng khối 'Trả kết quả' đúng định dạng."
if ! bash scripts/subagent-dispatch.sh --agent maintainer --harness generic --task "$TASK" --context-file "$REPORT" > "$PROMPT_FILE"; then
  log "subagent-dispatch thất bại (cần Python 3)"; exit 3
fi
log "prompt: $PROMPT_FILE ($(wc -c <"$PROMPT_FILE") byte)"

# ── (3) Giao cho CLI cục bộ ──────────────────────────────────────────────────
# Lệnh dựng dưới dạng MẢNG (không ghép chuỗi shell) — prompt không bao giờ đi qua eval.
cmd=()
case "$HARNESS" in
  claude)   cmd=("$BIN" -p --model "${MODEL:-sonnet}") ;;                       # prompt qua stdin
  hermes)   cmd=("$BIN" chat -q "$(cat "$PROMPT_FILE")"); [ -n "$PROVIDER" ] && cmd+=(--provider "$PROVIDER"); [ -n "$MODEL" ] && cmd+=(-m "$MODEL") ;;
  codex)    cmd=("$BIN" exec -C "$ROOT" -) ;;                                   # prompt qua stdin
  opencode) cmd=("$BIN" run "$(cat "$PROMPT_FILE")"); [ -n "$MODEL" ] && cmd+=(--model "$MODEL") ;;
  print)    ;;
esac

if [ "$HARNESS" = print ]; then
  log "không gọi CLI nào — dán nội dung $PROMPT_FILE vào chat của nhà cung cấp AI bạn dùng (bất kỳ)."
  [ -n "$PROMPT_OUT" ] || cat "$PROMPT_FILE"
  exit 0
fi
if [ "$DRY" -eq 1 ]; then
  printf 'DRY-RUN harness=%s bin=%s\n' "$HARNESS" "$BIN"
  case "$HARNESS" in claude|codex) printf 'CMD: %s  < %s\n' "${cmd[*]}" "$PROMPT_FILE" ;; *) printf 'CMD: %s %s "<prompt %s>"' "$BIN" "${cmd[1]}" "$PROMPT_FILE"; printf ' %s' "${cmd[@]:3}"; printf '\n' ;; esac
  exit 0
fi

start="$(date +%s)"
case "$HARNESS" in
  claude|codex) "${cmd[@]}" < "$PROMPT_FILE" ;;
  *)            "${cmd[@]}" < /dev/null ;;   # prompt đã nằm trong argv — đóng stdin kẻo CLI chờ stdin của tiến trình gọi (treo vô hạn khi chạy từ cron/agent nền)
esac
rc=$?
dur=$(( $(date +%s) - start ))
status=PASSED; [ "$rc" -eq 0 ] || status=FAILED
[ -f scripts/telemetry-log.sh ] && bash scripts/telemetry-log.sh --record --agent maintainer --harness "$HARNESS" \
  --provider "${PROVIDER:-$HARNESS}" --model "${MODEL:-default}" --task "maintain $MODE" --duration "$dur" --test-status "$status" >/dev/null 2>&1 || true
log "harness '$HARNESS' thoát $rc sau ${dur}s. Kế hoạch (nếu agent viết): docs/ops/MAINTENANCE-PLAN.md — đọc, duyệt, rồi thực thi từng PR qua /gate."
exit "$rc"
