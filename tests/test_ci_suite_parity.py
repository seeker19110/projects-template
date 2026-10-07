"""Prove every shell suite runs once on Linux, not again through the local gate.

This checks this repository's deliberately flat workflow format, not arbitrary YAML.
Windows repeats remain intentional portability tests. It never executes CI commands.
"""
from collections import Counter
from pathlib import Path
import re
from unittest import TestCase, main

ROOT = Path(__file__).resolve().parents[1]


def linux_commands(workflow):
    commands = []
    for job in re.split(r"(?m)^  (?=[\w-]+:\s*$)", workflow):
        if not re.search(r"(?m)^    runs-on: ubuntu-latest\s*$", job):
            continue
        multiline = False
        for line in job.splitlines():
            match = re.match(r"(?:      -|       ) run: (.+)$", line)
            if match:
                body = match[1].strip()
                multiline = body in ("|", "|-", "|+")
                if not multiline:
                    commands.append(body)
            elif multiline and line.startswith("          "):
                commands.append(line[10:])
            elif line.strip():
                multiline = False
    return commands


def suite_counts(workflow, suites):
    counts = Counter()
    for line in linux_commands(workflow):
        call = re.fullmatch(r'(?:\w+=[^\s]+\s+)*bash\s+(scripts/test-[\w-]+\.sh)', line.strip())
        if call:
            counts[call[1]] += 1
        if line.strip() == 'bash scripts/dev-task.sh gate':
            counts.update(suites)
    return counts


class CiSuiteParity(TestCase):
    def test_every_linux_suite_runs_exactly_once(self):
        suites = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 'scripts').glob('test-*.sh'))
        self.assertGreater(len(suites), 0)
        counts = suite_counts((ROOT / '.github/workflows/ci.yml').read_text(encoding='utf-8'), suites)
        self.assertEqual(counts, Counter(suites), 'Missing or duplicated Linux suites; do not hide them behind a second gate run')

    def test_local_gate_still_runs_all_suites(self):
        config = (ROOT / '.claude/project-commands.sh').read_text(encoding='utf-8')
        self.assertIn('for suite in scripts/test-*.sh; do REQUIRE_PWSH=1 bash "$suite" || exit 1; done', config)
        self.assertIn('python3 tests/test_runtime_safety.py', config)
        self.assertIn('python3 tests/test_ci_suite_parity.py', config)
        self.assertIn('python3 tests/test_profile_quality_matrix.py', config)
        self.assertIn('python3 tests/test_lean_adoption.py', config)

    def test_counts_execution_not_names_comments_or_windows(self):
        workflow = '''jobs:
  linux:
    runs-on: ubuntu-latest
    steps:
      - name: bash scripts/test-a.sh
        run: |
          # bash scripts/test-a.sh
          echo bash scripts/test-a.sh
          bash scripts/test-a.sh
      - run: REQUIRE_PWSH=1 bash scripts/test-b.sh
  windows:
    runs-on: windows-latest
    steps:
      - run: bash scripts/test-a.sh
'''
        self.assertEqual(suite_counts(workflow, []), Counter({'scripts/test-a.sh': 1, 'scripts/test-b.sh': 1}))

    def test_expands_duplicate_gate_and_detects_missing_suite(self):
        suites = ['scripts/test-a.sh', 'scripts/test-b.sh']
        workflow = '''jobs:
  linux:
    runs-on: ubuntu-latest
    steps:
      - run: bash scripts/test-a.sh
      - run: bash scripts/dev-task.sh gate
'''
        self.assertEqual(suite_counts(workflow, suites), Counter({'scripts/test-a.sh': 2, 'scripts/test-b.sh': 1}))
        missing = workflow.replace('      - run: bash scripts/dev-task.sh gate\n', '')
        self.assertNotEqual(suite_counts(missing, suites), Counter(suites))


if __name__ == '__main__':
    main()
