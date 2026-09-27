# Đối chiếu 15 repo agent → projects-template

Ngày 2026-09-27. Nguồn là 15 tên trong ảnh do người dùng cung cấp; đã đọc README hiện hành qua GitHub, đối chiếu `AGENTS.md`, `docs/framework/adopt-from-outside.md`, `quality-gates-by-profile.md`, `standard-delivery.md`, `CODEMAP.md`, cổng `scripts/dev-task.sh` và các workflow. Đây là khảo sát kiến trúc qua README và cổng đích, **không** phải kiểm định mã nguồn hay bảo đảm tương thích phiên bản của cả 15 SDK.

## Nguồn và cách áp dụng

| Repo trong ảnh (link hiện hành nếu đổi) | Ý tưởng có ích | Phán quyết cho template |
|---|---|---|
| [LangGraph](https://github.com/langchain-ai/langgraph) | Chạy dài, checkpoint, can thiệp của người | C7: thử dừng/tiếp tục và chống lặp tác dụng phụ; không đóng gói runtime. |
| [OpenAI Agents SDK](https://github.com/openai/openai-agents-python) | Handoff, guardrail, session, trace | C7: test quyền tool, handoff và trace; không buộc OpenAI. |
| [Google ADK](https://github.com/google/adk-python) | Workflow xác định, tool, nhiều model | C7: phân biệt bước có thể quyết định bằng code với bước model; không buộc Gemini. |
| [Pydantic AI](https://github.com/pydantic/pydantic-ai) | Input/output có kiểu, eval | C7: schema ở biên và eval baseline; đã có cổng spec/eval, chỉ bổ sung ca tool. |
| [Semantic Kernel](https://github.com/microsoft/semantic-kernel) | Plugin và kết nối nhiều provider | README hướng sang [Microsoft Agent Framework](https://github.com/microsoft/agent-framework); giữ nguyên chọn stack theo dự án. |
| [smolagents](https://github.com/huggingface/smolagents) | Agent viết code, sandbox | C7: test giới hạn chạy code; không chạy code model trong tiến trình chính. |
| [AgentScope](https://github.com/agentscope-ai/agentscope) | Quan sát hệ nhiều agent | C7: run/task ID và log có kiểm soát; không thêm nền observability mặc định. |
| [Mastra](https://github.com/mastra-ai/mastra) | TypeScript workflow và resume | Áp phép thử resume cho dự án TS nếu cần; không thêm stack mặc định. |
| [browser-use](https://github.com/browser-use/browser-use) | Điều khiển trình duyệt | Chỉ dùng khi có tác vụ web thật, kiểm quyền và dữ liệu không tin cậy. |
| [Mem0](https://github.com/mem0ai/mem0) | Truy hồi ký ức xuyên phiên | C7: nguồn, quyền, sửa/xóa, retention; benchmark dịch vụ quản lý không suy ra cho bản OSS. |
| [Letta](https://github.com/letta-ai/letta) | Agent có trí nhớ bền | README trỏ mã hoạt động sang [letta-code](https://github.com/letta-ai/letta-code); không kéo lịch sử chat vô hạn. |
| [SWE-agent](https://github.com/SWE-agent/SWE-agent) | Coding agent có cấu hình | README khuyên [mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent); chỉ lấy ý tưởng eval trên repo thật. |
| [OpenHands](https://github.com/OpenHands/OpenHands) | Điều phối coding agent qua môi trường | Tên trong ảnh `All-Hands-AI/OpenHands` đã redirect; template vẫn trung lập runner. |
| [MCP reference servers](https://github.com/modelcontextprotocol/servers) | Ranh giới server/tool | README nói rõ chỉ là reference, không sẵn sàng production; C7 yêu cầu kiểm quyền/kết nối. |
| [CAMEL](https://github.com/camel-ai/camel) | Hệ nhiều agent và nghiên cứu | Chỉ chọn hợp tác nhiều agent khi nhiệm vụ độc lập; quy tắc chia việc hiện hành đã sâu hơn. |

## Ba cột theo quy tắc tiếp nhận

| Đã có và sâu hơn | Bằng chứng trong đích |
|---|---|
| Chọn stack và runner theo từng dự án | `03-tech-selection-and-proactive-advice.md`, `standard-delivery.md`; không áp ADK/Mastra/OpenAI làm mặc định. |
| Cổng eval, spec và tác vụ độc lập | `quality-gates-by-profile.md` C7, `AI-EVAL.template.md`, `AGENTS.md` và `scripts/dev-task.sh`; không sao chép orchestration runtime vào template. |

| Đã có nhưng nông hơn | Phần chỉ bổ sung |
|---|---|
| C7 có eval và kill switch nhưng chưa nêu phép thử agent bị ngắt và tác dụng phụ lặp | C7 mục agent 1 và 4: thử resume, đối chiếu số ca eval, trace. |
| C7 có bảo vệ PII tổng quát, thiếu tiêu chí trí nhớ xuyên phiên và quyền tool | C7 mục agent 2, 3, 5, 6: phạm vi, xóa, nguồn, quyết định người. |
| C7 §6 buộc Claude trái với nguyên tắc chọn stack research-first và lựa chọn provider của dự án | Sửa §6 thành chọn model theo eval/giá/độ trễ/quyền riêng tư, ghi fallback. |

| Chưa có / chưa cần | Sự cố thật hoặc điều kiện xem lại |
|---|---|
| SDK agent/runtime, vector DB, browser controller, MCP server đi kèm | Template cố ý không cung cấp scaffold; chỉ thêm vào **dự án đích** sau khi spec có tác vụ thật và eval chứng minh cần. |
| Một sổ nhớ hoặc workflow engine thứ hai | Không có sự cố của template đòi runtime; xem lại khi có dự án đích gặp mất state được tái hiện và cách đang dùng không xử lý được. |

## Kết quả và giới hạn

Đã sửa đúng một mục lựa chọn model và thêm cổng C7 theo trường hợp agent. Chúng **chưa tự động chạy trong CI của ứng dụng đích**: lúc áp dụng template, chủ dự án phải chọn phép kiểm theo profile, viết test/fixture và đưa vào `dev-task.sh gate`. Không tuyên bố các 15 repo có cùng API, giấy phép hay mức ổn định; kiểm README, license, release và mã nguồn ở phiên bản dự định dùng trước khi chọn dependency.
