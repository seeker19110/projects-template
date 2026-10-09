// scripts/ci-workflow-policy.test.ts — bản VITEST của scripts/check-ci-policy.sh, cho DỰ ÁN ĐÍCH
// (repo khung không có package.json nên không chạy được vitest — xem CODEMAP.md của khung).
//
// VÌ SAO CẦN (docs/specs/2026-09-12-traps-codemap-ci-policy.md, lỗ hổng C): `ci.yml` có nhiều job
// PHẲNG, không `needs:` — không có job tổng hợp để gom, nên branch protection trên GitHub phải
// liệt kê ĐÚNG TÊN từng job. Đổi tên/xoá một job id mà quên cập nhật danh sách required checks thì
// hỏng theo kiểu IM LẶNG: workflow vẫn chạy, vẫn xanh, nhưng required check cũ không bao giờ báo
// cáo nữa (PR kẹt vĩnh viễn) hoặc job mới không được tính vào cổng bắt buộc (đỏ vẫn merge được).
//
// CỐ Ý chỉ kiểm CẤU TRÚC (job id có khớp danh sách khai báo không), KHÔNG kiểm nội dung từng bước —
// ép nội dung sẽ biến test thành vật cản mỗi lần thêm một bước kiểm mới.
//
// BẢNG KIỂM (ID khai ở scripts/check-ci-policy.sh — bản shell của repo khung; xem W-302):
//   CP-1  job id trong workflow ↔ bản kê required checks (hai chiều)   → ĐÃ IMPLEMENT dưới đây
//   CP-2  mọi `uses:` ghim full commit SHA                             → ĐÃ IMPLEMENT dưới đây
//   CP-3  `node-version:` khớp .nvmrc                                  → ĐÃ IMPLEMENT dưới đây
//   CP-4  mọi job ci.yml có trong `needs:` của job tổng hợp `gate`     → KHÔNG ÁP DỤNG cho dự án
//         đích: job `gate` là quy ước của RIÊNG repo khung (ADR-0003), khung không áp đặt cấu trúc
//         job lên dự án đích (xem LƯU Ý ngay dưới). Dự án đích tự thêm nếu muốn.
//   CP-5  sổ SKIP_ALLOWED khớp bằng đúng tập job có `if:`              → KHÔNG ÁP DỤNG cho dự án
//         đích, CÙNG LÝ DO với CP-4: nó kiểm nội dung bước "Kết luận từ mọi job cổng" của job
//         `gate`, mà `gate` là quy ước riêng của repo khung. NHƯNG bài học thì áp cho mọi dự án có
//         job tổng hợp — xem LƯU Ý ngay dưới, mục (c).
//   CP-6  mọi scripts/test-*.sh được ci.yml gọi                        → KHÔNG ÁP DỤNG cho dự án
//         đích: dự án đích chạy test qua test runner (vitest/jest) chứ không qua `scripts/test-*.sh`,
//         nên quy ước đặt tên này là của RIÊNG repo khung.
// Thêm/bỏ một CP-* ở bản shell mà quên khai ở đây → `check-ci-policy.sh` mục 7 làm CI đỏ.
//
// LƯU Ý cho dự án đích đã tự thêm job tổng hợp (`quality`/`e2e` có `needs:`, chia mảnh E2E…):
// đó là quy ước RIÊNG của dự án, không phải bất biến của khung — thêm test riêng cho quy ước đó,
// đừng sửa file này để giả định một cấu trúc mà khung không áp đặt. Ba cái bẫy đáng chép sang test
// riêng đó, cả ba đều là cổng-xanh-giả (job chạy/không chạy mà đỏ vẫn không chặn merge được):
//   (a) job cổng KHÔNG nằm trong `needs:` của job tổng hợp → đỏ của nó không chặn gì (khuôn CP-4);
//   (b) job tổng hợp thiếu `if: always()` → job con đỏ làm nó bị BỎ QUA, mà "bỏ qua" ở nhiều cấu
//       hình branch-protection lại không tính là trượt;
//   (c) job tổng hợp tính mọi `skipped` là đạt → một job bị `if:` viết hỏng loại ra sẽ im lặng qua
//       cổng (khuôn CP-5). Cách chặn: giữ một SỔ TƯỜNG MINH các job được phép skip, so BẰNG ĐÚNG
//       với tập job thật sự có `if:` — lệch chiều nào cũng đỏ. `join(needs.*.result)` không đủ để
//       làm việc này vì nó mất TÊN job; dùng `toJSON(needs)`.

