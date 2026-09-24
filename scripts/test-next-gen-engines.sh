#!/usr/bin/env bash
# test-next-gen-engines.sh — Tự kiểm tra Spec-to-Contract Compiler và Architectural Health Radar Engine.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi

source "$ROOT/scripts/_test-lib.sh"
fails=0  # explicit for ShellCheck; _test-lib.sh also initializes the counter

echo "== 1. Autonomous Spec-to-Contract Compiler Engine =="

PYTHON_CMD="python3"
command -v python3 >/dev/null 2>&1 || PYTHON_CMD="python"

out_compile="$(bash "$ROOT/scripts/spec-compiler.sh" --compile-all 2>&1)"
compile_rc=$?
if [ "$compile_rc" -eq 0 ]; then
  ok "spec-compiler --compile-all hoàn tất (rc=0)"
else
  bad "spec-compiler --compile-all thất bại (rc=$compile_rc)"
  printf '%s\n' "$out_compile" >&2
fi

if compgen -G "$ROOT/tests/contracts/test_*.py" >/dev/null; then
  out_unittest="$("$PYTHON_CMD" -m unittest discover -s "$ROOT/tests/contracts" 2>&1)"
  unittest_rc=$?
  if [ "$unittest_rc" -eq 0 ] && printf '%s\n' "$out_unittest" | grep -q '^Ran [1-9]'; then
    ok "Tất cả Executable Spec Contract Tests chạy thành công (PASSED)"
  else
    bad "Executable Spec Contract Tests thất bại hoặc không chạy test nào (rc=$unittest_rc)"
    printf '%s\n' "$out_unittest" >&2
  fi
elif [ "$compile_rc" -eq 0 ] && [ -z "$(find "$ROOT/docs/specs" -maxdepth 1 -name '*.md' ! -name README.md -print -quit 2>/dev/null)" ]; then
  echo "  ⏭️  Bỏ qua contract test: chưa có spec nào nên chưa sinh test"
else
  bad "Có specs nhưng không sinh được contract test"
  printf '%s\n' "$out_compile" >&2
fi

# --- Negative-test cho AC-2/AC-3 (audit 2026-09-13, A-01) ---
# VÌ SAO BẮT BUỘC: bản đầu của spec-compiler sinh 82/82 assertion `assertTrue(len(x) >= 0)` —
# hằng đúng, nên "OK" ở trên KHÔNG chứng minh được gì. Một bộ test không bao giờ đỏ cũng in "OK".
# Hai ca dưới chứng minh contract test THẬT SỰ bắt lỗi, và KHÔNG đỏ oan.
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
# Python là chương trình Windows GỐC: nó không hiểu đường dẫn kiểu MSYS (`/tmp/...`) mà `mktemp -d`
# trả về, nên `unittest discover -s /tmp/...` KHÔNG tìm thấy test nào và luôn thoát khác 0 — AC-2
# xanh OAN (đỏ nhưng sai lý do) còn AC-3 đỏ oan. Cùng cách xử lý đã dùng cho $ROOT ở đầu file.
# KHÔNG lộ trên máy dev nếu TMPDIR đã là đường dẫn Windows — chỉ đỏ trên runner windows-latest
# (nơi TMPDIR là /tmp). Đây chính là lỗi đầu tiên mà job `framework-lint-windows` bắt được.
if command -v cygpath >/dev/null 2>&1; then scratch="$(cygpath -m "$scratch")"; fi
mkdir -p "$scratch/docs/specs" "$scratch/tests/contracts" "$scratch/scripts"
# Test sinh ra tính ROOT_DIR = 3 cấp trên chính nó (<scratch>/tests/contracts/x.py -> <scratch>),
# nên ca đối chứng phải trỏ tới file có thật TRONG scratch, không phải trong repo.
printf '#!/usr/bin/env bash\nexit 0\n' > "$scratch/scripts/file-co-that.sh"

