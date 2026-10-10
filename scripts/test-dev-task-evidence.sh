#!/usr/bin/env bash
# test-dev-task-evidence.sh — dev-task.sh: BẰNG CHỨNG (LD-03) và REVIEW CÓ CĂN CỨ (LD-04).
# Tách khỏi test-dev-task.sh 2026-10-09 (file vượt 400 dòng); helper dùng chung ở _dev-task-test-lib.sh.
#   7b: lệnh giả/no-op bị chặn, 0 ca test = đỏ, evidence gắn HEAD/config/working tree, ghi evidence lỗi I/O
#   7c: review-findings/1 — finding không căn cứ bị loại, thiếu evidence/input không sinh REPAIR-CODE, jq CRLF
# Chạy: bash scripts/test-dev-task-evidence.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

# shellcheck source=scripts/_dev-task-test-lib.sh
source "$(dirname "$0")/_dev-task-test-lib.sh"

# --- LD-03: lệnh giả, zero-test, bằng chứng gắn đúng phiên bản (AC-3 của lean-delivery) ---
noop_tests() {
  local d i=0 cmd
  for cmd in 'true' ':' 'echo ok' 'exit 0' 'printf done'; do
    i=$((i+1)); d="$(gate_fixture "gate-noop-$i")"; printf "test='%s'\n" "$cmd" >> "$d/.claude/project-commands.sh"
    gate_case "$d" 2 'no-op'
  done
  d="$(gate_fixture gate-noop-doctor)"; printf "build=':'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 'no-op' doctor
  d="$(gate_fixture gate-pass-no-tests)"; printf "test='npx vitest run --passWithNoTests'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 2 'passWithNoTests'
  d="$(gate_fixture gate-exit-nonzero)"; printf "test='exit 3'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 1 FAIL
  d="$(gate_fixture gate-echo-piped)"; printf "test='echo 42 | grep -q 41'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 1 FAIL   # echo nối ống vào một phép kiểm thật không phải no-op: phải chạy và đỏ
}
count_fixture() {  # $1=tên $2=số ca test in ra
  local d; d="$(gate_fixture "$1")"
  printf 'echo "Ran %s tests"\n' "$2" > "$d/run-tests.sh"
  printf "test='bash run-tests.sh'\ngate_test_count_regex='Ran ([0-9]+) tests'\n" >> "$d/.claude/project-commands.sh"
  printf '%s' "$d"
}
count_tests() {
  local d
  d="$(count_fixture gate-zero-tests 0)"; gate_case "$d" 1 '0 ca'
  d="$(count_fixture gate-three-tests 3)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$WORK/count.json" >"$WORK/gate-output" 2>&1
  [ "$(jq -r .test_cases "$WORK/count.json" 2>/dev/null)" = 3 ] && ok "số ca test ghi vào evidence (3)" || bad "evidence không ghi số ca test"
  d="$(gate_fixture gate-unknown-count)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$WORK/unknown.json" >"$WORK/gate-output" 2>&1
  [ "$(jq -r .test_cases "$WORK/unknown.json" 2>/dev/null)" = null ] && ok "không khai regex → test_cases null (không biết), không phải 0" || bad "số ca test không biết bị ghi thành số"
}
fixture_git() {  # git trong fixture, danh tính cố định (không đọc cấu hình máy)
  git -C "$1" -c user.name=fixture -c user.email=fixture@example.invalid "${@:2}"
}
git_fixture() {  # repo git sạch: config + file nguồn đã ghi vào HEAD, out/ bị ignore
  local d; d="$(gate_fixture "$1")"
  mkdir -p "$d/out"; printf 'out/\n' > "$d/.gitignore"; printf 'v1\n' > "$d/src.txt"
  git -C "$d" init -q && git -C "$d" add -A && fixture_git "$d" commit -qm 'test: baseline'
  printf '%s' "$d"
}
ev_check() {  # $1=fixture $2=evidence $3=exit mong đợi $4=dấu hiệu $5=mô tả
  local rc; CLAUDE_PROJECT_DIR="$1" bash "$DT" evidence-check "$2" >"$WORK/ev-output" 2>&1; rc=$?
  if [ "$rc" -eq "$3" ] && grep -q "$4" "$WORK/ev-output"; then ok "$5 → exit $rc"; else bad "$5: mong exit $3/$4, được $rc"; cat "$WORK/ev-output"; fi
}
evidence_tests() {
  local d ev
  d="$(git_fixture gate-evidence)"; ev="$d/out/gate.json"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$ev" >"$WORK/gate-output" 2>&1 || bad "gate xanh nhưng exit khác 0"
  if [ "$(jq -r '[.schema,.status,.head,([.checks[]|select(.status=="PASS")]|length|tostring)]|join(" ")' "$ev" 2>/dev/null)" = "gate-evidence/1 PASS $(git -C "$d" rev-parse HEAD) 4" ]; then
    ok "evidence PASS gắn HEAD, đủ 4 kiểm tra đã chạy"
  else bad "evidence PASS thiếu trường/HEAD/kiểm tra"; cat "$ev" 2>/dev/null; fi
  ev_check "$d" "$ev" 0 VERIFIED "evidence khớp cây hiện tại"
  printf 'v2\n' > "$d/src.txt"; ev_check "$d" "$ev" 1 STALE "mã đổi sau kiểm tra → evidence cũ"
  printf 'v1\n' > "$d/src.txt"; ev_check "$d" "$ev" 0 VERIFIED "trả nội dung cũ → khớp lại (vân tay theo nội dung)"
  printf 'x\n' > "$d/new-untracked.txt"; ev_check "$d" "$ev" 1 STALE "file mới chưa ignore sau kiểm tra → evidence cũ"; rm "$d/new-untracked.txt"
  jq '.checks[3].status="NOT_RUN"' "$ev" > "$d/out/forged.json"; ev_check "$d" "$d/out/forged.json" 1 INCOMPLETE "evidence có task chưa chạy"
  jq 'del(.checks[3])' "$ev" > "$d/out/short.json"; ev_check "$d" "$d/out/short.json" 1 INCOMPLETE "evidence bỏ sót task test"
  jq '.status="FAIL"' "$ev" > "$d/out/fail.json"; ev_check "$d" "$d/out/fail.json" 1 'không phải PASS' "evidence FAIL không được nghiệm thu"
  printf '{' > "$d/out/bad.json"; ev_check "$d" "$d/out/bad.json" 2 BLOCKED "evidence hỏng → BLOCKED"
  ev_check "$d" "$d/out/khong-co.json" 2 BLOCKED "thiếu file evidence → BLOCKED"
  fixture_git "$d" commit --allow-empty -qm 'test: next'
  ev_check "$d" "$ev" 1 STALE "HEAD mới sau kiểm tra → evidence cũ"
  printf "lint='exit 4'\n" >> "$d/.claude/project-commands.sh"
  CLAUDE_PROJECT_DIR="$d" GATE_EVIDENCE="$ev" bash "$DT" gate >"$WORK/gate-output" 2>&1
  [ "$(jq -r '[.status,(.checks[]|.status)]|join(" ")' "$ev" 2>/dev/null)" = "FAIL PASS PASS FAIL NOT_RUN" ] \
    && ok "evidence FAIL ghi đúng task hỏng; task sau là NOT_RUN" || { bad "evidence FAIL sai trạng thái từng task"; cat "$ev"; }
  printf "test=''\n" >> "$d/.claude/project-commands.sh"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$ev" >"$WORK/gate-output" 2>&1
  [ "$(jq -r .status "$ev" 2>/dev/null)" = BLOCKED ] && ok "BLOCKED ghi đè evidence cũ (không để lại PASS cũ)" || bad "BLOCKED để lại evidence cũ"
}
evidence_binding_tests() {
  local d rc
  d="$(git_fixture gate-evidence-tracked)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/gate.json" >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && grep -q 'ignore' "$WORK/gate-output" && ok "evidence ghi vào cây chưa ignore → BLOCKED" || bad "evidence trong cây làm bẩn chính phiên bản được kiểm (exit $rc)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/src.txt" >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && [ "$(cat "$d/src.txt" 2>/dev/null)" = v1 ] && ok "--evidence trỏ nhầm file đã theo dõi → BLOCKED, file không bị xoá" || bad "--evidence xoá/ghi đè file nguồn đã theo dõi (exit $rc)"
  d="$(git_fixture gate-mutates-tracked)"; printf 'printf "v9\\n" > src.txt\n' > "$d/out/mutate.sh"
  printf "test='bash out/mutate.sh'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 'working tree'
  d="$(git_fixture gate-creates-artifact)"; printf 'printf "a\\n" > artifact.txt\n' > "$d/out/make.sh"
  printf "test='bash out/make.sh'\n" >> "$d/.claude/project-commands.sh"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/out/gate.json" >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q 'artifact.txt' "$WORK/gate-output" && ok "file mới sinh khi kiểm → PASS kèm cảnh báo tên file" || bad "file sinh mới bị chặn oan hoặc không được báo (exit $rc)"
  ev_check "$d" "$d/out/gate.json" 0 VERIFIED "evidence tính cả file sinh mới"
  # Lượt sau ghi lại chính artifact chưa ignore đó (vd __pycache__ ở dự án chưa có .gitignore): đây là output
  # build, không phải mã nguồn — chặn sẽ làm mọi lượt gate thứ hai đỏ oan (suite adoption Python đã bắt được).
  printf 'printf "b\\n" > artifact.txt\n' > "$d/out/make.sh"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q 'WARN.*artifact.txt' "$WORK/gate-output" && ok "artifact chưa ignore bị ghi lại → PASS kèm cảnh báo" || bad "artifact chưa ignore bị ghi lại làm gate chặn oan (exit $rc)"
  d="$(gate_fixture gate-evidence-nogit)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$WORK/nogit.json" >"$WORK/gate-output" 2>&1
  ev_check "$d" "$WORK/nogit.json" 2 BLOCKED "ngoài git → không gắn được phiên bản"
}
evidence_write_failure_tests() {
  local d rc scenario
  for scenario in missing-parent destination-directory failed-check; do
    d="$(git_fixture "gate-evidence-write-$scenario")"
    if [ "$scenario" = missing-parent ]; then
      printf "test='rmdir out'\n" >> "$d/.claude/project-commands.sh"
    elif [ "$scenario" = destination-directory ]; then
      printf "test='mkdir out/gate.json'\n" >> "$d/.claude/project-commands.sh"
    else
      printf "test='rmdir out; exit 7'\n" >> "$d/.claude/project-commands.sh"
    fi
    CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/out/gate.json" >"$WORK/gate-output" 2>&1; rc=$?
    if [ "$rc" -eq 2 ] && grep -q 'BLOCKED.*evidence' "$WORK/gate-output" && ! grep -q 'PASS:' "$WORK/gate-output"; then
      ok "$scenario: không lưu được evidence → BLOCKED, không báo PASS"
    else
      bad "$scenario: evidence không ghi được nhưng exit $rc"
      cat "$WORK/gate-output"
    fi
    [ -z "$(find "$d" -name 'gate.json.tmp.*' -print)" ] && ok "$scenario: không để lại evidence tạm" || bad "$scenario: còn evidence tạm"
  done
}
nested_repo_tests() {  # repo git lồng chưa theo dõi (vd .claude/worktrees/agent-*) → ls-files -o in "dir/" (2026-10-10)
  local d rc
  d="$(git_fixture gate-nested-repo)"; mkdir -p "$d/vendor/lib"; printf 'x\n' > "$d/vendor/lib/f.txt"
  git -C "$d/vendor/lib" init -q && git -C "$d/vendor/lib" add -A && fixture_git "$d/vendor/lib" commit -qm 'test: nested'
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/out/gate.json" >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && ok "repo lồng chưa theo dõi → gate PASS (bỏ mục thư mục khỏi vân tay)" || { bad "repo lồng chưa theo dõi làm gate exit $rc"; cat "$WORK/gate-output"; }
  ev_check "$d" "$d/out/gate.json" 0 VERIFIED "evidence khớp khi có repo lồng chưa theo dõi"
}
echo "== 7b. Bằng chứng: lệnh giả, zero-test, evidence gắn phiên bản (LD-03) =="
noop_tests
count_tests
evidence_tests
evidence_binding_tests
nested_repo_tests
evidence_write_failure_tests

