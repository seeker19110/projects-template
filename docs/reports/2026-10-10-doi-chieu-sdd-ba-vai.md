# Đối chiếu "Spec-Driven Development — ba vai của spec" → projects-template — 2026-10-10

Nguồn: ảnh chụp reel Instagram "Mint Tech" (người dùng gửi 2026-10-10) — sơ đồ *3 roles of specification in SDLC* (reel ghi nguồn
"System Design Newsletter"): SPECIFICATION {Behavior, Scope, Edge Cases, Success Criteria} → **Spec-First** (quyết định xây gì trước
khi code) · **Spec-Anchored** (spec là mốc tham chiếu, "luôn gắn liền với codebase cho mọi thay đổi sau này") · **Spec-as-Source**
(spec sinh PLAN → TASKS → TESTS → IMPLEMENTATION, "stays connected"); caption: "AI viết code pass 100% test nhưng chạy thực tế lỗi".
Đích: `projects-template` @ `2ac2a37` (`origin/main`, sau PR #259). Câu hỏi của người dùng: *dự án đã áp dụng chưa? tích hợp sâu vào
dự án khung và dự án đích.* Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột, cổng sự cố thật, **grep cổng đang chạy**).

**Kết quả: 12 hạng mục → lấy 2** (một cổng thật cho dự án đích + một bản đồ từ vựng 3 dòng phát sang đích), **1 lỗi khung lộ ra
khi viết test** (TRAPS 64), **1 hạng mục "chưa cần" kèm điều kiện xem lại và một câu hỏi cho chủ repo** (cuối file). Câu trả lời
ngắn: khung đã có cả ba vai, ở **repo khung** sâu hơn sơ đồ ở mọi hạng mục đo được; ở **dự án đích** vai Spec-Anchored chỉ có
engine mà không có cổng nào gọi — đúng khuôn TRAPS 11/25 — nay đã nối.

## Phép đo đã chạy (không đọc văn xuôi)

```bash
grep -n "spec" .github/workflows/*.yml                              # cổng CI khung: pr-policy (feat → spec Approved), ci.yml (test-next-gen-engines)
grep -n -i "spec\|trace\|contract" docs/framework/templates/ci-target.yml   # CI phát cho ĐÍCH → 0 kết quả (trước PR này)
grep -n "spec-compiler\|_spec_contract\|pr-policy\|docs/specs" copy-framework.manifest  # engine + cổng PR + README có phát sang đích
sed -n 120,362p scripts/spec-compiler.py; cat scripts/_spec_contract_gen.py            # C-1..C-4, --trace, evidence map `path::ký hiệu`
grep -n "def _spec_quality" -A 25 scripts/arch-health-radar.py                         # radar: spec phải có FR/AC + mục 11 (20% điểm)
grep -n -i "spec\|goal" scripts/maintenance-sweep.sh                                   # spec Draft/In review treo, goal BLOCKED
grep -n "AC-" docs/work/*/PLAN.md                                                      # PLAN thật nối AC? → 0 (PLAN duy nhất là audit `ci:`, không có spec)
for s in docs/specs/2026-10-0[7-9]-*.md; do python3 scripts/spec-compiler.py --trace "$s" | tail -1; done   # 5/5 TRACE COMPLETE
grep -n "^## " TRAPS.md | grep -i "spec\|AC\|lệch"                                     # 63 mục: 0 mục "sửa không-feat làm lệch AC của spec Approved"
# Đo trôi (drift) thật: touchpoint §11 của spec Approved bị sửa SAU commit cuối của spec
#   → 139/201 touchpoint (20/25 spec); file bằng chứng của 5 spec từ 2026-10-07: 9 commit đổi `scripts/test-hooks-session.sh`
#     sau spec 2026-10-07-pr-dispatch-work-memory.md — C-4 vẫn xanh (ký hiệu test còn) → neo hoạt động, không có sự cố.
```

## Ba cột

### Đã có và SÂU HƠN (8)

