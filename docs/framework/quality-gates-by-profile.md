# Cổng chất lượng cụ thể theo hồ sơ (C2–C10) + quyền riêng tư dữ liệu

> `03-tech-selection-and-proactive-advice.md` PHẦN C đặt tên "cổng đặc thù" cho từng hồ sơ (mỗi hồ sơ một
> dòng tóm tắt). File này viết **cụ thể, đo được** từng cổng đó — cùng độ chi tiết với `CLAUDE.md` §3(B)
> cho web/UI — để `/gate` và cổng merge có tiêu chí thật để đối chiếu, không chỉ tên gọi chung chung.
> **C1 (Web app) đã có đủ ở `CLAUDE.md` §3(B) — không lặp lại ở đây.**
> Đọc đúng phần khớp hồ sơ dự án (PHẦN A0 của `03-tech-selection-and-proactive-advice.md`); dự án đa
> thành phần (C10) đọc phần của từng thành phần con.
> Con số ngân sách (thời gian tải, fps, kích thước…) là **điểm khởi đầu tham khảo** — dự án tự chốt số
> thật vào `PROJECT.md`/ADR theo bối cảnh (thiết bị mục tiêu, đối tượng dùng); không dùng máy móc.

---

## Cổng bổ sung áp cho MỌI hồ sơ có dữ liệu cá nhân (không riêng web)

> Khoảng trống trước đây: `CLAUDE.md` §3.2 chỉ nói "không tin client, bảo mật server-side" — chưa nói rõ
> vòng đời **dữ liệu cá nhân** (PII). Áp cho bất kỳ hồ sơ nào (C1–C10) có thu thập/lưu dữ liệu người dùng
> thật, kể cả khi không phải web (app mobile, backend, pipeline data/ML).

1. **Thu thập tối thiểu:** chỉ lưu trường dữ liệu cá nhân thực sự cần cho tính năng; không lưu "phòng khi cần sau".
2. **Khai báo rõ mục đích dùng** ở nơi thu thập (form, permission prompt, API doc) — không dùng cho mục đích khác mà không hỏi lại.
3. **Xóa được theo yêu cầu** (right to delete/erasure): có đường xử lý xóa dữ liệu cá nhân của một người dùng cụ thể, kể cả bản sao/backup/log — không chỉ xóa ở bảng chính.
4. **Ẩn danh hóa trước khi dùng cho mục đích thứ cấp** (phân tích, huấn luyện model — xem thêm C7 mục 5).
5. **Mã hóa khi lưu trữ** với dữ liệu nhạy cảm (mật khẩu, thông tin định danh, thanh toán) — không lưu plaintext.
6. **Log không chứa PII thô** (không log mật khẩu, số thẻ, token phiên) — che/hash trước khi ghi log.
7. **Có thời hạn giữ dữ liệu** (retention) đã quyết định và ghi trong ADR/`PROJECT.md`, không giữ vô thời hạn mặc định.

Vi phạm mục nào trong 7 mục trên khi đụng dữ liệu người dùng thật → **dừng và hỏi** (`CLAUDE.md` §9), không tự quyết định thay người dùng.

---

## C2 — Mobile native

1. **Cold start** ≤ ngân sách đã chốt (điểm khởi đầu tham khảo: 2s trên thiết bị tầm trung) — đo bằng thời gian tới màn hình tương tác đầu tiên, không phải chỉ splash screen.
2. **60fps khi cuộn/chuyển màn** ở luồng chính — không giật (frame time không vượt ngưỡng đã chốt) trên thiết bị thấp nhất còn hỗ trợ.
3. **Kích thước app** ≤ ngân sách đã chốt trong `PROJECT.md` (khác nhau nhiều theo loại app — không có số chung).
4. **A11y nền tảng:** mọi control chính đọc được bằng TalkBack (Android) và VoiceOver (iOS); tương phản đạt AA; vùng chạm ≥ 44×44px.
5. **Permission tối thiểu, xin đúng lúc dùng** (không xin toàn bộ permission lúc mở app lần đầu) — kèm giải thích lý do trước khi xin (rationale).
6. **Trạng thái mất mạng/offline** có xử lý rõ ràng (không crash, không treo loading vô hạn); nếu app cần offline-first, có chiến lược đồng bộ khi có mạng lại.
7. **E2E thiết bị** (Maestro/Detox) cho luồng chính (đăng nhập, luồng lõi của app) chạy trước mỗi build release.
8. **Test trên cả hai nền tảng** (iOS + Android, thiết bị thật hoặc simulator/emulator đại diện) trước khi release — không chỉ test trên một nền tảng rồi suy ra nền tảng kia.

## C3 — Desktop app