# Khi AC-2/AC-3 do, in NGAY thu can de chan doan. Truoc day ca lenh bien dich lan lenh unittest
# deu bi nuot bang >/dev/null 2>&1, nen mot ca do chi noi "co gi do sai" — phai doan, va doan sai
# hai luot lien (xem lich su PR them cong Windows).
ac_diag() {
  echo "     --- chan doan ---" >&2
  echo "     scratch      = $scratch" >&2
  echo "     PYTHON_CMD   = $PYTHON_CMD ($("$PYTHON_CMD" --version 2>&1))" >&2
  echo "     spec-compiler stdout/stderr:" >&2
  printf '%s
' "$out_compile" | sed 's/^/       /' >&2
  echo "     noi dung $scratch/tests/contracts:" >&2
  ls -la "$scratch/tests/contracts" 2>&1 | sed 's/^/       /' >&2
  echo "     unittest stdout/stderr:" >&2
  printf '%s
' "${out_ac2:-}" | sed 's/^/       /' >&2
}

# (a) spec đã Approved khai một đường dẫn KHÔNG tồn tại → contract test phải ĐỎ (AC-2)
# Tên file thiếu được GHÉP LÚC CHẠY: nếu viết thẳng chuỗi đó trong backtick vào mã nguồn,
# mục 1 của check-docs-consistency.sh sẽ báo "tham chiếu file không tồn tại" cho chính test này
# (đã mắc thật). Heredoc dưới CỐ Ý không trích dẫn để biến nở ra.
MISSING_PATH="scripts/file-$(printf 'khong')-ton-tai-$$.sh"
cat > "$scratch/docs/specs/2099-01-01-ca-am.md" <<SPEC
# Feature spec: ca âm

| Thuộc tính | Giá trị |
| --- | --- |
| State | **Approved for implementation** |

## 7. Functional requirements

- **FR-1** Phải có file không tồn tại.

## 11. Architecture và code touchpoints

