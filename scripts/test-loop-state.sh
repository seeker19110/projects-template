#!/usr/bin/env bash
# test-loop-state.sh — Kiểm engine trạng thái vòng lặp /auto-complete (scripts/loop-state.py, wrapper loop-state.sh).
#
# VÌ SAO (ADR-0012, spec docs/specs/2026-10-12-auto-complete-loop-v2.md AC-1..AC-7): trước engine, bước kế tiếp mỗi lượt do
# model đọc 3–6 tài liệu rồi tự suy; hook giữ vòng chép lời model viết. Engine biến trạng thái thành phép ĐO trên artifact
# (hồ sơ, goal, kế hoạch hoàn thiện, release-readiness, git, PR/CI, chuỗi đỏ cổng) → verdict có kiểu + next. Engine sai
# verdict thì cả vòng lặp đi sai hướng mà không ai thấy — nên mỗi nhánh verdict có một ca ở đây, trên repo giả dựng tạm.
# Tên ca khớp từng ký tự bảng bằng chứng §9 của spec. Ca NEGATIVE: engine rỗng (exit 0 không in gì) đỏ ở `--json parse`.
#
# Chạy: bash scripts/test-loop-state.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"
ENGINE="$ROOT/scripts/loop-state.sh"

command -v python3 >/dev/null 2>&1 || { echo "::error::Cần python3 để kiểm engine loop-state."; exit 1; }

ID="2026-10-12-fixture"
# gh giả: in $FAKE_GH_JSON (mặc định "[]"); FAKE_GH_FAIL=1 → lỗi như gh chưa đăng nhập.
mkdir -p "$WORK/fakebin" "$WORK/nogh"
cat > "$WORK/fakebin/gh" <<'GH'
#!/usr/bin/env bash
[ "${FAKE_GH_FAIL:-0}" = "1" ] && { echo "gh: not logged in" >&2; exit 1; }
printf '%s\n' "${FAKE_GH_JSON:-[]}"
GH
chmod +x "$WORK/fakebin/gh"
for t in python3 git bash env; do ln -s "$(command -v "$t")" "$WORK/nogh/$t"; done
export PATH="$WORK/fakebin:$PATH"