1. **Code signing/notarization bắt buộc** trước phát hành — không phát hành bản để trình cài đặt cảnh báo "nhà phát hành không xác minh".
2. **Auto-update an toàn:** có cơ chế xác minh bản cập nhật (chữ ký/checksum) trước khi cài; có đường **rollback** nếu bản mới lỗi.
3. **Quyền truy cập hệ thống** (file system, camera, micro, accessibility API…) xin tối thiểu cần thiết, giải thích lý do; không chạy nền/khởi động cùng OS nếu người dùng không đồng ý.
4. **Thời gian khởi động** ứng dụng ≤ ngân sách đã chốt trong `PROJECT.md`.
5. **Test trên mọi OS mục tiêu** (Windows/macOS/Linux — tùy phạm vi đã chốt) trước khi release, không chỉ test trên OS của máy dev.

## C4 — Backend / API / dịch vụ

1. **Validate runtime mọi input** (body/query/header) bằng schema — không chỉ dựa vào type tĩnh của ngôn ngữ.
2. **p95 latency** ≤ ngân sách đã chốt trong `PROJECT.md`, đo bằng tracing/metric thật (không chỉ đo local).
3. **Idempotency key** cho mọi thao tác ghi có thể gọi lại (thanh toán, tạo đơn, gửi thông báo) — gọi lại cùng key không tạo bản ghi trùng.
4. **Rate limit** áp cho endpoint công khai/nhạy cảm (auth, tìm kiếm nặng) — có test xác nhận limit hoạt động.
5. **OpenAPI/schema đồng bộ với code thật** — kiểm tự động (generate từ code hoặc test contract), không để tài liệu lệch code.
6. **Migration có phiên bản, rollback được** — test migration trên bản sao dữ liệu trước khi chạy production.
7. **Health-check endpoint** + **log có cấu trúc** (JSON, có trace id) + **tracing** cho request xuyên service.
8. **Test integration** chạy DB/service phụ thuộc **thật** (qua testcontainers hoặc tương đương) cho luồng quan trọng — không mock toàn bộ tầng dữ liệu.

## C5 — Site nội dung tĩnh / SEO nặng

1. **Lighthouse CI** đạt ngân sách CWV như C1 (LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1).
2. **`sitemap.xml` + `robots.txt`** hợp lệ và tự sinh khi thêm trang mới; không quên trang mới trong sitemap.
3. **OG tags + structured data (JSON-LD)** hợp lệ cho mọi trang có nghĩa để chia sẻ/index — kiểm bằng validator (Rich Results Test hoặc tương đương) trước khi coi là xong.
4. **Ngân sách JS** cho trang thuần đọc — không tải framework JS nặng cho nội dung tĩnh không cần tương tác.
5. **Broken link check tự động** trong CI (nội bộ + tối thiểu link ngoài quan trọng) — không phát hiện thủ công.

## C6 — CLI / Thư viện / SDK

1. **SemVer nghiêm:** phá vỡ API công khai = bump major; ghi rõ trong `CHANGELOG.md` (breaking change mục riêng).
2. **Test snapshot/golden** cho output CLI hoặc API công khai — đổi output có chủ đích thì nêu lý do + diff, không `-u` phản xạ (đúng luật golden test ở `CLAUDE.md` §5).
3. **README có ví dụ chạy được thật** — ví dụ trong tài liệu được test tự động (doctest hoặc test riêng chạy đúng snippet đó), không để ví dụ lỗi thời.
4. **Không thêm dependency runtime mới** mà không cân nhắc kích thước bundle/attack surface — ưu tiên 0-dependency hoặc dependency đã kiểm chứng.
5. **Test trên ma trận phiên bản runtime** đã công bố hỗ trợ (vd 3 phiên bản Node gần nhất) — không chỉ test trên phiên bản dev đang dùng.

## C7 — Data / ML / AI

