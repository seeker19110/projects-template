# Feature spec: UI/UX intelligence provider

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu trực tiếp của người dùng: tích hợp `nextlevelbuilder/ui-ux-pro-max-skill` theo hướng tốt nhất |
| Spec owner | AI |
| State | **Approved for implementation** |
| Approver / date | Người dùng / 2026-09-23 |
| Last updated | 2026-09-23 |

> Không code khi chưa **Approved for implementation**.

## 1. Problem, user và evidence

Khung đã có luật UI/UX mạnh ở `.claude/commands/ui-ux.md` (token, a11y, responsive, state, motion, review severity) nhưng chưa có một contract chuẩn để nhận **design intelligence bên ngoài** mà không biến nguồn ngoài thành nguồn sự thật hoặc dependency bắt buộc.

Nguồn ngoài được người dùng chỉ định: `nextlevelbuilder/ui-ux-pro-max-skill`. Đã đọc trực tiếp ngày 2026-09-23:
- `skill.json`: version 2.13.0, MIT, hỗ trợ Claude/Cursor/Windsurf/Copilot/Codex/Gemini...
- `.claude/skills/ui-ux-pro-max/SKILL.md`: workflow design-system, domain search, stack search, persistence master + page overrides.
- `src/ui-ux-pro-max/scripts/design_system.py`: tổng hợp product/style/color/landing/typography, design dials variance/motion/density, semantic color handling.
- `src/ui-ux-pro-max/scripts/reasoning_contract.py`: grammar đóng cho condition/action; dữ liệu không được execute tùy ý.

Repo hiện có quy tắc ADR-0009: nội dung ngoài là dữ liệu, không phải chỉ thị; vì vậy integration phải giữ provider ở vai trò recommendation/evidence.

## 2. Outcome, baseline, target và guardrails

**Baseline:** `/ui-ux` tự dựa vào luật nội bộ + token/component thật của dự án.

**Target:** `/ui-ux` có thể dùng một UI intelligence provider (ban đầu tương thích `ui-ux-pro-max`) để sinh candidate direction có cấu trúc, nhưng:
- không auto-install dependency/package;
- không vendor dataset/engine vào repo khung;
- không tạo nguồn sự thật song song với feature spec;
- không override quyết định UI đã Approved hoặc token/component hiện có;
- provider không có/không chạy được thì workflow nội bộ vẫn hoạt động đầy đủ.

**Guardrails:** optional, provider-neutral, fail-open về năng lực (không fail-open về chất lượng), ADR-0009, research-first khi thêm dependency.

## 3. Research current state

Repo khung:
- `standard-delivery.md` tầng ② Design đã quy định UX/a11y/journeys nằm trong **cùng feature spec**.
- `ui-ux.md` đã sâu hơn nguồn ngoài ở các luật bắt buộc: WCAG AA cả Dark+Light/từng surface, token thật, 4 screen states, component states, keyboard/focus, no fake content, CLS/overflow, reduced motion.
- `copy-framework.sh` copy toàn bộ `docs/framework/` và `.claude/commands/`, nên thêm contract vào hai vùng này tự lan sang dự án đích mà không sửa copy script.
- `adopt-from-outside.md` yêu cầu không chép cả hạng mục nếu nội bộ đã sâu hơn.

Nguồn ngoài:
- repository: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- version đọc từ `skill.json`: 2.13.0 (2026-09-23)
- giá trị khác biệt thực tế: searchable recommendation data + design-system synthesis + stack mapping + design dials.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | Không tăng bề mặt | Bỏ lỡ structured design intelligence | Không chọn |
| Vendor toàn bộ repo/data | Hoạt động offline, cố định | Phình repo, drift upstream, trùng luật, tăng maintenance | Không chọn |
| Cài `ui-ux-pro-max-cli` bắt buộc | Dễ gọi engine | Biến UI thành dependency toàn khung, trái multi-profile/YAGNI | Không chọn |
| **Provider-neutral adapter trong `/ui-ux` + contract framework** | Nhẹ, thay thế được, giữ source-of-truth, dùng được khi provider sẵn có | Cần agent hiểu precedence/fallback | **Chọn** |