write_work() {   # $1 = dự án, $2 = trạng thái, $3 = dòng cuối "Lần thử / blocker", $4 = nội dung Bàn giao
  mkdir -p "$1/docs/work/$ID"
  cat > "$1/docs/work/$ID/working.md" <<EOF
# Công việc: fixture

- Work ID: $ID
- Trạng thái: $2
- Mức rủi ro / số PR: M — 1 PR
- Spec / goal / issue: docs/goals/fixture-goal.md
- Nhánh / base SHA / thời điểm reconcile: \`main\` @ \`abc1234\` · 2026-10-12

## Kế hoạch và phân công

Một PR.

## Lần thử / blocker

$3

## Bàn giao / bước tiếp theo

$4

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<chưa>
EOF
}
write_goal() {   # $1 = dự án, $2 = Evidence của S1, $3 = State S2
  cat > "$1/docs/goals/fixture-goal.md" <<EOF
# Goal: fixture

| Thuộc tính | Giá trị |
| --- | --- |
| State | ACTIVE |

## Milestones và slices

| ID | Outcome/AC | Dependency | Spec | Issue | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S1 | nền | — | — | — | #1 | DONE | $2 |
| S2 | engine | S1 | — | — | — | $3 | |
| S3 | hook | S2 | — | — | — | BACKLOG | |
EOF
}
write_plan() {   # $1 = dự án, $2..$5 = ô trạng thái W-101..W-104, $6 = DoC dòng 2 ("x" hoặc " ")
  cat > "$1/docs/ops/COMPLETION-PLAN.md" <<EOF
# COMPLETION-PLAN

## Definition of Complete (đã chốt)
- [x] cổng xanh
- [$6] smoke
- [$6] tài liệu

## Đợt 1 — Bảo mật
| ID | Từ phát hiện | Việc | Tiêu chí | Phụ thuộc | Ước lượng | Trạng thái | PR / bằng chứng |
|----|----|----|----|----|----|----|----|
| W-101 | F-1 | a | a | – | S | $2 | #2 |
| W-102 | F-2 | b | b | – | S | $3 | |
| W-103 | F-3 | c | c | – | S | $4 | |
| W-104 | F-4 | d | d | – | S | $5 | bỏ |

## Nhật ký hội tụ (Pha 4)
- [ ] không đếm dòng này vào DoC
EOF
}
write_ready() { printf '# Release readiness\n\n- [x] build\n- [%s] smoke\n' "$2" > "$1/docs/ops/release-readiness.md"; }
commit_all() { git -C "$1" add -A && git -C "$1" commit -q -m "${2:-fixture}"; }

new_proj() {   # repo tạm: commit sạch, hồ sơ Active, goal S1 DONE/S2 BUILD/S3 BACKLOG, plan 1 mỗi loại ô, NO-GO
  local p="$WORK/p-$RANDOM-$RANDOM"
  mkdir -p "$p/.claude" "$p/docs/goals" "$p/docs/ops"
  git -C "$p" init -q -b main
  git -C "$p" config user.name fixture; git -C "$p" config user.email fixture@example.invalid
  git -C "$p" commit --allow-empty -q -m init
  printf '.claude/.gate-red-streak\n.claude/.auto-complete-loop\n' > "$p/.gitignore"
  write_work "$p" "Active" "- 2026-10-12: chưa có failure." "Làm S2 theo spec."
  write_goal "$p" "PR #1 CI xanh" "BUILD"
  write_plan "$p" "✅" "⬜" "🔄" "➖" " "
  write_ready "$p" " "
  commit_all "$p" "fixture"
  printf '%s\n' "$p"
}
run_ls() { ( cd "$1" && shift && bash "$ENGINE" "$@" ); }       # $1 = dự án, còn lại = cờ engine
js() { printf '%s' "$1" | python3 -c "import json,sys; d=json.load(sys.stdin); print($2)" 2>/dev/null; }   # $2 = biểu thức trên d

echo "== AC-1. Không xác định được hồ sơ → exit 2 =="
p="$(new_proj)"; mv "$p/docs/work/$ID/working.md" "$p/docs/work/$ID/done.md"
out="$(run_ls "$p" --root "$p" --json 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && ok "0 hồ sơ Active → exit 2" || bad "0 hồ sơ Active → exit 2 (rc=$rc, out=$out)"
p="$(new_proj)"
out="$(run_ls "$p" --root "$p" --work-id 2099-01-01-khong-co --json 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && ok "--work-id không tồn tại → exit 2" || bad "--work-id không tồn tại → exit 2 (rc=$rc, out=$out)"
mkdir -p "$p/docs/work/2026-10-13-khac"; sed "s/$ID/2026-10-13-khac/" "$p/docs/work/$ID/working.md" > "$p/docs/work/2026-10-13-khac/working.md"
out="$(run_ls "$p" --root "$p" --json 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q "2026-10-13-khac" && printf '%s' "$out" | grep -q "$ID" \
  && ok "nhiều hồ sơ Active → exit 2 + danh sách" || bad "nhiều hồ sơ Active → exit 2 + danh sách (rc=$rc, out=$out)"

echo "== AC-2. Verdict theo trạng thái hồ sơ + file dở =="
p="$(new_proj)"; printf 'x\n' > "$p/do-dang.txt"
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['verdict']")" = "continue" ] && js "$out" "d['next']" | grep -qi "commit" && [ "$(js "$out" "d['git']['dirty']")" = "1" ] \
  && ok "Active + file dở → continue/commit" || bad "Active + file dở → continue/commit: $out"
p="$(new_proj)"; write_work "$p" "Blocked — chờ chủ repo" "-" "-"
[ "$(js "$(run_ls "$p" --root "$p" --work-id "$ID" --json)" "d['verdict']")" = "request-input" ] && ok "Blocked → request-input" || bad "Blocked → request-input"
p="$(new_proj)"; write_work "$p" "Waiting (chờ CI)" "-" "-"
[ "$(js "$(run_ls "$p" --root "$p" --work-id "$ID" --json)" "d['verdict']")" = "waiting" ] && ok "Waiting → waiting" || bad "Waiting → waiting"
p="$(new_proj)"; mv "$p/docs/work/$ID/working.md" "$p/docs/work/$ID/done.md"
out="$(run_ls "$p" --root "$p" --work-id "$ID" --json)"
[ "$(js "$out" "d['verdict']")" = "stop" ] && ok "done.md → stop" || bad "done.md → stop: $out"

echo "== AC-3. Chuỗi đỏ cổng commit (.claude/.gate-red-streak) =="
p="$(new_proj)"; printf 'n=3\nsig=FAIL: lint\n' > "$p/.claude/.gate-red-streak"
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['verdict']")" = "request-input" ] && [ "$(js "$out" "d['streak']['n']")" = "3" ] \
  && ok "streak 3 → request-input" || bad "streak 3 → request-input: $out"
p="$(new_proj)"; printf 'n=2\nsig=FAIL: test\n' > "$p/.claude/.gate-red-streak"
write_work "$p" "Active" "- lần 1: test đỏ.
- lần 2: lỗi ở tầng ① vì AC mơ hồ." "x"
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['verdict']")" = "refine-spec" ] && [ "$(js "$out" "d['work']['layer_hint']")" = "spec" ] \
  && ok "streak 2 tầng ① → refine-spec" || bad "streak 2 tầng ① → refine-spec: $out"
write_work "$p" "Active" "- lần 1: lỗi ở tầng ① (đã sửa spec).
- lần 2: lỗi ở tầng ③ vì thiếu nhánh null." "x"
[ "$(js "$(run_ls "$p" --root "$p" --json)" "d['verdict']")" = "refine-code" ] && ok "streak 2 tầng ③ → refine-code" || bad "streak 2 tầng ③ → refine-code"

echo "== AC-4. Goal: ready/blocked theo Dependency, DONE thiếu Evidence =="
p="$(new_proj)"
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['goal']['slices']['ready']")" = "['S2']" ] && [ "$(js "$out" "d['goal']['slices']['blocked']")" = "['S3']" ] \
  && [ "$(js "$out" "d['goal']['file']")" = "docs/goals/fixture-goal.md" ] && [ "$(js "$out" "d['verdict']")" = "continue" ] \
  && ok "goal ready/blocked theo Dependency" || bad "goal ready/blocked theo Dependency: $out"
write_goal "$p" "" "BUILD"; commit_all "$p"
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['goal']['done_without_evidence']")" = "['S1']" ] && js "$out" "d['next']" | grep -q "Evidence" \
  && ok "goal DONE thiếu Evidence" || bad "goal DONE thiếu Evidence: $out"
p="$(new_proj)"; write_goal "$p" "PR #1" "BLOCKED"; commit_all "$p"
[ "$(js "$(run_ls "$p" --root "$p" --json)" "d['verdict']")" = "request-input" ] && ok "slice mở không ready → request-input" || bad "slice mở không ready → request-input"

echo "== AC-5. Kế hoạch hoàn thiện + release-readiness =="
p="$(new_proj)"
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "[d['completion'][k] for k in ('open','doing','done','dropped','doc_unchecked','doc_total')]")" = "[1, 1, 1, 1, 2, 3]" ] \
  && ok "completion đếm ô + DoC" || bad "completion đếm ô + DoC: $out"
h1="$(js "$out" "d['handoff']['verdict']")"
write_ready "$p" "x"; h2="$(js "$(run_ls "$p" --root "$p" --json)" "d['handoff']['verdict']")"
rm "$p/docs/ops/release-readiness.md"; h3="$(js "$(run_ls "$p" --root "$p" --json)" "d['handoff']['verdict']")"
[ "$h1/$h2/$h3" = "NO-GO/GO/unknown" ] && ok "handoff GO/NO-GO/unknown" || bad "handoff GO/NO-GO/unknown (được $h1/$h2/$h3)"
p="$(new_proj)"; write_goal "$p" "PR #1" "DONE"; sed -i 's/| S3 | hook | S2 | — | — | — | BACKLOG | |/| S3 | hook | S2 | — | — | — | DROPPED | |/' "$p/docs/goals/fixture-goal.md"
sed -i 's/| S2 | engine | S1 | — | — | — | DONE | |/| S2 | engine | S1 | — | — | — | DONE | PR #2 |/' "$p/docs/goals/fixture-goal.md"; commit_all "$p"
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['verdict']")" = "continue" ] && js "$out" "d['next']" | grep -q "W-103" \
  && ok "kế hoạch còn ⬜/🔄 → continue W kế" || bad "kế hoạch còn ⬜/🔄 → continue W kế: $out"
write_plan "$p" "✅" "✅" "✅" "➖" "x"; commit_all "$p"
js "$(run_ls "$p" --root "$p" --json)" "d['next']" | grep -q "release-readiness" && ok "NO-GO → continue release-readiness" || bad "NO-GO → continue release-readiness"
write_ready "$p" "x"; commit_all "$p"
js "$(run_ls "$p" --root "$p" --json)" "d['next']" | grep -q "done.md" && ok "mọi thứ xong → nghiệm thu done.md" || bad "mọi thứ xong → nghiệm thu done.md"
p="$(new_proj)"; rm -r "$p/docs/goals" "$p/docs/ops"; write_work "$p" "Active" "-" "<Một hành động cụ thể>"; commit_all "$p"
js "$(run_ls "$p" --root "$p" --json)" "d['next']" | grep -q "Bàn giao" && ok "Bàn giao chưa điền → ghi Bàn giao" || bad "Bàn giao chưa điền → ghi Bàn giao"

echo "== AC-6. PR/CI qua gh (giả) =="
p="$(new_proj)"
out="$( cd "$p" && PATH="$WORK/nogh" python3 "$ROOT/scripts/loop-state.py" --root "$p" --json 2>&1 )"
[ "$(js "$out" "d['pr']['available']")" = "False" ] && [ -n "$(js "$out" "d['pr']['note']")" ] && [ "$(js "$out" "d['verdict']")" = "continue" ] \
  && ok "không gh → pr.available=false" || bad "không gh → pr.available=false: $out"
out="$(FAKE_GH_FAIL=1 run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['pr']['available']")" = "False" ] && ok "gh lỗi → pr.available=false" || bad "gh lỗi → pr.available=false: $out"
FAIL_JSON='[{"number":7,"mergeable":"MERGEABLE","autoMergeRequest":null,"statusCheckRollup":[{"conclusion":"SUCCESS","status":"COMPLETED"},{"conclusion":"FAILURE","status":"COMPLETED"}]}]'
out="$(FAKE_GH_JSON="$FAIL_JSON" run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['verdict']")" = "continue" ] && js "$out" "d['next']" | grep -q "CI" && [ "$(js "$out" "d['pr']['open'][0]['ci']")" = "failure" ] \
  && ok "gh giả CI FAILURE → sửa CI" || bad "gh giả CI FAILURE → sửa CI: $out"
OK_JSON='[{"number":8,"mergeable":"MERGEABLE","autoMergeRequest":{"enabledAt":"x"},"statusCheckRollup":[{"conclusion":"SUCCESS","status":"COMPLETED"},{"conclusion":"SKIPPED","status":"COMPLETED"}]}]'
out="$(FAKE_GH_JSON="$OK_JSON" run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['verdict']")" = "waiting" ] && [ "$(js "$out" "d['pr']['open'][0]['auto_merge']")" = "True" ] \
  && ok "gh giả SUCCESS → waiting" || bad "gh giả SUCCESS → waiting: $out"

echo "== Reconcile: tụt origin/main không PR =="
p="$(new_proj)"; git clone -q --bare "$p" "$p.git"; git -C "$p" remote add origin "$p.git"
git clone -q "$p.git" "$p.o"; git -C "$p.o" config user.name f; git -C "$p.o" config user.email f@example.invalid
git -C "$p.o" commit --allow-empty -q -m tren-main; git -C "$p.o" push -q origin main; git -C "$p" fetch -q origin
out="$(run_ls "$p" --root "$p" --json)"
[ "$(js "$out" "d['git']['behind']")" = "1" ] && js "$out" "d['next']" | grep -qi "reconcile" \
  && ok "tụt origin/main không PR → continue/reconcile" || bad "tụt origin/main không PR → continue/reconcile: $out"

echo "== AC-7. --enter, --fingerprint, --json, --brief =="
p="$(new_proj)"; printf '%s\nn=5\nlast=123\nnudged=0\nfp=abc\nfpn=1\n' "$ID" > "$p/.claude/.auto-complete-loop"
brief="$(run_ls "$p" --root "$p" --enter)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(sed -n 1p "$p/.claude/.auto-complete-loop")" = "$ID" ] && grep -q '^n=5$' "$p/.claude/.auto-complete-loop" \
  && grep -q '^fp=abc$' "$p/.claude/.auto-complete-loop" && printf '%s' "$brief" | grep -q '^verdict: ' \
  && ok "--enter ghi marker giữ n" || bad "--enter ghi marker giữ n (rc=$rc): $(cat "$p/.claude/.auto-complete-loop") / $brief"
rm "$p/.claude/.auto-complete-loop"; run_ls "$p" --root "$p" --enter >/dev/null
[ "$(cat "$p/.claude/.auto-complete-loop")" = "$ID" ] && ok "--enter không marker → chỉ ghi ID (hồ sơ duy nhất)" || bad "--enter không marker → chỉ ghi ID: $(cat "$p/.claude/.auto-complete-loop" 2>&1)"
f1="$(run_ls "$p" --root "$p" --work-id "$ID" --fingerprint)"; f2="$(run_ls "$p" --root "$p" --work-id "$ID" --fingerprint)"
printf 'x\n' > "$p/moi.txt"; f3="$(run_ls "$p" --root "$p" --work-id "$ID" --fingerprint)"
printf '\nghi chú\n' >> "$p/docs/work/$ID/working.md"; f4="$(run_ls "$p" --root "$p" --work-id "$ID" --fingerprint)"
commit_all "$p"; f5="$(run_ls "$p" --root "$p" --work-id "$ID" --fingerprint)"
printf '%s' "$f1" | grep -Eq '^[0-9a-f]{16}$' && [ "$f1" = "$f2" ] && [ "$f3" != "$f2" ] && [ "$f4" != "$f3" ] && [ "$f5" != "$f4" ] \
  && ok "--fingerprint đổi/giữ" || bad "--fingerprint đổi/giữ ($f1 $f2 $f3 $f4 $f5)"
out="$(run_ls "$p" --root "$p" --json)"
keys="$(js "$out" "sorted(d)")"
[ "$keys" = "['completion', 'git', 'goal', 'handoff', 'loop', 'next', 'pr', 'reason', 'streak', 'verdict', 'work']" ] \
  && [ -n "$(js "$out" "d['verdict']")" ] && [ "$(js "$out" "d['loop']['max']")" = "20" ] \
  && ok "--json parse" || bad "--json parse (keys=$keys, out=$out)"
brief="$(run_ls "$p" --root "$p" --brief)"; nl="$(printf '%s\n' "$brief" | wc -l)"
[ -n "$brief" ] && [ "$nl" -le 20 ] && printf '%s' "$brief" | head -1 | grep -q '^verdict: ' && printf '%s' "$brief" | grep -q '^next: ' \
  && ok "--brief ≤ 20 dòng" || bad "--brief ≤ 20 dòng ($nl dòng): $brief"

echo "== Review 2026-10-12 (F1/F2/F4): đầu vào lạ không làm chết engine =="
# F1 (TRAPS 24): repo ở đường dẫn Unicode + locale C → subprocess text=True giải mã theo locale → UnicodeDecodeError khi không --root.
p="$(new_proj)"; u="$WORK/dự-án-$RANDOM"; mv "$p" "$u"
out="$( cd "$u" && LC_ALL=C LANG=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0 python3 "$ROOT/scripts/loop-state.py" --brief 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '^verdict: ' \
  && ok "đường dẫn Unicode + locale C không --root → vẫn chạy" || bad "đường dẫn Unicode + locale C (rc=$rc): $(printf '%s' "$out" | tail -1)"
# F2: gh trả statusCheckRollup không phải danh sách dict → ci unknown, không traceback.
p="$(new_proj)"
out="$(FAKE_GH_JSON='[{"number":7,"statusCheckRollup":["x",5]},{"number":8,"statusCheckRollup":{"a":1}},"rác"]' run_ls "$p" --root "$p" --json 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(js "$out" "[q['ci'] for q in d['pr']['open']]")" = "['unknown', 'unknown']" ] \
  && ok "gh JSON phần tử sai kiểu → ci unknown, không chết" || bad "gh JSON phần tử sai kiểu (rc=$rc): $(printf '%s' "$out" | tail -1)"
# F4: --enter trên hồ sơ done.md không ghi marker (verdict stop dặn xoá marker — không tạo cái phải xoá).
p="$(new_proj)"; mv "$p/docs/work/$ID/working.md" "$p/docs/work/$ID/done.md"
out="$(run_ls "$p" --root "$p" --work-id "$ID" --enter --brief 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ ! -e "$p/.claude/.auto-complete-loop" ] && printf '%s' "$out" | grep -q '^verdict: stop' \
  && ok "--enter trên done.md → stop, không ghi marker" || bad "--enter trên done.md (rc=$rc, marker=$([ -e "$p/.claude/.auto-complete-loop" ] && echo có || echo không)): $(printf '%s' "$out" | head -1)"

finish "engine loop-state đúng verdict/parser/marker/vân tay trên repo giả."
