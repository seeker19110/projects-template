"""Regression tests: CLI validation, immutable Git lease, transactional upgrade.

All repositories are disposable, local-only fixtures. No AI CLI, credentials,
production files or network are used. Run: python3 tests/test_runtime_safety.py
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GIT = shutil.which("git")
BASH = shutil.which("bash")


def run(args, cwd=None, env=None, timeout=30):
    return subprocess.run(
        [str(arg) for arg in args], cwd=cwd, env=env,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, encoding="utf-8", errors="replace", timeout=timeout,
    )


def git(repo, *args):
    result = run([GIT, "-C", repo, *args])
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout.strip()


def init(repo):
    repo.mkdir(parents=True, exist_ok=True)
    git(repo, "init", "-q", "-b", "main")
    git(repo, "config", "user.name", "Safety fixture")
    git(repo, "config", "user.email", "safety@example.invalid")


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as stream:
        stream.write(content)


def commit(repo, message="test: fixture"):
    git(repo, "add", "--all")
    git(repo, "commit", "-qm", message)


class RuntimeSafety(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="framework safety ")
        self.addCleanup(self.temp.cleanup)
        self.tmp = Path(self.temp.name)
        self.env = os.environ.copy()
        for key in ("CLAUDE_PROJECT_DIR", "GITHUB_TOKEN", "GH_TOKEN", "GIT_DIR", "GIT_WORK_TREE"):
            self.env.pop(key, None)
        self.env.update(GIT_CONFIG_NOSYSTEM="1", GIT_TERMINAL_PROMPT="0")

    def test_missing_cli_values_are_rejected_before_side_effects(self):
        flags = {
            "maintain-cron.sh": ("--base", "--lock-dir", "--gh-token", "--gh-token-file", "--repo", "--harness", "--model", "--provider", "--mode"),
            "maintain-run.sh": ("--harness", "--model", "--provider", "--mode", "--prompt-out"),
            "maintenance-sweep.sh": ("--out",),
        }
        for script, options in flags.items():
            for option in options:
                for value in ([], [""], ["--help"]):
                    with self.subTest(script=script, option=option, value=value):
                        # File-backed stderr bounds memory if the old parser spins.
                        with tempfile.TemporaryFile(mode="w+", encoding="utf-8") as err:
                            try:
                                result = subprocess.run(
                                    [BASH, (ROOT / "scripts" / script).as_posix(), option, *value],
                                    cwd=self.tmp, env={**self.env, "CLAUDE_PROJECT_DIR": self.tmp.as_posix()}, stdout=subprocess.DEVNULL,
                                    stderr=err, timeout=2,
                                )
                            except subprocess.TimeoutExpired:
                                self.fail("CLI hung instead of rejecting a missing value")
                            err.seek(0)
                            message = err.read(4096)
                        self.assertEqual(result.returncode, 2, message)
                        self.assertIn("thiếu giá trị", message)

    def cron_fixture(self):
        seed = self.tmp / "seed"
        init(seed)
        shutil.copytree(ROOT / "scripts", seed / "scripts")
        write(seed / "scripts/maintenance-sweep.sh", "#!/usr/bin/env bash\nexit 0\n")
        write(seed / "scripts/maintain-run.sh", '''#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/ops
printf 'local report\\n' > docs/ops/MAINTENANCE-REPORT.md
if [ -n "${SAFETY_OTHER:-}" ]; then
  printf 'concurrent report\\n' > "$SAFETY_OTHER/docs/ops/MAINTENANCE-REPORT.md"
  git -C "$SAFETY_OTHER" add docs/ops/MAINTENANCE-REPORT.md
  git -C "$SAFETY_OTHER" commit -qm 'test: concurrent report'
  git -C "$SAFETY_OTHER" push -q origin HEAD
  if [ "${SAFETY_FETCH:-0}" = 1 ]; then git fetch -q origin "$SAFETY_BRANCH"; fi
fi
if [ "${SAFETY_UNEXPECTED:-0}" = 1 ]; then
  printf 'unapproved source\\n' > unexpected.txt
  git add unexpected.txt
fi
''')
        write(seed / "docs/ops/MAINTENANCE-REPORT.md", "baseline report\n")
        commit(seed)
        remote = self.tmp / "remote.git"
        result = run([GIT, "clone", "--bare", seed, remote])
        self.assertEqual(result.returncode, 0, result.stderr)
        checkout = self.tmp / "checkout"
        result = run([GIT, "clone", remote, checkout])
        self.assertEqual(result.returncode, 0, result.stderr)
        git(checkout, "config", "user.name", "Safety fixture")
        git(checkout, "config", "user.email", "safety@example.invalid")
        branch = "maint/auto-" + run(["date", "-u", "+%Y-%m-%d"]).stdout.strip()
        git(checkout, "push", "-q", "origin", f"HEAD:refs/heads/{branch}")
        other = self.tmp / "other"
        result = run([GIT, "clone", "-b", branch, remote, other])
        self.assertEqual(result.returncode, 0, result.stderr)
        git(other, "config", "user.name", "Concurrent fixture")
        git(other, "config", "user.email", "concurrent@example.invalid")
        return checkout, remote, other, branch

    def cron(self, checkout, **overrides):
        env = {**self.env, "CLAUDE_PROJECT_DIR": checkout.as_posix(), **overrides}
        return run([BASH, (checkout / "scripts/maintain-cron.sh").as_posix(), "--no-open-pr"],
                   cwd=checkout, env=env, timeout=30)

    def test_concurrent_report_is_not_overwritten_by_retry(self):
        checkout, remote, other, branch = self.cron_fixture()
        result = self.cron(checkout, SAFETY_OTHER=other.as_posix(), SAFETY_BRANCH=branch)
        self.assertEqual(result.returncode, 8, result.stderr)
        self.assertEqual(git(remote, "rev-parse", branch), git(other, "rev-parse", "HEAD"))
        self.assertEqual(git(remote, "show", f"{branch}:docs/ops/MAINTENANCE-REPORT.md"), "concurrent report")

    def test_background_fetch_cannot_refresh_the_expected_lease(self):
        checkout, remote, other, branch = self.cron_fixture()
        result = self.cron(checkout, SAFETY_OTHER=other.as_posix(), SAFETY_BRANCH=branch, SAFETY_FETCH="1")
        self.assertEqual(result.returncode, 8, result.stderr)
        self.assertEqual(git(remote, "rev-parse", branch), git(other, "rev-parse", "HEAD"))

    def test_report_only_publish_rejects_unexpected_staged_files(self):
        checkout, remote, _, branch = self.cron_fixture()
        previous = git(remote, "rev-parse", branch)
        result = self.cron(checkout, SAFETY_UNEXPECTED="1")
        self.assertEqual(result.returncode, 9, result.stderr)
        self.assertEqual(git(remote, "rev-parse", branch), previous)
        self.assertTrue((checkout / "unexpected.txt").exists())

    def test_clean_local_base_commits_are_not_discarded(self):
        checkout, remote, _, _ = self.cron_fixture()
        write(checkout / "local-only.txt", "unpublished work\n")
        commit(checkout, "test: local unpublished commit")
        before = git(checkout, "rev-parse", "HEAD")
        result = self.cron(checkout)
        self.assertEqual(result.returncode, 6, result.stderr)
        self.assertEqual(git(checkout, "rev-parse", "main"), before)
        self.assertNotEqual(before, git(remote, "rev-parse", "main"))

    def test_normal_report_can_be_published(self):
        checkout, remote, _, branch = self.cron_fixture()
        result = self.cron(checkout)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(git(remote, "show", f"{branch}:docs/ops/MAINTENANCE-REPORT.md"), "local report")

    def upgrade_fixture(self):
        source = self.tmp / "source"
        init(source)
        shutil.copy2(ROOT / "copy-framework.sh", source / "copy-framework.sh")
        for name in ("docs/framework", "docs/ops", ".claude/commands"):
            (source / name).mkdir(parents=True, exist_ok=True)
        write(source / "docs/framework/guide.md", "one\ntwo\nthree\nfour\nfive\n")
        write(source / "VERSION", "1.0.0\n")
        write(source / "PROGRESS.template.md", "# Progress\n")
        write(source / ".claude/settings-shared-default.json", "{}\n")
        commit(source)
        target = self.tmp / "target"
        init(target)
        result = run([BASH, (source / "copy-framework.sh").as_posix(), target.as_posix()], env=self.env)
        self.assertEqual(result.returncode, 0, result.stderr)
        return source, target

    def upgrade(self, source, target, env=None):
        return run([BASH, (source / "copy-framework.sh").as_posix(), target.as_posix(), "--upgrade"], env=env or self.env)

    @unittest.skipUnless((ROOT / "copy-framework.sh").is_file(), "copy upgrade is tested only in the template source repository")
    def test_fatal_merge_keeps_destination_and_previous_manifest(self):
        source, target = self.upgrade_fixture()
        guide = target / "docs/framework/guide.md"
        stamp = target / "docs/framework/FRAMEWORK-VERSION"
        write(guide, "local user work\n")
        original, manifest = guide.read_bytes(), stamp.read_bytes()
        write(source / "docs/framework/guide.md", "new upstream work\n")
        commit(source, "test: upstream upgrade")
        bindir = self.tmp / "bin"
        wrapper = bindir / "git"
        write(wrapper, '#!/usr/bin/env bash\nif [ "$1" = merge-file ]; then\n  printf "partial corrupt output\\n" > "${@: -3:1}"\n  exit 255\nfi\nexec "' + Path(GIT).as_posix() + '" "$@"\n')
        wrapper.chmod(0o755)
        result = self.upgrade(source, target, {**self.env, "PATH": str(bindir) + os.pathsep + self.env["PATH"]})
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertEqual(guide.read_bytes(), original)
        self.assertEqual(stamp.read_bytes(), manifest)
        self.assertEqual(Path(str(guide) + ".framework-new").read_text(), "new upstream work\n")
        self.assertFalse(list(guide.parent.glob("*.framework-merge.*")))

    @unittest.skipUnless((ROOT / "copy-framework.sh").is_file(), "copy upgrade is tested only in the template source repository")
    def test_conflict_is_not_applied_or_marked_as_a_completed_upgrade(self):
        source, target = self.upgrade_fixture()
        guide = target / "docs/framework/guide.md"
        stamp = target / "docs/framework/FRAMEWORK-VERSION"
        write(guide, "local\ntwo\nthree\nfour\nfive\n")
        original, manifest = guide.read_bytes(), stamp.read_bytes()
        write(source / "docs/framework/guide.md", "upstream\ntwo\nthree\nfour\nfive\n")
        commit(source)
        result = self.upgrade(source, target)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(guide.read_bytes(), original)
        self.assertEqual(stamp.read_bytes(), manifest)
        self.assertIn("<<<<<<<", Path(str(guide) + ".framework-conflict").read_text())

    @unittest.skipUnless((ROOT / "copy-framework.sh").is_file(), "copy upgrade is tested only in the template source repository")
    def test_clean_three_way_merge_preserves_both_changes(self):
        source, target = self.upgrade_fixture()
        guide = target / "docs/framework/guide.md"
        write(guide, "local\ntwo\nthree\nfour\nfive\n")
        write(source / "docs/framework/guide.md", "one\ntwo\nthree\nfour\nupstream\n")
        commit(source)
        result = self.upgrade(source, target)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(guide.read_text(), "local\ntwo\nthree\nfour\nupstream\n")


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(RuntimeSafety)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(2 if result.errors else (0 if result.wasSuccessful() else 1))
