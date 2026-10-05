# Supply-chain và release evidence

Áp mức phù hợp với loại artifact/risk; không tuyên bố SLSA level nếu chưa kiểm đủ requirement.

## Baseline mọi project

- lockfile hoặc dependency resolution có thể tái lập;
- dependency review trên PR và vulnerability update có SLA;
- workflow least privilege, không nội suy input không tin cậy vào shell;
- action bên thứ ba pin full commit SHA và được review;
- build từ clean runner/default branch/tag đã bảo vệ;
- artifact có version, digest và retention;
- release notes, license/notice và rollback/revoke procedure.

Workflow `dependency-review.yml` chạy action khi cây Git có manifest ở bất kỳ thư mục nào,
kể cả `scripts/requirements-ci.txt` và manifest trong monorepo; bước phát hiện không chỉ
nhìn gốc repo. Bật Dependency graph của GitHub và kiểm trang Dependencies xem từng manifest
được nhận diện; bước phát hiện chỉ quyết định có chạy action, không chứng minh GitHub đã phân
tích được mọi dependency. Với định dạng GitHub chưa hỗ trợ, cần nộp dependency snapshot qua API.
Khi action báo `Dependency review is not supported on this repository`, kiểm cài đặt
Dependency graph/Dependabot alerts trước khi sửa workflow. Trong PR #192, API
`GET /repos/{owner}/{repo}/vulnerability-alerts` trả 404 trước khi bật, rồi trả 204
sau khi bật; job dependency-review chạy lại đã xanh. Cài đặt live này phải được
kiểm riêng khi áp khung sang repo khác.

## SBOM

Release artifact phân phối ra ngoài hoặc production nên có SBOM CycloneDX/SPDX sinh từ dependency
truth của build. Lưu SBOM cạnh artifact/release; kiểm nó chứa direct/transitive dependencies, version,
license và package identifier. Không dùng một scanner không hiểu ecosystem làm nguồn duy nhất.

## Provenance/attestation

Với artifact đóng gói/container/binary:

1. build bằng workflow version-controlled;
2. sinh provenance/attestation gắn đúng subject digest;
3. ký bằng identity ngắn hạn/OIDC khi hỗ trợ;
4. publish artifact + checksum + SBOM + provenance;
5. verify trước deploy/promotion, không chỉ verify sau release;
6. document builder trust, inputs và limitation.

## Maturity path

| Level nội bộ | Evidence |
| --- | --- |
| SC-0 | CI + lock/dependency scan |
| SC-1 | Release digest + SBOM |
| SC-2 | Hosted build + signed provenance/attestation |
| SC-3 | Verify-before-deploy, isolated builder, policy/exception audit |

Tên nội bộ không thay thế chứng nhận SLSA. Nếu claim SLSA, map và audit theo đúng phiên bản spec.

## Exception

Dependency/action chưa pin hoặc vulnerability chưa vá phải có owner, lý do, compensating control,
expiry và issue. Exception hết hạn tự trở thành blocker release.
