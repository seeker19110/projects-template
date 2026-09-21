# Học từ repo / khung / skill BÊN NGOÀI — phương pháp ba cột

> Dùng khi: người dùng đưa một repo, một bộ skill, một bài viết "best practice" và bảo *"lấy cái hay của nó
> về"*; hoặc khi bạn tự thấy một công cụ hay và định mang vào. Đọc file này **trước khi chép một dòng nào**.

## 0. Vì sao cần luật riêng cho việc này

Chép một thực hành hay vào một repo **đã có thực hành đó** không phải là "thừa một chút" — nó là một
**nguồn lệch mới**: hai chỗ nói cùng một luật, hai sổ phải khớp nhau bằng tay, và tới lúc chúng lệch thì
không ai biết chỗ nào đúng. Với repo khung, rủi ro còn cao hơn: khung là thứ được **chép sang nhiều dự án**,
nên một luật thừa nhân bản theo.

Rủi ro ngược lại cũng thật: bỏ qua một thứ hay chỉ vì "trông quen quen". Ba cột dưới đây tách hai ca đó ra.

## 1. Ba cột — bắt buộc điền đủ

Với **mỗi** hạng mục của nguồn ngoài, xếp vào đúng một cột:

| Cột | Nghĩa | Việc phải làm |
|---|---|---|
| **Đã có và SÂU HƠN** | ở đây đã có, và bản ở đây mạnh hơn | không lấy gì; ghi một câu *mạnh hơn ở chỗ nào* |
| **Đã có nhưng NÔNG HƠN** | cùng ý, bản ở đây yếu hơn ở một điểm **cụ thể** | chỉ lấy **đúng điểm đó**, không lấy cả hạng mục |
| **CHƯA CÓ** | không có gì tương đương | phải qua được cổng §2 mới được lấy |

Không có cột "hay quá, lấy luôn". Một hạng mục không xếp được vào cột nào nghĩa là bạn chưa hiểu nó hoặc
chưa hiểu repo mình — đọc tiếp, đừng chép.

## 2. Cổng cho cột "CHƯA CÓ": phải ứng với một SỰ CỐ THẬT

Trả lời được câu này thì mới lấy:

> Hạng mục này giải quyết **sự cố nào đã thực sự xảy ra**?

Bằng chứng nhận được: một mục trong `TRAPS.md`; một bug/incident đã ghi; một PR phải làm lại; một lần audit
phát hiện; một lần người dùng phải sửa tay thứ đáng lẽ tự động. **Không** nhận: "thực hành tốt mà", "sớm muộn
cũng cần", "repo kia có mà mình không có".

