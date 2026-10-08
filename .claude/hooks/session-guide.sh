#!/usr/bin/env bash
# session-guide.sh — SessionStart hook.
# HIỆN cho NGƯỜI DÙNG (systemMessage) gợi ý "nên làm gì tiếp theo" khi mở phiên,
# CHỈ trong dự án dùng khung/template này. Tự nhận biết trạng thái để gợi ý đúng:
#   • Chưa có tiến độ  → hướng bắt đầu (mô tả ý tưởng / /consult / /bootstrap / /auto)
#   • Đang làm dở      → hướng tiếp tục ('tiếp tục' / /auto / /gate)
# Đồng thời NHẮC chính sách hai pha (ADR-0007, thay `opusplan` đã ngừng hỗ trợ):
# PHA LẬP KẾ HOẠCH việc lớn dùng model cao cấp nhất đang sẵn có, PHA THỰC THI quay lại model
# tiêu chuẩn (mặc định repo: Sonnet 5) + phân việc/PR cho model khác theo độ phức tạp
# (`scripts/subagent-dispatch.sh --tier`). Không còn một alias/model_id cố định để so khớp,
# nên hook chỉ NHẮC chính sách — không tự xác nhận/cảnh báo đúng-sai theo tên model.
# Không đổi gì (chỉ đọc). No-op nếu không phải dự án của khung; thiếu jq → bỏ qua nhưng NÓI RA (stderr).
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
command -v jq >/dev/null 2>&1 || { echo "[session-guide] không có jq → không đọc được payload, bỏ qua gợi ý đầu phiên." >&2; exit 0; }

# Marker: chỉ chạy trong dự án áp dụng khung này.
[ -d "$ROOT/docs/framework" ] || [ -f "$ROOT/.claude/commands/auto.md" ] || exit 0

# Trích "Giai đoạn hiện tại" thật (bỏ dòng rỗng và placeholder "(vd").
phase=""
if [ -f "$ROOT/PROGRESS.md" ]; then
  phase="$(awk '/## Giai đoạn hiện tại/{f=1;next} /^## /{f=0} f' "$ROOT/PROGRESS.md" \
           | sed 's/^[[:space:]]*-[[:space:]]*//' \
           | grep -v '^[[:space:]]*$' | grep -v '(vd' | head -1)"
fi

# Có thay đổi chưa commit? → coi như đang làm dở.
dirty=""
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  dirty="$(git -C "$ROOT" status --short 2>/dev/null | head -1)"
fi

# Model phiên hiện tại chỉ để HIỂN THỊ (SessionStart stdin có trường "model"; không luôn có) —
# không so khớp với một alias cố định nữa (opusplan đã ngừng hỗ trợ, xem ADR-0007).
payload="$(cat 2>/dev/null || true)"
model_id="$(printf '%s' "$payload" | jq -r '.model // empty' 2>/dev/null || true)"
if [ -n "$model_id" ]; then
  mnote="ℹ️ Model phiên: ${model_id}. Việc lập kế hoạch lớn/tự động → cân nhắc chuyển sang model cao cấp nhất đang sẵn có trước; việc thực thi/code quay lại model tiêu chuẩn (ADR-0007)."
else
  mnote="ℹ️ Không đọc được model phiên từ stdin. Việc lập kế hoạch lớn/tự động → cân nhắc chuyển sang model cao cấp nhất đang sẵn có trước; việc thực thi/code quay lại model tiêu chuẩn (ADR-0007)."
fi

if [ -z "$phase" ] && [ -z "$dirty" ]; then
  msg="🧭 Dự án dùng KHUNG (template). Chưa có tiến độ ghi nhận.
${mnote}
Bắt đầu thế nào:
• Mô tả ý tưởng/yêu cầu dự án — hoặc gõ /consult (chọn công nghệ, research-first)
• /bootstrap (dựng nền dự án mới)  •  /auto (lập kế hoạch bằng model cao cấp → chạy tự động)
• Model & chế độ tự động: docs/framework/models-and-automation.md"
else
  extra=""
  [ -n "$phase" ] && extra=" — GĐ hiện tại: ${phase}"
  [ -n "$dirty" ] && extra="${extra} (có thay đổi chưa commit)"
  msg="🧭 Dự án dùng KHUNG${extra}.
${mnote}
Tiếp theo nên:
• Gõ 'tiếp tục' để nối việc dở (PROGRESS.md đã được nạp) — xem mục 'Đang làm'/'Tiếp theo'/'Bàn giao phiên'
• /auto để tự động điều phối  •  /gate trước khi commit  •  /incident nếu có sự cố
• /completion để hoàn thiện dự án (audit 12 nhóm → kế hoạch → sửa từng đợt → quét lại đến khi sạch)"
fi

jq -n --arg m "$msg" '{systemMessage:$m}'
exit 0