rv_check() {  # $1=fixture $2=findings $3=exit mong đợi $4=dấu hiệu $5=mô tả
  local rc; CLAUDE_PROJECT_DIR="$1" bash "$DT" review-check "$2" >"$WORK/rv-output" 2>&1; rc=$?
  if [ "$rc" -eq "$3" ] && grep -q -- "$4" "$WORK/rv-output"; then ok "$5 → exit $rc"; else bad "$5: mong exit $3/$4, được $rc"; cat "$WORK/rv-output"; fi
}
finding() {  # $1=kind $2=location $3=scenario $4=evidence → một finding JSON
  jq -nc --arg k "$1" --arg l "$2" --arg s "$3" --arg e "$4" '{id:"F1",kind:$k,location:$l,scenario:$s,evidence:$e}'
}
findings_file() {  # $1=đường dẫn, phần còn lại = các finding JSON
  local out="$1"; shift
  printf '%s\n' "$@" | jq -s '{schema:"review-findings/1",findings:.}' > "$out"
}
review_tests() {
  local d f="$WORK/findings.json"
  d="$(gate_fixture review)"; printf 'a\nb\n' > "$d/app.sh"
  findings_file "$f" "$(finding defect app.sh:2 'b rỗng → chia 0' 'test_div_zero đỏ')"
  rv_check "$d" "$f" 0 'REPAIR-CODE F1' "lỗi có vị trí + kịch bản + bằng chứng → sửa code"
  # jq trên Windows in CRLF (CI framework-lint-windows đã đỏ đúng ca này): giả lập bằng jq bọc thêm \r.
  mkdir -p "$WORK/crlf-bin"; printf '#!/usr/bin/env bash\n%s "$@" | sed "s/\\$/\\r/"\n' "$(command -v jq)" > "$WORK/crlf-bin/jq"; chmod +x "$WORK/crlf-bin/jq"
  PATH="$WORK/crlf-bin:$PATH" rv_check "$d" "$f" 0 'REPAIR-CODE F1' "jq in CRLF (Windows) → vẫn đọc đúng path:line"
  findings_file "$f" "$(finding missing-evidence '' 'evidence STALE' 'evidence-check: STALE head')"
  rv_check "$d" "$f" 0 'RERUN-EVIDENCE F1' "thiếu/cũ bằng chứng → chạy lại kiểm, không sửa code"
  grep -q 'REPAIR-CODE' "$WORK/rv-output" && bad "thiếu bằng chứng bị quy thành sửa code" || ok "thiếu bằng chứng không sinh REPAIR-CODE"
  findings_file "$f" "$(finding missing-input '' 'AC-3 không nói ca rỗng' 'spec §9 thiếu ca rỗng')"
  rv_check "$d" "$f" 0 'ASK-UPSTREAM F1' "thiếu input/spec → hỏi/sửa tầng trên, không sửa code"
  findings_file "$f" "$(finding defect app.sh:2 'chia 0' '')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "finding không có bằng chứng → bị loại"
  findings_file "$f" "$(finding defect '' 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "lỗi code không chỉ được path:line → bị loại"
  findings_file "$f" "$(finding defect khong-co.sh:3 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "lỗi trỏ tới file không tồn tại → bị loại"
  findings_file "$f" "$(finding defect app.sh:9 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "dòng vượt quá độ dài file → bị loại"
  findings_file "$f" "$(finding defect ../app.sh:1 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "path thoát khỏi repo → bị loại"
  findings_file "$f" "$(finding style app.sh:1 'x' 'y')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "kind lạ → bị loại, không đoán"
  findings_file "$f" "$(finding cleanup app.sh:1 'trùng helper' 'grep thấy 2 bản')"
  rv_check "$d" "$f" 0 'OPTIONAL F1' "cleanup → tuỳ chọn, không chặn"
  findings_file "$f"
  rv_check "$d" "$f" 0 'CLEAN' "không có finding → CLEAN"
  printf '{"schema":"x"}' > "$f"; rv_check "$d" "$f" 2 BLOCKED "sai schema → BLOCKED"
  rv_check "$d" "$WORK/khong-co.json" 2 BLOCKED "thiếu file findings → BLOCKED"
}
echo "== 7c. Review có căn cứ, repair đúng nguyên nhân (LD-04) =="
review_tests

finish "dev-task.sh: evidence gắn phiên bản (LD-03) và review có căn cứ (LD-04)."