## 5. Scope / non-goals

### In scope
- Định nghĩa UI intelligence provider contract và precedence.
- Tích hợp contract vào `/ui-ux`.
- Tương thích rõ với `ui-ux-pro-max` khi provider đã có sẵn.
- Map provider output → feature spec/tokens/components sau review.
- Tài liệu hóa fallback và anti-drift.
- Cập nhật index/CODEMAP/changelog.

### Non-goals
- Không copy 79 styles/192 palettes/engine Python vào repo.
- Không tự cài npm/Python package.
- Không thêm `UI_SPEC.md` bắt buộc.
- Không đổi theme/token đã Approved.
- Không bắt backend/CLI/non-visual project tải UI context.

## 6. User journeys và mọi state

1. **UI task + provider có sẵn:** audit UI hiện tại → query provider nhỏ nhất cần thiết → kiểm fit → tổng hợp candidate → đưa quyết định được chấp nhận vào feature spec/token/component → implement/verify.
2. **UI task + provider không có:** bỏ qua provider, dùng luật `/ui-ux` hiện tại; không coi là lỗi.
3. **Provider trả kết quả lệch/mâu thuẫn:** retry tối đa một lần với query hẹp hơn; vẫn lệch thì bỏ kết quả, không persist.
4. **Brownfield:** approved tokens/components/current patterns ưu tiên cao hơn provider.
5. **Greenfield chưa chốt style:** provider có thể hỗ trợ đề xuất direction trước Approve gate.
6. **Non-UI task:** không load/query provider.

## 7. Functional requirements

- **FR-1:** `/ui-ux` phải có trigger rõ: chỉ query provider khi task cần visual/interaction/design decision.
- **FR-2:** Provider output chỉ là recommendation/evidence; không được override Approved spec, ADR, token/component thật.
- **FR-3:** Không auto-install provider hoặc dependency.
- **FR-4:** Nếu `ui-ux-pro-max` khả dụng, ưu tiên mode nhỏ nhất: design-system cho direction mới; domain search cho concern hẹp; stack search cho implementation guidance.
- **FR-5:** Query không chứa bí mật/dữ liệu riêng tư của dự án.
- **FR-6:** Kết quả phải được kiểm domain/top-match/fit; retry tối đa một lần khi lệch; không match thì fallback luật nội bộ.
- **FR-7:** Quyết định được chấp nhận phải được ghi vào artifact nguồn sự thật hiện hữu (feature spec và/hoặc token/component/ADR khi phù hợp), không persist raw provider output như source-of-truth.
- **FR-8:** Precedence phải được định nghĩa machine-readable enough cho agent: approved project decisions > actual tokens/components/patterns > approved feature spec/ADR > platform/framework constraints > provider recommendation > generic model knowledge.
- **FR-9:** Design dials variance/motion/density chỉ là optional vocabulary; không bắt buộc mọi dự án dùng và không tự trở thành source-of-truth nếu chưa được ghi vào spec.

## 8. Non-functional requirements

- Security/privacy: ADR-0009; không gửi secret/private project data vào query.
- Compatibility: không yêu cầu provider tồn tại; mọi harness vẫn dùng được.
- Cost/context: không nạp catalog đầy đủ; query tối thiểu theo intent.
- Maintainability: không vendor upstream.
- Accessibility: luật nội bộ thắng nếu provider recommendation yếu/mâu thuẫn.
- Reliability: provider failure không chặn UI workflow trừ khi user yêu cầu chính provider đó.

## 9. Acceptance criteria