1. **Tái lập được:** seed cố định + version hóa dữ liệu và model (DVC/MLflow hoặc tương đương) — chạy lại cùng input/config phải ra cùng kết quả (hoặc sai số đã biết).
2. **Data validation** (schema, kiểu, miền giá trị, tỷ lệ null bất thường) chạy trước khi train/serve — dữ liệu không đạt validation thì dừng pipeline, không âm thầm bỏ qua.
3. **Eval set cố định**, so metric với baseline **trước khi** thay model vào production — không tự tin bằng cảm tính là "model mới chắc tốt hơn".
4. **Giám sát drift** dữ liệu đầu vào/đầu ra ở production (cảnh báo khi lệch ngưỡng đã chốt) — không chỉ đánh giá một lần lúc launch.
5. **Không train/serve trên dữ liệu cá nhân chưa ẩn danh hóa** nếu không có sự đồng ý rõ ràng của người dùng (đối chiếu mục "Cổng bổ sung PII" ở đầu file).
6. Nếu xây ứng dụng dùng LLM: dùng **model Claude mới nhất phù hợp bài toán**, xác minh bằng skill `claude-api` — không đoán tên/giá theo trí nhớ.
7. **"Kill-switch" cho tính năng gọi LLM production:** mọi tính năng gọi LLM ở production phải có một cấu hình có thể **TẮT TỨC THÌ không cần deploy lại** (feature flag/cấu hình DB có cache ngắn — vài chục giây, không phải biến môi trường cần redeploy), dùng khi phát hiện chi phí AI tăng bất thường (bug vòng lặp gọi API, spam, prompt injection gây gọi tool lặp) — đây là cầu dao khẩn cấp **runtime**, khác với việc ước tính/dự báo chi phí lúc dev (`.claude/hooks/usage-guard.sh`/`scripts/usage-estimate.sh` của khung chỉ là dự báo trước, không thay được cầu dao runtime này).
8. **Eval bắt buộc khi đổi prompt/model:** mọi PR đổi system prompt, đổi model, hoặc đổi guardrail của một tính năng AI phải chạy lại một bộ eval offline có **golden fixtures cố định** (input mẫu + kỳ vọng đã chốt) và **dán bảng so sánh với baseline trước đó vào PR** (metric kiểu recall/precision/tỷ lệ đúng, tùy bài toán) — không merge một thay đổi prompt/model mà "cảm tính là chắc tốt hơn" (đối chiếu mục 3 phía trên "Eval set cố định, so metric với baseline trước khi thay model vào production" — mục 8 này áp cùng nguyên tắc đó cho **mọi** thay đổi prompt/model, không chỉ lúc thay model). Tham chiếu mẫu: `docs/framework/templates/AI-EVAL.template.md`.

## C8 — Game

1. **Frame budget** (mặc định tham khảo 60fps, hoặc ngân sách đã chốt) đạt trên **thiết bị mục tiêu thấp nhất** còn hỗ trợ — đo bằng profiler thật, không đo trên máy dev mạnh nhất.
2. **Thời gian tải màn đầu** ≤ ngân sách đã chốt trong `PROJECT.md`.
3. **Kích thước build** ≤ giới hạn nền tảng phân phối (store/web) đã chọn.
4. **Playtest có kịch bản** cho luồng chính (tutorial, gameplay lõi) trước mỗi bản release — không chỉ tự chơi thử ngẫu hứng.
5. **Profiling bắt buộc trước khi tối ưu hiệu năng** — không đoán bottleneck rồi sửa mò.

## C9 — Blockchain / Web3

1. **Audit bảo mật độc lập bắt buộc trước khi lên mainnet** — không lấy việc AI/đội tự rà làm thay thế cho audit độc lập.
2. **Test coverage cao cho contract + fuzzing** (slither/echidna hoặc tương đương) — vì lỗi không sửa được sau khi deploy (bất biến), cổng test ở đây **cứng hơn** mức thường của khung.
3. **Không có hàm rút quỹ/mint không kiểm soát** — mọi hàm ảnh hưởng tới quỹ/nguồn cung phải có kiểm soát quyền (access control) rà kỹ, có test riêng cho từng đường tấn công đã biết (reentrancy, overflow, front-running…).
4. **Chạy đủ lâu trên testnet** trước mainnet; có kế hoạch pause/upgrade (nếu kiến trúc contract cho phép) khi phát hiện sự cố sau deploy.
5. **Private key/secret không bao giờ nằm trong code/log/lịch sử git** — kể cả key ví test dùng nội bộ.

## C10 — Monorepo đa thành phần

1. **Build/test chỉ phần bị ảnh hưởng** (affected) + cache — không chạy lại toàn repo cho mỗi thay đổi nhỏ.
2. **Không import vòng** giữa packages; ràng buộc biên (ai được import ai) kiểm tự động bằng lint/dependency-cruiser hoặc tương đương, không chỉ dựa vào quy ước bằng lời.
3. **Mỗi `apps/*`/`packages/*` áp đúng cổng của hồ sơ tương ứng** (C1–C9 ở trên) — monorepo không tự sinh ra cổng riêng, nó tổng hợp cổng của các thành phần con.
4. **Versioning nội bộ rõ ràng** (independent hay fixed/lockstep) — quyết định ghi trong ADR, không để mỗi package tự phát minh cách versioning riêng.

---

## Khi dự án chưa khớp hồ sơ nào (embedded/IoT, AR/VR, …)

Không coi là "ngoài khả năng của khung" — áp đúng **phương pháp** ở PHẦN A–B của
`03-tech-selection-and-proactive-advice.md` (research-first, cân bằng phổ biến↔năng lực, xác minh phiên
bản) để tự dựng cổng chất lượng đặc thù mới, rồi **ghi ADR** — không chờ file này liệt kê sẵn mới làm.