| Sơ đồ | Ở khung (cổng đang chạy) | Sâu hơn ở chỗ nào |
| --- | --- | --- |
| Spec gồm Behavior / Scope / Edge Cases / Success Criteria | `FEATURE-SPEC.template.md` 19 mục + Approval (§5 scope/non-goal, §6 mọi state kể cả lỗi/offline/conflict, §7 FR, §9 AC Given/When/Then, §14 abuse case, §16 bảng AC → bằng chứng); `arch-health-radar.py::_spec_quality` trừ 20% điểm khi spec thiếu FR/AC hoặc mục 11; contract C-2 đỏ khi spec không có mã yêu cầu | Sơ đồ là checklist 4 ô; khung có **cổng đo** spec vỏ rỗng (audit 2026-09-13: 2 spec dừng ở mục 5 — sự cố thật) |
| Spec-First: quyết định xây gì trước khi code | `pr-policy.yml`: PR/commit `feat` phải trỏ `docs/specs/<ngày>-<slug>.md` **Approved for implementation** — soi cả tiêu đề từng commit (PR #99 lọt `feat:` qua tiêu đề `test:`); mức S/M/L `standard-delivery.md` §3c; `/contract` chốt DDL/API trong spec trước khi code; `/grill` làm rõ trước khi viết spec | Khung cưỡng chế bằng máy và phân mức (S không spec, M spec gọn, L spec + goal); sơ đồ là nguyên tắc |
| Spec-First ở dự án đích | `copy-framework.manifest`: `pr-policy.yml`, `docs/specs/README.md`, `FEATURE-SPEC.template.md`, `new-work.sh` phát sang đích; `test-copy-framework.sh` dòng 89 đỏ nếu thiếu `docs/specs/README.md` | Đã có cổng ở đích; không có gì để lấy |
| Spec-Anchored khi triển khai ("refer back") | C-3: mọi đường dẫn mục 11 của spec Approved phải tồn tại; C-4/`--trace`: mọi AC phải có bằng chứng `path::ký hiệu` có thật, "chưa có" phải khai; `/gate` chỉ đánh ✅ tiêu chí chấp nhận khi TRACE COMPLETE **và** test xanh đúng commit; `reviewer.md`: thiếu spec/AC → `ASK-UPSTREAM`, không viết lại code; PR template "Deviation from spec"; DoD "implementation khớp spec; deviation được review" | Sơ đồ có mũi tên "refer back"; khung có 4 cổng máy + 2 luật vai trên cùng mũi tên đó |
| Spec-Anchored chạy liên tục ở REPO KHUNG ("stays connected") | `ci.yml` job `framework-lint` → `test-next-gen-engines.sh` `--compile-all` + `unittest` mỗi PR; đo: file bằng chứng `scripts/test-hooks-session.sh` đổi 9 commit sau spec 2026-10-07 mà C-4 vẫn xanh; xoá/đổi tên touchpoint hay ký hiệu test → đỏ | Neo được **đo** chạy thật, không phải lời hứa |
| Spec-as-Source → Tests ("tự sinh bộ test chuẩn") | `_spec_contract_gen.py` sinh C-1..C-4 **kiểm được thật** (`test-next-gen-engines.sh` AC-2 chứng minh contract test đỏ khi spec trỏ file không có); test hành vi viết theo TDD đỏ-trước (ADR-0005) và map vào bảng AC → bằng chứng | Khung **cố ý không** sinh test hành vi bằng máy: audit 2026-09-13 A-01 — bản đầu sinh 82/82 `assertTrue(len(x) >= 0)`, không bao giờ đỏ, "tệ hơn không có test" (sự cố thật). Sơ đồ không phân biệt test sinh ra có thể đỏ hay không |
| "AI pass 100% test nhưng chạy thực tế lỗi" | Bằng chứng phải chứng minh **hành vi** của AC, không phải file tồn tại/HTTP 200 (template §16); LD-03 evidence gắn đúng commit (`dev-task.sh gate --evidence` + `evidence-check`, từ chối evidence cũ/FAIL); §6 smoke luồng chính **thật** trước merge; golden test; hồ sơ C1 E2E + axe + Lighthouse trên CI | Khung đã đóng đúng lỗ hổng caption nêu bằng cổng, không bằng lời |
| Spec-as-Source → Plan → Tasks | `PLAN.template.md` + `subagent-dispatch.sh --check-plan` (`_plan_check.py`: route, 4 trường, placeholder, vòng phụ thuộc, nhóm PR — TRAPS 59); `docs/work/<id>/working.md` (cổng docs-consistency mục 13); goal slice table | Khung cưỡng chế **hình thức kín** của plan/task; sơ đồ chỉ vẽ mũi tên. Xem đính chính (A): khung **không sinh** PLAN từ AC — ngang về cơ chế sinh, sâu hơn về cổng |

### Đã có nhưng NÔNG HƠN (1 — lấy đúng điểm nông)

| Sơ đồ | Ở khung | Điểm nông cụ thể | Sự cố thật (cổng §2) | Lấy |
| --- | --- | --- | --- | --- |
| Spec-Anchored "stays connected" ở DỰ ÁN ĐÍCH | Engine `spec-compiler.py`/`_spec_contract_gen.py`/`spec-compiler.sh` **có phát** sang đích (manifest dòng 68–70) | `docs/framework/templates/ci-target.yml` chỉ chạy `doctor` + `gate`; `grep spec` → 0; `dev-task.sh gate` không gọi spec-compiler → ở đích, spec Approved trỏ file đã xoá/đổi tên **không cổng nào đỏ** | TRAPS 11 ("thêm code chạy được mà không nối cổng CI → code chết" — chính 4 engine này ở repo khung, audit 2026-09-13 CAO-1), TRAPS 25 (test có trong repo nhưng không job nào gọi), TRAPS 3/15 ("copy đủ file" ≠ "dùng được ở đích") | **Có**: bước `Spec contracts (docs/specs Approved → C-1..C-4)` trong `ci-target.yml` sau `gate`; test `scripts/test-adoption-smoke.sh::spec_contract_expect` chạy **đúng dòng `run:`** của drop-in trên 2 fixture Node/Python, 3 ca (chưa có spec → xanh; spec Approved trỏ file không có → đỏ; sửa về file thật → xanh), đỏ-trước 2 ca |

### CHƯA CÓ (3)

| Sơ đồ | Ở khung | Cổng §2: sự cố thật? | Kết luận |
| --- | --- | --- | --- |
| Spec-Anchored cho **mọi thay đổi sau này**: `fix`/`refactor` chạm touchpoint của spec cũ phải quay về spec (cập nhật/khai deviation) | Chỉ `feat` bị cổng; PR template có ô "Deviation from spec" nhưng không cổng nào đọc nó cho PR không-feat; `spec-driven-openspec.md` §1 đã ghi delta-spec là lỗ hổng **cố ý** để cho OpenSpec tùy chọn | **Không**: 63 mục TRAPS, `docs/work/*/done.md`, `docs/reports/*` → 0 sự cố "PR không-feat làm lệch AC của spec Approved mà không ai biết"; sự cố gần nhất là "generator ngoài spec" (#231) do `reviewer` bắt được — cổng người đã chạy. Đo: 139/201 touchpoint đã đổi sau spec, nghĩa là **mọi PR** đều chạm một spec cũ → cổng kiểu "phải nêu spec" sẽ đỏ gần như mọi PR hoặc thành ô điền lấy lệ | **Chưa cần** + §4 mâu thuẫn luật: khung coi spec là hợp đồng **theo thời điểm duyệt** (không sửa lịch sử — TRAPS 60 ghi chú FT-66/FT-71 giữ nguyên; `contract-exempt` cho spec lịch sử); bản đồ sống là `CODEMAP.md`/`FEATURE-MAP.md` (cổng docs-consistency 6/11b). **Xem lại khi:** một PR `fix:`/`refactor:` đổi cả code lẫn test bằng chứng của một AC Approved mà PR không nhắc spec và reviewer không bắt — ghi TRAPS rồi mở cổng **hẹp**: "PR sửa file nằm trong bảng bằng chứng của spec Approved phải nêu spec đó ở mục Research / Spec" (đo được: chỉ 5 spec từ 2026-10-07 có bảng bằng chứng, nhiễu thấp). Quyết định cho chủ repo ở cuối file |
| Spec-as-Source: **sinh** PLAN/tasks từ AC (`spec-compiler --plan`) | Không sinh; PLAN viết tay theo mẫu, cổng `--check-plan` kiểm hình thức | **Không**: TRAPS 59 là brief mâu thuẫn khuôn, không phải bỏ sót AC; AC bỏ sót sẽ đỏ ở C-4/`--trace` trước khi `/gate` đánh ✅ (cổng đầu ra đã có) | **Chưa cần.** Xem lại khi: một PLAN mức L của `feat` bỏ sót AC và AC đó lên `main` không bằng chứng (C-4 xanh oan) |
| Tên gọi ba vai (Spec-First / Spec-Anchored / Spec-as-Source) | `grep -rn "Spec-First\|Spec-Anchored\|Spec-as-Source"` → 0; người đọc ở đích không nhận ra khung đã có | Không phải cơ chế — là con trỏ tài liệu (cùng khuôn "bản đồ từ vựng" ở đối chiếu ralph #253) | **Lấy phần nhỏ nhất**: bảng 3 dòng trong `docs/specs/README.md` (file phát sang đích) ánh xạ vai → cổng đang chạy; không thêm luật |

## Đính chính giữa chừng (giữ nguyên)

- **(A)** Ứng viên đầu tiên định xếp "Spec-as-Source → Plan" vào "nông hơn" vì PLAN thật (`docs/work/2026-10-09-audit-full-automation/PLAN.md`)
  có 0 tham chiếu `AC-`. Đo lại: PLAN đó phục vụ 9 PR `ci:` từ audit, **không có spec** nên không có AC để nối — số 0 không phải bằng
  chứng của lỗ hổng. Xếp lại: sâu hơn về cổng, ngang về cơ chế sinh; "sinh PLAN từ AC" tách thành hạng mục chưa có → chưa cần.
- **(B)** Ca 3 của test mới ("sửa về file có thật → xanh") **đỏ** sau khi đã thêm bước CI, với thông báo lỗi của ca 2. Không phải lỗi
  bước CI: Python nạp `tests/contracts/__pycache__/*.pyc` cũ vì file sinh lại có **cùng mtime-giây và cùng kích thước** (`khong-co.sh`
  và `dev-task.sh` dài bằng nhau). Tái hiện cô lập: thứ tự có-thật → không-có → có-thật in `OK / OK / OK` — ca giữa **xanh oan**, tức
  lỗ hổng này ở chiều nguy hiểm cũng có thật và ảnh hưởng cả `test-next-gen-engines.sh` của repo khung. Sửa gốc trong
  `spec-compiler.py` (xoá `__pycache__` của thư mục đích trước khi sinh) + TRAPS 64. Một ứng viên bị chính phép đo loại bỏ rồi lộ ra
  lỗi khác là **kết quả**, không giấu.
- **(C)** Định đếm 139/201 touchpoint "trôi" là sự cố cho hạng mục Spec-Anchored-mọi-thay-đổi. Đọc kỹ: đó là **thiết kế** (spec đóng
  băng, code tiến; C-3/C-4 chỉ đòi *tồn tại*), và không có hậu quả nào được ghi. Con số là bằng chứng cho **nhiễu** của cổng định thêm,
  không phải cho nhu cầu.

## Danh sách thực sự lấy

1. `docs/framework/templates/ci-target.yml`: bước `Spec contracts (docs/specs Approved → C-1..C-4)` — `spec-compiler.sh --compile-all`
   rồi `unittest discover -s tests/contracts` khi có test sinh ra; chưa có spec → không có gì chạy, xanh.
2. `scripts/test-adoption-smoke.sh::spec_contract_expect` — chạy đúng dòng `run:` của drop-in trên 2 fixture, 3 ca, đỏ-trước.
3. `docs/specs/README.md`: bảng ba vai → cổng (phát sang đích).
4. (Lộ ra) `scripts/spec-compiler.py` xoá `__pycache__` trước khi sinh; TRAPS 64.

Không đổi: luật feature gate, template spec, `_plan_check.py`, `dev-task.sh` (399 dòng — sát trần radar, cổng mới đặt ở CI thay
vì trong gate; `xem lại khi:` dự án đích cần cổng spec chạy ở pre-commit local, khi đó tách `dev-task.sh` trước).

## Quyết định cho chủ repo (một câu)

Có mở cổng hẹp "PR sửa file trong bảng bằng chứng của spec Approved phải nêu spec ở mục Research / Spec" **ngay bây giờ** (chưa có sự
cố; nhiễu thấp vì chỉ spec từ 2026-10-07 có bảng bằng chứng), hay giữ "chưa cần" theo đúng `adopt-from-outside.md` §2 cho tới khi
khuôn đó xảy ra thật? Đề xuất: **giữ "chưa cần"**, điều kiện xem lại đã ghi ở bảng trên.
