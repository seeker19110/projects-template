#!/usr/bin/env bash
# Contract của CHÍNH repo khung; KHÔNG copy sang dự án đích.
# Dự án khác điền project-commands.example.sh theo stack/profile đã review.
# Doctor nạp file này nhưng không chạy các command được khai báo bên dưới.
export gate_tools='python3 node shellcheck pwsh'
export gate_python_modules='coverage radon'
export build='find scripts .claude/hooks -name "*.sh" -print0 | xargs -0 -n1 bash -n; bash -n copy-framework.sh; python3 -m compileall -q scripts tests'
# Phân tích tĩnh tương đương cho framework Bash/Python, không giả làm TypeScript type-check.
export typecheck='bash scripts/check-python-complexity.sh && bash scripts/check-shell-complexity.sh'
export lint='find . -name "*.sh" -not -path "./node_modules/*" -print0 | xargs -0 shellcheck --severity=warning; bash scripts/check-docs-consistency.sh; bash scripts/check-ci-policy.sh'
# Các suite con chạy fixture riêng; không gọi lại gate của repo khung để tránh recursion.
export test='for suite in scripts/test-*.sh; do REQUIRE_PWSH=1 bash "$suite" || exit 1; done; python3 tests/test_runtime_safety.py'