import { describe, it, expect } from 'vitest'
import { readFileSync, existsSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = process.cwd()
// Còn nằm trong _framework-dropins/ (copy-framework.sh vừa phát, chưa merge vào scripts/) thì vitest của
// dự án đích vẫn gom file này theo mẫu **/*.test.ts → đỏ ngay sau khi copy vì .github/workflows chưa có
// (TRAPS 57, 2026-10-09). Tự bỏ qua cho tới khi được chuyển vào chỗ thật; CP-2 vẫn tự bảo vệ khỏi suite rỗng.
const STAGED = fileURLToPath(import.meta.url).split(/[\\/]/).includes('_framework-dropins')
const WORKFLOW_FILES = ['ci.yml', 'pr-policy.yml']
const SETTINGS_FILE = join(ROOT, 'docs', 'ops', 'repository-settings.md')

// Tự tách khối job thay vì kéo thêm một thư viện YAML: chỉ cần biết id job (thụt lề 2 khoảng,
// đúng chuẩn Prettier giữ cho *.yml), không cần phần thân.
function parseJobIds(yml: string): string[] {
  const lines = yml.split('\n')
  const start = lines.findIndex((l) => l === 'jobs:')
  if (start === -1) return []
  const ids: string[] = []
  for (const line of lines.slice(start + 1)) {
    const header = /^ {2}([A-Za-z0-9_-]+):/.exec(line)
    if (header?.[1]) ids.push(header[1])
    else if (/^[A-Za-z]/.test(line)) break // về lại cột 0 → hết khối jobs
  }
  return ids
}

// Khối fenced code block ĐẦU TIÊN trong repository-settings.md, dạng "workflow.yml: job-id" mỗi dòng.
function parseDeclaredJobs(md: string): Set<string> {
  const lines = md.split('\n')
  const declared = new Set<string>()
  let inBlock = false
  for (const line of lines) {
    if (line.trim() === '```') {
      if (!inBlock) {
        inBlock = true
        continue
      } else break
    }
    if (inBlock) {
      const m = /^([a-zA-Z0-9_.-]+\.yml):\s*([A-Za-z0-9_-]+)\s*$/.exec(line)
      if (m) declared.add(`${m[1]}:${m[2]}`)
    }
  }
  return declared
}

describe.skipIf(STAGED)('required checks — .github/workflows/{ci,pr-policy}.yml ↔ docs/ops/repository-settings.md', () => {
  it('docs/ops/repository-settings.md tồn tại và có khối required checks', () => {
    expect(existsSync(SETTINGS_FILE), 'thiếu docs/ops/repository-settings.md — copy lại khung').toBe(
      true
    )
  })

  const settingsMd = existsSync(SETTINGS_FILE) ? readFileSync(SETTINGS_FILE, 'utf-8') : ''
  const declared = parseDeclaredJobs(settingsMd)

  it('đọc được ít nhất một job khai báo trong khối required checks', () => {
    expect(declared.size).toBeGreaterThan(0)
  })

  for (const wf of WORKFLOW_FILES) {
    const file = join(ROOT, '.github', 'workflows', wf)
    if (!existsSync(file)) continue // dự án đích có thể không dùng pr-policy.yml

    const actualIds = parseJobIds(readFileSync(file, 'utf-8'))

    it(`${wf}: tách được job (tự bảo vệ khỏi test rỗng luôn xanh)`, () => {
      expect(actualIds.length).toBeGreaterThan(0)
    })

    it.each(actualIds)(`${wf}: job \`%s\` phải được khai trong repository-settings.md`, (id) => {
      expect(
        declared.has(`${wf}:${id}`),
        `Job '${wf}:${id}' có thật trong workflow nhưng chưa khai trong docs/ops/repository-settings.md`
      ).toBe(true)
    })

    it(`${wf}: mọi job khai báo cho ${wf} phải còn tồn tại thật`, () => {
      const declaredForThisFile = [...declared]
        .filter((k) => k.startsWith(`${wf}:`))
        .map((k) => k.slice(wf.length + 1))
      const dead = declaredForThisFile.filter((id) => !actualIds.includes(id))
      // Báo thẳng tên job đã chết — branch protection đang canh một tên không còn báo cáo nữa.
      expect(dead, `Job đã khai nhưng không còn tồn tại trong ${wf}`).toEqual([])
    })
  }
})

// ── CP-2: mọi GitHub Action phải ghim full commit SHA ──
// Tag di động (`@v4`) nghĩa là mã chạy trong CI có thể đổi dưới chân bạn mà không có PR nào.
describe.skipIf(STAGED)('CP-2 — chuỗi cung ứng: action ghim full commit SHA', () => {
  const wfDir = join(ROOT, '.github', 'workflows')
  const files = existsSync(wfDir)
    ? readdirSync(wfDir).filter((f) => f.endsWith('.yml') || f.endsWith('.yaml'))
    : []

  it('tìm thấy ít nhất một workflow (tự bảo vệ khỏi test rỗng luôn xanh)', () => {
    expect(files.length).toBeGreaterThan(0)
  })

  for (const f of files) {
    it(`${f}: mọi uses: đã ghim SHA40`, () => {
      const unpinned: string[] = []
      for (const line of readFileSync(join(wfDir, f), 'utf-8').split('\n')) {
        const ref = line.match(/^\s*-?\s*uses:\s*(\S+)/)?.[1]
        if (!ref) continue
        if (ref.startsWith('./') || ref.startsWith('docker://')) continue // action local/docker
        if (!/@[0-9a-f]{40}$/.test(ref)) unpinned.push(ref)
      }
      expect(unpinned, `Action chưa ghim SHA (dùng: uses: <action>@<sha40> # <tag>)`).toEqual([])
    })
  }
})

// ── CP-3: node-version trong workflow khớp .nvmrc ──
// Lệch nghĩa là CI test bằng Node khác Node dev — hỏng im lặng, rất khó lần ra.
describe.skipIf(STAGED)('CP-3 — node-version khớp .nvmrc', () => {
  const nvmrcPath = join(ROOT, '.nvmrc')
  const wfDir = join(ROOT, '.github', 'workflows')

  it.runIf(existsSync(nvmrcPath) && existsSync(wfDir))('mọi node-version khớp .nvmrc', () => {
    const want = readFileSync(nvmrcPath, 'utf-8').trim()
    const bad: string[] = []
    for (const f of readdirSync(wfDir).filter((x) => x.endsWith('.yml') || x.endsWith('.yaml'))) {
      for (const line of readFileSync(join(wfDir, f), 'utf-8').split('\n')) {
        const raw = line.match(/node-version:\s*(.+)$/)?.[1]
        if (!raw) continue
        const val = raw.trim().replace(/['"]/g, '')
        if (val.startsWith('${{')) continue // biểu thức matrix
        if (val !== want) bad.push(`${f}: '${val}' ≠ .nvmrc '${want}'`)
      }
    }
    expect(bad, 'node-version lệch .nvmrc').toEqual([])
  })
})
