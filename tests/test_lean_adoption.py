"""LD-08: copied Node/Python fixtures exercise gate evidence through upgrade.

These are local runtime fixtures, never hosted CI, a product pilot or a model benchmark.
"""
import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
from unittest import TestCase, main

ROOT = Path(__file__).resolve().parents[1]
PROTOCOL = ROOT / 'docs/framework/lean-delivery-benchmark.md'


def run(*args, cwd, expected=0):
    env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
    env.pop('CLAUDE_PROJECT_DIR', None)
    result = subprocess.run(args, cwd=cwd, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    if result.returncode != expected:
        raise AssertionError(f'{args}: expected {expected}, got {result.returncode}\n{result.stdout}')
    return result.stdout


class LeanAdoption(TestCase):
    def test_copied_runtime_evidence_survives_upgrade_and_rejects_stale_work(self):
        for stack in ('node', 'python'):
            with self.subTest(stack=stack), TemporaryDirectory() as scratch:
                target = Path(scratch) / stack
                target.mkdir()
                run('git', 'init', '-q', cwd=target)
                run('bash', str(ROOT / 'copy-framework.sh'), str(target), cwd=ROOT)
                (target / '.gitignore').write_text('out/\n__pycache__/\n', encoding='utf-8')
                (target / 'out').mkdir()
                if stack == 'node':
                    source, good, bad = 'sum.cjs', 'module.exports = (a, b) => a + b;\n', 'module.exports = (a, b) => a - b;\n'
                    (target / 'test.cjs').write_text("const {test} = require('node:test');\nconst assert = require('node:assert/strict');\ntest('adds', () => assert.equal(require('./sum.cjs')(2, 3), 5));\n", encoding='utf-8')
                    config = "gate_tools='node'\nbuild='node --check sum.cjs'\nlint='node --check test.cjs'\ntest='node --test --test-reporter=tap test.cjs'\ngate_test_count_regex='^# tests ([0-9]+)'\n"
                else:
                    source, good, bad = 'calc.py', 'def add(a, b):\n    return a + b\n', 'def add(a, b):\n    return a - b\n'
                    (target / 'test_calc.py').write_text('from unittest import TestCase\nfrom calc import add\nclass Calc(TestCase):\n    def test_add(self):\n        self.assertEqual(add(2, 3), 5)\n', encoding='utf-8')
                    config = "gate_tools='python3'\nbuild='python3 -m py_compile calc.py test_calc.py'\nlint='python3 -m tabnanny calc.py test_calc.py'\ntest='python3 -m unittest -q test_calc'\ngate_test_count_regex='Ran ([0-9]+) tests?'\n"
                config += "gate_skip_typecheck_reason='Dynamic runtime fixture; behavior covered by a real runtime test.'\n"
                commands = target / '.claude/project-commands.sh'
                commands.write_text(config, encoding='utf-8')
                (target / source).write_text(good, encoding='utf-8')
                quickstart = target / 'docs/framework/quickstart.md'
                quickstart.write_text(quickstart.read_text(encoding='utf-8') + '\nLOCAL-ADOPTION-NOTE\n', encoding='utf-8')
                run('git', 'add', '-A', cwd=target)
                run('git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'test: adoption baseline', cwd=target)
                evidence = target / 'out/gate.json'
                run('bash', 'scripts/dev-task.sh', 'gate', '--evidence', str(evidence), cwd=target)
                data = json.loads(evidence.read_text(encoding='utf-8'))
                self.assertEqual((data['status'], data['test_cases']), ('PASS', 1))
                self.assertIn('VERIFIED:', run('bash', 'scripts/dev-task.sh', 'evidence-check', str(evidence), cwd=target))
                # Upgrade must retain project-specific commands and documentation.
                run('bash', str(ROOT / 'copy-framework.sh'), str(target), '--upgrade', cwd=ROOT)
                self.assertEqual(commands.read_text(encoding='utf-8'), config)
                self.assertIn('LOCAL-ADOPTION-NOTE', quickstart.read_text(encoding='utf-8'))
                run('bash', 'scripts/dev-task.sh', 'gate', '--evidence', str(evidence), cwd=target)
                self.assertIn('VERIFIED:', run('bash', 'scripts/dev-task.sh', 'evidence-check', str(evidence), cwd=target))
                (target / source).write_text(bad, encoding='utf-8')
                self.assertIn('STALE:', run('bash', 'scripts/dev-task.sh', 'evidence-check', str(evidence), cwd=target, expected=1))
                # Remove timestamp-sensitive Python bytecode before testing changed source.
                if stack == 'python':
                    for bytecode in (target / '__pycache__').glob('*.pyc'):
                        bytecode.unlink()
                run('bash', 'scripts/dev-task.sh', 'gate', '--evidence', str(evidence), cwd=target, expected=1)
                self.assertEqual(json.loads(evidence.read_text(encoding='utf-8'))['status'], 'FAIL')
                self.assertIn('REJECTED:', run('bash', 'scripts/dev-task.sh', 'evidence-check', str(evidence), cwd=target, expected=1))

    def test_protocol_is_explicit_about_scope_and_unknown_metrics(self):
        text = PROTOCOL.read_text(encoding='utf-8')
        for requirement in ('fixture', 'hosted CI', 'pilot', 'unknown', 'e2b70bf',
                            'S/M/L', 'token', 'retry', 'reject', 'latency', 'rollback'):
            self.assertIn(requirement, text)
        self.assertIn('tests/test_lean_adoption.py', (ROOT / '.claude/project-commands.sh').read_text(encoding='utf-8'))
        self.assertIn('python3 tests/test_lean_adoption.py', (ROOT / '.github/workflows/ci.yml').read_text(encoding='utf-8'))


if __name__ == '__main__':
    main()
