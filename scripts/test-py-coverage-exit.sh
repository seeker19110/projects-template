#!/usr/bin/env bash
# A failed success probe must fail coverage measurement even when coverage stays above its floor.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
PROBE="$ROOT/scripts/zz-probe-coverage-exit-$$.sh"
trap 'rm -f "$PROBE"; rm -r "$WORK"' EXIT

file_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

cp "$ROOT/scripts/test-py-coverage.sh" "$PROBE"
python3 - "$PROBE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
old = 'run scripts/arch-health-radar.py --scan'
assert source.count(old) == 2
path.write_text(source.replace(old, 'run scripts/arch-health-radar.py --invalid-coverage-probe', 1))
PY

before="$(file_sha256 "$ROOT/scripts/model-rates.json")"
bash "$PROBE" > "$WORK/output" 2>&1
rc=$?
after="$(file_sha256 "$ROOT/scripts/model-rates.json")"

if [ "$rc" -ne 1 ] || ! grep -q 'Success probe failed' "$WORK/output"; then
  echo "FAIL — success probe lỗi phải làm suite thoát 1 ngay (rc=$rc)." >&2
  tail -n 25 "$WORK/output" >&2
  exit 1
fi
if [ "$before" != "$after" ]; then
  echo 'FAIL — bảng giá không được thay đổi sau probe lỗi.' >&2
  exit 1
fi
echo 'OK — success probe lỗi làm coverage suite đỏ, bảng giá giữ nguyên.'

# Fail during the temporary radar fixtures; EXIT trap must remove all of them.
cp "$ROOT/scripts/test-py-coverage.sh" "$PROBE"
python3 - "$PROBE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
old = 'run scripts/arch-health-radar.py --scan'
assert source.count(old) == 2
first, second = source.split(old, 1)
path.write_text(first + old + second.replace(old, 'run scripts/arch-health-radar.py --invalid-coverage-probe', 1))
PY
before_probes=$(find "$ROOT/scripts" "$ROOT/docs" -maxdepth 2 -name 'zz-probe-*' -print | sort)
bash "$PROBE" > "$WORK/output" 2>&1
rc=$?
after_probes=$(find "$ROOT/scripts" "$ROOT/docs" -maxdepth 2 -name 'zz-probe-*' -print | sort)
if [ "$rc" -ne 1 ] || [ "$before_probes" != "$after_probes" ]; then
  echo "FAIL — probe lỗi phải đỏ và dọn đủ fixture tạm (rc=$rc)." >&2
  tail -n 25 "$WORK/output" >&2
  exit 1
fi
echo 'OK — probe lỗi giữa lượt vẫn dọn đủ fixture tạm.'

# Fail after the rates file is corrupted; EXIT trap must restore its original bytes.
cp "$ROOT/scripts/test-py-coverage.sh" "$PROBE"
python3 - "$PROBE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
old = "printf '{ hong json' > scripts/model-rates.json"
assert source.count(old) == 1
path.write_text(source.replace(old, old + '\nexit 1', 1))
PY
bash "$PROBE" > "$WORK/output" 2>&1
rc=$?
after="$(file_sha256 "$ROOT/scripts/model-rates.json")"
if [ "$rc" -ne 1 ] || [ "$before" != "$after" ]; then
  echo "FAIL — thoát sớm phải khôi phục model-rates.json (rc=$rc)." >&2
  tail -n 25 "$WORK/output" >&2
  exit 1
fi
echo 'OK — thoát sớm sau lỗi bảng giá vẫn khôi phục bytes gốc.'