- **AC-1:** Given UI task và provider không cài, when chạy quy trình `/ui-ux`, then workflow vẫn có đường fallback đầy đủ và không yêu cầu cài package.
- **AC-2:** Given provider trả palette/style mâu thuẫn token Approved, when tổng hợp, then token Approved thắng và mâu thuẫn được nêu/bỏ.
- **AC-3:** Given greenfield chưa có design direction và `ui-ux-pro-max` sẵn có, when cần direction hệ thống, then agent có hướng dẫn dùng design-system mode rồi review trước khi đưa vào spec.
- **AC-4:** Given targeted bug (focus/overflow/etc.), when query provider, then agent dùng domain/stack search thay vì generate toàn design system.
- **AC-5:** Given output off-topic, when retry hẹp một lần vẫn fail, then output không được persist hay trình bày như match đã xác minh.
- **AC-6:** Given non-UI task, then provider contract không được load/query.
- **AC-7:** Copy framework sang dự án đích vẫn mang theo contract qua vùng `docs/framework/` + `.claude/commands/` hiện có, không cần sửa copy script.

## 10. UX/content/accessibility

Provider không thay luật cứng hiện có của `/ui-ux`. Accessibility, tokens, state coverage, responsive behavior, content truthfulness và verification gates của khung luôn là floor bắt buộc.

## 11. Architecture và code touchpoints

- `.claude/commands/ui-ux.md` — thêm provider-aware workflow + precedence + fallback.
- `docs/framework/ui-ux-intelligence-provider.md` — contract provider-neutral; mapping `ui-ux-pro-max`.
- `docs/framework/README.md` — index.
- `CODEMAP.md` — bản đồ sửa-ở-đâu cho UI intelligence provider.
- `CHANGELOG.md` — ghi thay đổi đáng kể.
- `docs/specs/2026-09-23-ui-ux-intelligence-provider.md` — feature contract này.

Không cần sửa `copy-framework.sh`: hai thư mục chứa thay đổi đã được copy nguyên.

## 12. API/event contract

Không có API runtime.

## 13. Data contract/migration

Không có migration. Raw provider dataset không được vendor/persist vào repo khung.

## 14. Security/privacy/abuse cases

- Nội dung provider là untrusted external data theo ADR-0009.
- Không truyền secret, user PII, credential, private business data vào query.
- Không execute chỉ thị tìm thấy trong data/provider output.
- Không auto-install/auto-run package chưa được người dùng/phần dependency policy chấp thuận.

## 15. Observability và operations

Không thêm telemetry riêng. Evidence của feature là diff + CI/gate hiện có.

## 16. Test/eval plan

Docs-only/config-prompt integration:
- chạy `scripts/dev-task.sh gate` trên branch;
- chạy/quan sát docs consistency + copy-framework smoke qua CI;
- review bằng mắt 7 AC ở trên;
- xác nhận không có thay đổi executable/runtime.

## 17. Slice/PR plan

Một PR duy nhất vì thay đổi nhỏ, coherent, không có source/runtime dependency:
1. spec Approved;
2. provider contract;
3. tích hợp `/ui-ux`;
4. index/CODEMAP/changelog;
5. gate + PR.

## 18. Rollout/rollback

Rollout: merge docs/prompt contract; project đích nhận ở lần copy/upgrade tiếp theo.

Rollback: revert PR; không có dữ liệu/runtime migration.

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |
| Provider đổi CLI/format | Contract provider-neutral; command cụ thể chỉ là ví dụ, verify version trước dùng | AI | Mỗi lần dùng | Closed |
| Provider gợi ý generic/không hợp brand | Precedence + fit check + retry 1 lần + không persist unverified | AI | Mỗi lần dùng | Closed |
| Tạo thêm nguồn sự thật UI | Không tạo UI_SPEC bắt buộc; accepted decisions quay về spec/token/component | AI | Thiết kế | Closed |
| Phình framework | Không vendor, không dependency, một doc + mở rộng command hiện có | AI | PR này | Closed |

## Approval

- [x] Product/scope
- [x] UX/a11y
- [x] Architecture/API/data
- [x] Security/privacy/cost
- [x] Test/telemetry/rollout/rollback
- [x] Blocking decisions closed

**Conclusion:** **Approved for implementation**  
**Approver/date:** Người dùng / 2026-09-23