Không có sự cố tương ứng → xếp **"chưa cần"**, ghi rõ lý do, và ghi luôn **điều kiện xem lại** (vd *"xem lại
khi số lệnh > 5"*). "Chưa cần" không phải "không bao giờ" — nó là một quyết định có hạn dùng.

**Riêng repo KHUNG (`projects-template`):** sự cố được tính cả ở **dự án đích** mà khung phục vụ, không chỉ ở
repo khung. Khung tồn tại để đóng gói bài học **trước khi** dự án đích mắc lại. Nhưng vẫn phải chỉ ra sự cố
thật ở đâu đó — "về lý thuyết thì tốt" vẫn không đủ.

## 3. Luật quan trọng nhất: **grep CỔNG ĐANG CHẠY, đừng đọc văn xuôi**

Đây là chỗ trượt đắt nhất, và nó trượt theo cách rất thuyết phục.

Tài liệu mô tả vấn đề thường **cũ hơn** cổng đã bịt vấn đề đó. Bạn đọc một câu kiểu *"ba lối thoát này không
có trần, không ai đếm lại"*, tin rằng chỗ đó còn trống, rồi xây lại thứ đã có — trong khi bản có sẵn còn mạnh
hơn bản bạn đang viết.

Trước khi kết luận "chưa có", chạy **cả ba** kiểu tìm dưới đây, không chỉ kiểu đầu:

```bash
# 1. Tên khái niệm trong tài liệu — KHÔNG đủ để kết luận, chỉ để định hướng
grep -ril "<khái niệm>" --exclude-dir=.git .

# 2. CỔNG: test/script/job CI đang thực thi luật đó — đây mới là câu trả lời
grep -rn "def test_\|^[a-z_]*()" --include='*.py' --include='*.sh' . | grep -i "<khái niệm>"
ls .github/workflows/ && grep -n "^  [a-z-]*:" .github/workflows/*.yml

# 3. Hằng số/sổ mà cổng đó so — thứ hay nằm ở file test, không nằm ở tài liệu
grep -rn "BASELINE\|TRAN_\|THRESHOLD\|fail_under\|ceiling" --exclude-dir=.git .
```

Quy tắc rút gọn: **tài liệu nói "chưa có" chỉ là giả thuyết; một lần `grep` ra cổng đang chạy mới là dữ kiện.**
Và nếu phát hiện tài liệu nói sai (luật đã có cổng mà văn xuôi vẫn bảo chưa), **đó là một phát hiện phải ghi
lại** — chính câu văn đó sẽ lừa người tiếp theo.

## 4. Kiểm tra mâu thuẫn luật, không chỉ kiểm trùng lặp

Một hạng mục có thể **chưa có** mà vẫn **không được lấy**, vì nó ngược với một luật đang có hiệu lực. Ví dụ
thật: một khung có kỹ năng "phỏng vấn dồn dập để làm rõ yêu cầu trước khi code"; một repo khác có luật "khi
bối rối thì nêu giả định rồi đi tiếp, chỉ dừng hỏi trong 4 trường hợp". Hai thứ đều hợp lý, nhưng lấy cái
trước vào repo sau là **cấy một mâu thuẫn luật** — và AI đọc luật sẽ chọn ngẫu nhiên tuỳ phiên.

Nên với mỗi hạng mục sắp lấy, hỏi thêm: *luật nào đang có ở đây sẽ nói ngược với nó?* Có → không lấy, hoặc
đưa mâu thuẫn ra cho người dùng quyết, đừng tự hoà giải trong im lặng.

## 5. Đầu ra bắt buộc

Một **bản đối chiếu** lưu lại (`docs/reports/<ngày>-doi-chieu-<nguồn>.md` hoặc tương đương), gồm:

- ba bảng theo ba cột, **mỗi dòng một câu lý do** — viết đủ để người khác **bác lại được**;
- cột "chưa cần" ghi kèm điều kiện xem lại;
- danh sách thứ **thực sự lấy** — thường rất ngắn;
- mọi **đính chính giữa chừng** giữ nguyên trong văn bản, không xoá dấu vết. Một ứng viên bị chính phép đo
  của mình loại bỏ là **kết quả**, không phải thất bại cần giấu.

Con số 1–2 trên 25 hạng mục là bình thường và là dấu hiệu phương pháp đang chạy đúng. Con số 20/25 gần như
luôn nghĩa là bước §3 bị bỏ.

## 6. Cạm bẫy đã mắc

- **Đọc văn xuôi mô tả vấn đề rồi tin là chỗ đó còn trống** (§3). Bẫy đã mắc thật: thứ định "bổ sung" hoá ra
  đã có cổng thật đang chạy, và bản có sẵn mạnh hơn.
- **Loại một ứng viên sau khi NGHĨ, thay vì sau khi ĐO.** Ngược lại cũng vậy: một bộ dò tưởng hay, đo thử
  trên repo thật thì ra 42 kết quả mà gần như toàn bộ là dương tính giả. Đo trước khi kết luận, cả hai chiều.
- **Chép cả hạng mục khi chỉ nông hơn một điểm.** Cột 2 tồn tại để chặn đúng việc này.
- **Giấu đính chính.** Sửa bản nháp cho "gọn" làm mất đúng phần có giá trị nhất của bản đối chiếu.
