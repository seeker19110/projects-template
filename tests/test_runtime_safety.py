"""Regression tests: shell paths, PR policy and CLI validation.

All repositories are disposable, local-only fixtures. No AI CLI, credentials,
production files or network are used. Run: python3 tests/test_runtime_safety.py
"""
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import sys
import textwrap
import unittest

from _runtime_fixture import RuntimeFixture, ROOT, BASH, run, write


class RuntimeSafety(RuntimeFixture):
    def pr_policy(self, pr, others):
        workflow = (ROOT / ".github/workflows/pr-policy.yml").read_text(encoding="utf-8")
        _, marker, script = workflow.partition("          script: |\n")
        self.assertTrue(marker, "Workflow must expose the actual github-script body")
        fixture = self.tmp / "pr-policy.json"
        write(fixture, json.dumps({"script": textwrap.dedent(script), "pr": pr,
                                  "open": [pr, *others]}, ensure_ascii=False))
        runner = self.tmp / "pr-policy.cjs"
        write(runner, '''const fs = require("node:fs");
const input = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const failures = [], calls = [];
const context = {payload: {pull_request: input.pr}, repo: {owner: "fixture", repo: "local"}};
const core = {setFailed: text => failures.push(text), info() {}, warning() {}};
const github = {
  rest: {pulls: {list: "list", listCommits: "commits", listFiles: "files"}},
  async paginate(route, args) {
    calls.push(route);
    if (route === "list" && args.state === "open") return input.open;
    if (route === "commits") return [{commit: {message: "chore: fixture"}}];
    if (route === "files") return [{filename: "TRAPS.md"}];
    throw new Error(`Unexpected fixture API request: ${route}`);
  }
};
const AsyncFunction = Object.getPrototypeOf(async function() {}).constructor;
new AsyncFunction("context", "core", "github", input.script)(context, core, github)
  .then(() => process.stdout.write(JSON.stringify({failures, calls})))
  .catch(error => { process.stderr.write(String(error)); process.exitCode = 1; });
''')
        result = run(["node", runner, fixture], env=self.env)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_pr_policy_wip_counts_every_open_pr_before_metadata_exemptions(self):
        body = "\n".join(("## Summary", "## Issue / Goal", "## Research / Spec",
                          "## Validation", "## Risk, rollout and rollback", "## Definition of Done"))
        regular = {"number": 1, "draft": False, "user": {"login": "human"},
                   "title": "fix: fixture", "body": body}
        cases = [
            ("three regular", {}, 2, False, []),
            ("four regular", {}, 3, False, ["Trần WIP"]),
            ("three including other drafts", {}, 2, True, []),
            ("four including other drafts", {}, 3, True, ["Trần WIP"]),
            ("ordinary missing body", {"body": ""}, 2, False, ["Missing PR sections"]),
            ("ordinary unapproved feature", {"title": "feat: fixture"}, 2, False,
             ["Feature PR must link", "Feature spec must be Approved"]),
        ]
        exemptions = [("draft", {"draft": True})]
        exemptions.extend((bot, {"user": {"login": bot}})
                          for bot in ("dependabot[bot]", "renovate[bot]", "github-actions[bot]"))
        for actor, fields in exemptions:
            fields = {**fields, "title": "feat: fixture", "body": ""}
            cases.extend((
                (f"{actor} under cap retains exemptions", fields, 2, True, []),
                (f"{actor} over cap", fields, 3, True, ["Trần WIP"]),
                (f"{actor} invalid title", {**fields, "title": "invalid"}, 2, True,
                 ["PR title must follow Conventional Commits"]),
            ))
        for label, fields, count, draft, expected in cases:
            with self.subTest(case=label):
                others = [{"number": index + 2, "draft": draft,
                           "user": {"login": "another-author"}} for index in range(count)]
                output = self.pr_policy({**regular, **fields}, others)
                self.assertEqual(len(output["failures"]), len(expected), output)
                for fragment, failure in zip(expected, output["failures"]):
                    self.assertIn(fragment, failure)
                self.assertEqual(output["calls"].count("list"), 1, output)

    def formatter_fixture(self, tool=None, template=None, tool_exit=0, root=None):
        root = root or self.tmp / (tool or "no-formatter")
        root.mkdir(parents=True, exist_ok=True)
        bindir = root / "fixture-bin"
        bindir.mkdir()
        # Isolate detection from tools installed on the host. Bash resolves the
        # fixture bin path itself so this also works with Git Bash on Windows.
        for name in ("bash", "dirname", "touch"):
            executable = run([BASH, "-c", f"command -v {name}"]).stdout.strip()
            self.assertTrue(executable, f"Fixture requires {name}")
            wrapper = bindir / name
            write(wrapper, f'#!/bin/bash\nexec {shlex.quote(executable)} "$@"\n')
            wrapper.chmod(0o755)
        if tool:
            wrapper = bindir / tool
            write(wrapper, '#!/bin/bash\nprintf "%s\\0" "$@" > "$FORMAT_ARGS"\n'
                  f"exit {tool_exit}\n")
            wrapper.chmod(0o755)
        if tool == "npx":
            write(root / "package.json", "{}\n")
        if template:
            write(root / ".claude/project-commands.sh",
                  "export format_file=" + shlex.quote(template) + "\n")
        env = {**self.env, "CLAUDE_PROJECT_DIR": root.as_posix(),
               "FORMAT_ARGS": (root / "formatter-args").as_posix()}
        return root, bindir, env

    def run_formatter(self, fixture, *args):
        root, bindir, env = fixture
        for name in ("formatter-args", "format-sentinel", "trusted-sentinel", "venv-sentinel", "venv-backtick"):
            (root / name).unlink(missing_ok=True)
        return run([BASH, "-c", 'export PATH="$(cd "$1" && pwd)"; exec "$2" "$3" "${@:4}"',
                    "bash", bindir.as_posix(), Path(BASH).as_posix(),
                    (ROOT / "scripts/dev-task.sh").as_posix(), *args], cwd=root, env=env)

    def formatter_args(self, root):
        output = root / "formatter-args"
        self.assertTrue(output.exists(), "Formatter was not invoked")
        return output.read_bytes().decode("utf-8").split("\0")[:-1]

    def test_format_file_builtin_preserves_literal_filename(self):
        tools = {
            "npx": ("md", ["--no-install", "prettier", "--write"]),
            "ruff": ("py", ["format"]), "black": ("py", []),
            "gofmt": ("go", ["-w"]), "rustfmt": ("rs", []),
        }
        names = ("space name", "double\"quote", "single'quote", "$HOME",
                 "$(touch format-sentinel)", "`touch format-sentinel`",
                 "semi; touch format-sentinel;", "line\nbreak")
        for tool, (ext, prefix) in tools.items():
            fixture = self.formatter_fixture(tool)
            root = fixture[0]
            for name in names:
                with self.subTest(tool=tool, name=name):
                    filename = (root / f"{name}.{ext}").as_posix()
                    result = self.run_formatter(fixture, "format-file", filename)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertFalse((root / "format-sentinel").exists(), result.stderr)
                    self.assertEqual(self.formatter_args(root), [*prefix, filename])

    def test_format_file_trusted_template_preserves_literal_filename(self):
        for index, placeholder in enumerate(("{}", '"{}"', "'{}'")):
            with self.subTest(placeholder=placeholder):
                root = self.tmp / f"template-{index}"
                fixture = self.formatter_fixture("customfmt", "customfmt " + placeholder, root=root)
                filename = (root / 'space "quote\' $(touch format-sentinel) `touch format-sentinel`;\n.md').as_posix()
                result = self.run_formatter(fixture, "format-file", filename)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse((root / "format-sentinel").exists(), result.stderr)
                self.assertEqual(self.formatter_args(root), [filename])

    def test_format_file_retains_trusted_shell_operations(self):
        fixture = self.formatter_fixture("customfmt", "customfmt {} {} && touch trusted-sentinel")
        root = fixture[0]
        filename = (root / "$(touch format-sentinel).md").as_posix()
        result = self.run_formatter(fixture, "format-file", filename)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((root / "format-sentinel").exists(), result.stderr)
        self.assertTrue((root / "trusted-sentinel").exists(), result.stderr)
        self.assertEqual(self.formatter_args(root), [filename, filename])

    def test_format_file_leading_dash_is_a_filename(self):
        fixture = self.formatter_fixture("npx")
        result = self.run_formatter(fixture, "format-file", "--flag.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.formatter_args(fixture[0]),
                         ["--no-install", "prettier", "--write", "./--flag.md"])

    def test_format_file_remains_best_effort(self):
        fixture = self.formatter_fixture()
        for args in (("format-file",), ("format-file", "file.py"), ("format-file", "file.unknown")):
            with self.subTest(args=args):
                result = self.run_formatter(fixture, *args)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse((fixture[0] / "formatter-args").exists())
        failing = self.formatter_fixture("npx", tool_exit=7)
        result = self.run_formatter(failing, "format-file", "file.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.formatter_args(failing[0]),
                         ["--no-install", "prettier", "--write", "file.md"])

    def test_python_venv_executable_path_is_shell_escaped(self):
        root = self.tmp / "venv $(touch venv-sentinel) `touch venv-backtick` 'quoted' ;"
        fixture = self.formatter_fixture(root=root)
        write(root / "requirements.txt", "")
        tool = root / ".venv/bin/ruff"
        write(tool, '#!/bin/bash\nprintf "%s\\0" "$@" > "$FORMAT_ARGS"\n')
        tool.chmod(0o755)
        result = self.run_formatter(fixture, "lint")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((root / "venv-sentinel").exists(), result.stderr)
        self.assertFalse((root / "venv-backtick").exists(), result.stderr)
        self.assertEqual(self.formatter_args(root), ["check", "."])

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


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(RuntimeSafety)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(2 if result.errors else (0 if result.wasSuccessful() else 1))
