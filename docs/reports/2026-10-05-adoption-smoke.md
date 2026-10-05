# W-06/C02 — smoke áp khung lên đích Node/Python

Trạng thái: **bằng chứng cục bộ có giới hạn**, chưa nghiệm thu C02 cho mọi hồ sơ.

## Phạm vi đã chạy

`scripts/test-adoption-smoke.sh` tạo hai Git repo tạm, chạy `copy-framework.sh`,
khai các lệnh `build`/`lint`/`test` tối thiểu và lý do N/A cho `typecheck`, rồi
gọi `scripts/dev-task.sh gate` bằng Node và Python cài thật. Mỗi đích bắt đầu
với phép cộng sai nên gate phải đỏ ở `test`; sửa logic thì gate phải xanh.

| Đích | Lệnh hành vi thật | Kết quả smoke cục bộ 2026-10-05 |
| --- | --- | --- |
| JavaScript thuần | `node test.cjs` | gate đỏ rồi xanh; build/lint kiểm cú pháp Node |
| Python thuần | `python3 -m unittest -q test_calc` | gate đỏ rồi xanh; build `py_compile`, lint `tabnanny` |

Test còn cài `ci.yml` từ `_framework-dropins/` vào mỗi đích và kiểm offline:
`doctor`/`gate` chạy thật trên đích; mọi script được workflow gọi đều đã phát,
action `uses:` ghim SHA 40 ký tự. Xóa gate, thay pin bằng tag, hoặc thêm lời gọi
script chưa phát đều làm kiểm này đỏ. Lượt đỏ-trước trên drop-in cũ: cả hai đích
đều báo `CI drop-in gọi script vắng` (exit 2). Bản mới dùng
`docs/framework/templates/ci-target.yml` riêng thay cho CI nội bộ của repo khung.
Job `copy-framework-smoke` trong `.github/workflows/ci.yml` chạy test trên PR.
Smoke còn mô phỏng checkout CI bằng clone sạch: config lệnh bị `.gitignore`
loại ra làm `doctor` BLOCKED; sau khi review rồi `git add -f`
`.claude/project-commands.sh`, clone mới chạy `doctor` READY và `gate` PASS
cho cả Node/Python. Fixture chỉ chứa lệnh thử, không có thông tin bí mật.

## Giới hạn chưa được chứng minh

- Kiểm offline ở trên **không chứng minh** workflow GitHub chạy xanh sau khi cài;
  cần chạy PR ở repo đích để có bằng chứng hosted CI. Workflow đích tối thiểu
  chạy lệnh đã review; dự án có dependency phải bổ sung bước cài, cache và cổng
  riêng theo stack. Bản policy Vitest
  `scripts/ci-workflow-policy.test.ts` cũng chưa chạy: fixture không cài Vitest.
- `typecheck` là N/A có lý do trong hai fixture nhỏ; chưa kiểm một đích có
  type checker thật. Lint Node/Python ở đây chỉ đo cú pháp/indentation.
- Đây là JavaScript và Python tối thiểu, không chứng minh web UI, backend/DB,
  mobile, desktop, static site, CLI release, ML, game, blockchain hay monorepo.
  C01 vẫn cần một sản phẩm thật do người dùng chọn.