- \`$MISSING_PATH\`
SPEC
out_compile="$("$PYTHON_CMD" "$ROOT/scripts/spec-compiler.py" --spec "$scratch/docs/specs/2099-01-01-ca-am.md" --out-dir "$scratch/tests/contracts" 2>&1)"
compile_rc=$?
out_ac2="$("$PYTHON_CMD" -m unittest discover -s "$scratch/tests/contracts" 2>&1)"
unittest_rc=$?
if [ "$compile_rc" -ne 0 ]; then
  bad "AC-2: compiler thất bại (rc=$compile_rc)"; ac_diag
elif [ "$unittest_rc" -eq 0 ]; then
  bad "AC-2: contract test KHÔNG đỏ dù spec Approved trỏ tới file không tồn tại (assertion rỗng?)"; ac_diag
elif ! printf '%s' "$out_ac2" | grep -q "^FAIL: test_c3_duong_dan_spec_hua_phai_ton_tai"; then
  # Đỏ nhưng KHÔNG phải vì assertion — discover không chạy được test nào (ví dụ đường dẫn MSYS
  # trên Windows). Nếu không bắt ở đây thì ca này xanh oan và che mất chính lỗi đó.
  bad "AC-2: đỏ nhưng SAI LÝ DO — unittest không chạy được test nào (discover hỏng?)"; ac_diag
else
  ok "AC-2: contract test ĐỎ đúng lúc — spec Approved trỏ tới file không tồn tại"
fi

# (b) đối chứng: cùng spec nhưng trỏ tới file CÓ THẬT → phải XANH (không đỏ oan) (AC-3)
rm -f "$scratch/tests/contracts"/*.py
sed -i "s|$MISSING_PATH|scripts/file-co-that.sh|" "$scratch/docs/specs/2099-01-01-ca-am.md"
out_compile="$("$PYTHON_CMD" "$ROOT/scripts/spec-compiler.py" --spec "$scratch/docs/specs/2099-01-01-ca-am.md" --out-dir "$scratch/tests/contracts" 2>&1)"
compile_rc=$?
out_ac2="$("$PYTHON_CMD" -m unittest discover -s "$scratch/tests/contracts" 2>&1)"
unittest_rc=$?
if [ "$compile_rc" -eq 0 ] && [ "$unittest_rc" -eq 0 ] && printf '%s\n' "$out_ac2" | grep -q '^Ran [1-9]'; then
  ok "AC-3: contract test XANH khi mọi đường dẫn tồn tại (không đỏ oan)"
else
  bad "AC-3: contract test đỏ oan dù mọi đường dẫn đều tồn tại"; ac_diag
fi

# SC-1 (hồi quy, 2026-09-15): `os.path.relpath` NÉM ValueError khi hai đường dẫn nằm trên hai ổ
# đĩa khác nhau trên Windows. Runner `windows-latest` checkout repo ở ổ D: còn `mktemp -d` trả về
# thư mục ở ổ C: — spec-compiler chết ngay, không sinh ra test nào, làm AC-2 xanh oan và AC-3 đỏ oan.
# Ca này **ép** ValueError bằng monkeypatch thay vì chờ có hai ổ đĩa thật, nên nó có nghĩa trên CẢ
# Linux lẫn Windows — nếu chỉ gọi với đường dẫn "D:/..." thì trên Linux nó xanh vô nghĩa.
out_sc1="$(PYTHONIOENCODING=utf-8 "$PYTHON_CMD" - "$ROOT" <<'PY' 2>&1
import importlib.util, os, sys
root = sys.argv[1]
spec = importlib.util.spec_from_file_location("sc", os.path.join(root, "scripts", "spec-compiler.py"))
mod = importlib.util.module_from_spec(spec)
sys.argv = ["spec-compiler.py"]
spec.loader.exec_module(mod)

def boom(*_a, **_k):
    raise ValueError("path is on mount 'C:', start on mount 'D:'")

os.path.relpath = boom
out = mod._display_path(os.path.join(root, "scripts", "spec-compiler.py"))
print("OK" if out else "RONG")
PY
)"
sc1_rc=$?
if [ "$sc1_rc" -eq 0 ] && [ "$out_sc1" = "OK" ]; then
  ok "SC-1: _display_path chịu được ValueError khác ổ đĩa (không làm chết spec-compiler)"
else
  bad "SC-1: _display_path vẫn vỡ khi relpath ném ValueError — $out_sc1"
fi

echo "== 2. Architectural Health & Tech Debt Radar Engine =="

out_radar="$(bash "$ROOT/scripts/arch-health-radar.sh" --scan 2>&1)"
radar_rc=$?
if [ "$radar_rc" -eq 0 ] && echo "$out_radar" | grep -q "Repo Health & Tech Debt Radar"; then
  ok "arch-health-radar --scan tạo được báo cáo"
else
  bad "arch-health-radar --scan thất bại (rc=$radar_rc)"
  printf '%s\n' "$out_radar" >&2
fi

# AHR-1: báo cáo PHẢI in công thức chấm điểm. Một con số không kèm cách tính là thứ đã khiến
# "90/100 sức khoẻ kiến trúc" bị đọc nhầm thành điểm kiến trúc thật (audit 2026-09-13, A-02).
if echo "$out_radar" | grep -q "Điểm được tính ra sao"; then
  ok "AHR-1: báo cáo in công thức chấm điểm (con số không đi một mình)"
else
  bad "AHR-1: báo cáo KHÔNG in công thức — con số dễ bị đọc nhầm"
fi

# AHR-2: tỷ lệ tài liệu phải phản ánh thực tế. Bản cũ đếm văn xuôi Markdown là "code" nên
# báo repo ~2/3 là .md thành "16% tài liệu". Đối chiếu với số đếm ĐỘC LẬP bằng find/wc.
# Loại trừ ĐÚNG tập thư mục radar loại trừ (EXCLUDE_DIRS trong arch-health-radar.py) — nếu không, bộ đếm
# đối chứng tự lệch: .ai-telemetry/telemetry.json phình sau nhiều lượt test cục bộ làm find/wc ra 50% trong
# khi radar (bỏ qua thư mục đó) ra 56% → ca này đỏ oan trên máy dev (gặp thật 2026-09-23).
doc_lines_real="$(find "$ROOT" -name '*.md' -not -path '*/.git/*' -not -path '*/.ai-telemetry/*' -not -path '*/node_modules/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')"
total_real="$(find "$ROOT" -type f -not -path '*/.git/*' -not -path '*/__pycache__/*' -not -path '*/.ai-telemetry/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' -not -path '*/coverage/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')"
radar_doc_pct="$(echo "$out_radar" | sed -n 's/.*\*\*\([0-9.]*\)%\*\* tổng số dòng.*/\1/p' | head -1)"
if [ -n "$radar_doc_pct" ] && [ "$total_real" -gt 0 ]; then
  expected_pct=$(( 100 * doc_lines_real / total_real ))
  radar_int="${radar_doc_pct%%.*}"
  diff=$(( radar_int - expected_pct )); [ "$diff" -lt 0 ] && diff=$(( -diff ))
  if [ "$diff" -le 5 ]; then
    ok "AHR-2: tỷ lệ tài liệu khớp số đếm độc lập (radar ${radar_int}% vs find/wc ${expected_pct}%)"
  else
    bad "AHR-2: tỷ lệ tài liệu LỆCH thực tế (radar ${radar_int}% vs find/wc ${expected_pct}%)"
  fi
else
  bad "AHR-2: không đọc được tỷ lệ tài liệu từ báo cáo"
fi

# AHR-3 (đối chứng ĐỘNG): thêm một script KHÔNG có test thì độ phủ cổng phải TỤT.
# Không có ca này thì "100% độ phủ" chỉ là một hằng số in ra, không phải phép đo.
cov_before="$(echo "$out_radar" | sed -n 's/.*Độ phủ cổng.*| \([0-9.]*\) | .*/\1/p' | head -1)"
probe="$ROOT/scripts/zz-probe-do-phu-$$.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$probe"
cov_after="$(bash "$ROOT/scripts/arch-health-radar.sh" --scan 2>&1 | sed -n 's/.*Độ phủ cổng.*| \([0-9.]*\) | .*/\1/p' | head -1)"
rm -f "$probe"
# Ở DỰ ÁN ĐÍCH mới dựng chưa có .github/workflows/ci.yml nên độ phủ cổng đã là 0 — không có
# gì để "tụt" thêm, ca này không chứng minh được gì. skip kèm lý do, KHÔNG assert bừa cho xanh
# (phát hiện 2026-09-14 khi smoke self-test ngay trong dự án đích).
if [ "${cov_before:-0}" = "0.0" ] || [ "${cov_before:-0}" = "0" ]; then
  echo "  ⏭️  AHR-3 bỏ qua: độ phủ cổng đang là 0 (repo chưa nối test nào vào CI) — không có gì để tụt"
elif [ -n "$cov_before" ] && [ -n "$cov_after" ] \
   && [ "$(printf '%s\n' "$cov_after" "$cov_before" | sort -g | head -1)" = "$cov_after" ] \
   && [ "$cov_after" != "$cov_before" ]; then
  ok "AHR-3: thêm script không có test → độ phủ TỤT ($cov_before → $cov_after), radar đo thật"
else
  bad "AHR-3: độ phủ KHÔNG đổi khi thêm script không có test ($cov_before → $cov_after) — đang in hằng số?"
fi

if [ "$fails" -eq 0 ]; then
  echo "OK — Tất cả kiểm tra Next-Gen Engines (Spec Compiler & Health Radar) đều XANH."
  exit 0
else
  echo "FAIL — Có $fails ca kiểm tra thất bại."
  exit 1
fi
