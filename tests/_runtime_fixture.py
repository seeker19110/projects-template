"""Shared fixture for the runtime regression suites (disposable local Git repos only)."""
import os
from pathlib import Path
import shutil
import subprocess
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


class RuntimeFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="framework safety ")
        self.addCleanup(self.temp.cleanup)
        self.tmp = Path(self.temp.name)
        self.env = os.environ.copy()
        for key in ("CLAUDE_PROJECT_DIR", "GITHUB_TOKEN", "GH_TOKEN", "GIT_DIR", "GIT_WORK_TREE"):
            self.env.pop(key, None)
        # Use the same Git config as clone/setup; changing core.autocrlf only
        # for the system under test makes a clean Windows fixture look dirty.
        self.env.update(GIT_TERMINAL_PROMPT="0")
