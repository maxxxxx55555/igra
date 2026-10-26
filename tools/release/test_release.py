"""Fault tests: the real PowerShell bootstrap against disposable real Git remotes."""
import base64
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pipeline import configure_profile, import_configuration, judge, verified_profile, reset_profile  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


class JudgeTests(unittest.TestCase):
    def test_first_import_restores_the_original_theme_even_after_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            data = b'[gui]\r\ntheme/custom="res://assets/ui/theme_tls.tres"\r\n'
            (project / "project.godot").write_bytes(data)
            with self.assertRaises(RuntimeError):
                with import_configuration(project):
                    self.assertIn('theme/custom=""', (project / "project.godot").read_text())
                    raise RuntimeError("import failed")
            self.assertEqual((project / "project.godot").read_bytes(), data)

    def test_incomplete_zero_exit_fails(self):
        with self.assertRaises(RuntimeError):
            judge("started", 0, r"DONE fails=0")

    def test_real_errors_fail_even_after_done(self):
        with self.assertRaises(RuntimeError):
            judge("SCRIPT ERROR: bad\nDONE fails=0", 0, "DONE fails=0", True)
        with self.assertRaises(RuntimeError):
            judge("ERROR: Missing resource\nDONE fails=0", 0, "DONE fails=0", True)

    def test_only_exact_dummy_backend_diagnostic_is_classified(self):
        with self.assertRaises(RuntimeError):
            judge('ERROR: Parameter "material" is null.\nDONE fails=0', 0, "DONE fails=0", True)
        output = 'DONE fails=0\nERROR: Parameter "material" is null.\n   at: material_get_instance_shader_parameters (servers/rendering/dummy/storage/material_storage.cpp:264)\n'
        judge(output, 0, "DONE fails=0", True)

    def test_failure_exit_and_missing_marker(self):
        with self.assertRaises(RuntimeError):
            judge("DONE fails=0", 124, "DONE fails=0")
        judge("DONE fails=0\nERROR: 22 resources still in use at exit", 0, "DONE fails=0", True)

    def test_profile_refuses_owner_path(self):
        with self.assertRaises(RuntimeError):
            verified_profile('[release-profile] {"name":"Last Streetlight","path":"/tmp/Last Streetlight"}', "Last Streetlight")
        with self.assertRaises(RuntimeError):
            reset_profile(Path("/tmp/Last Streetlight"), "Last Streetlight")

    def test_profile_configuration_and_roundtrip(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "project.godot").write_text('[application]\nconfig/name="Last Streetlight"\n', encoding="utf-8")
            name = "__TLS_QA_" + "a" * 32
            configure_profile(project, name)
            self.assertIn('config/use_custom_user_dir=true', (project / "project.godot").read_text())
            path = project / name
            path.mkdir()
            output = "[release-profile] " + json.dumps({"name": name, "path": str(path)})
            self.assertEqual(verified_profile(output, name), path)
            reset_profile(path, name)
            self.assertFalse(path.exists())


@unittest.skipUnless(os.environ.get("IGRA_TEST_PWSH"), "Set IGRA_TEST_PWSH to a real PowerShell executable/wrapper")
class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="igra-bootstrap-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.real_git = shutil.which("git")
        self.remote = self.root / "remote.git"
        self.source = self.root / "origin"
        self.git("init", "--bare", str(self.remote))
        self.git("init", "-b", "main", str(self.source))
        self.git("-C", str(self.source), "config", "user.email", "release-test@example.invalid")
        self.git("-C", str(self.source), "config", "user.name", "Release fixture")
        (self.source / "game.txt").write_text("baseline\n")
        self.git("-C", str(self.source), "add", ".")
        self.git("-C", str(self.source), "commit", "-m", "fixture base")
        self.base = self.git("-C", str(self.source), "rev-parse", "HEAD")
        self.git("-C", str(self.source), "push", str(self.remote), "main")
        self.git("--git-dir", str(self.remote), "symbolic-ref", "HEAD", "refs/heads/main")
        self.git("-C", str(self.source), "checkout", "-b", "release-payload")
        (self.source / "game.txt").write_text("real game fixes\n")
        self.git("-C", str(self.source), "commit", "-am", "fixture source improvements")
        self.head = self.git("-C", str(self.source), "rev-parse", "HEAD")
        bundle = self.root / "source.bundle"
        self.git("-C", str(self.source), "bundle", "create", str(bundle), "release-payload", "^" + self.base)
        data = bundle.read_bytes()
        text = (ROOT / "tools/release/MegaRelease.ps1.in").read_text(encoding="utf-8")
        text = text.replace("a4b1943d1d6fbcee4eeffeff795b0a959fdb8dea", self.base)
        self.text = text.replace("@@HEAD@@", self.head).replace("@@SHA256@@", hashlib.sha256(data).hexdigest()).replace("@@BUNDLE@@", base64.b64encode(data).decode())
        self.bin = self.root / "bin"
        self.bin.mkdir()
        # Both wrappers route only this fixture. Auth is simulated; Git transport,
        # bundle verification, checkout, lease protection and remote verification are real.
        git_wrapper = f'''#!{sys.executable}
import os,subprocess,sys
args=[a.replace('https://github.com/fixture/igra.git',{'file://' + str(self.remote)!r}).replace('https://github.com/maxxxxx55555/igra.git',{str(self.source)!r}) for a in sys.argv[1:]]
if os.environ.get('FIXTURE_RACE')=='1' and 'push' in args:
 subprocess.run([{self.real_git!r},'--git-dir',{str(self.remote)!r},'update-ref','refs/heads/release/test',{self.base!r}],check=True)
if os.environ.get('FIXTURE_VERIFY_FAIL')=='1' and 'ls-remote' in args and 'origin' in args: sys.exit(0)
os.execv({self.real_git!r},[{self.real_git!r},*args])
'''
        gh_wrapper = f'''#!{sys.executable}
import json,os,sys,pathlib
args=sys.argv[1:]
path=pathlib.Path({str(self.root / 'auth')!r})
if args[:2]==['auth','status']: sys.exit(0 if path.exists() else 1)
if args[:2]==['auth','login']: path.write_text('browser auth'); print('fixture browser authorization'); sys.exit(0)
if args[:2]==['repo','view']: print(json.dumps({{'viewerPermission':os.environ.get('FIXTURE_PERMISSION','ADMIN'),'isArchived':False}})); sys.exit(0)
sys.exit(19)
'''
        for name, code in (("git", git_wrapper), ("gh", gh_wrapper)):
            path = self.bin / name
            path.write_text(code)
            path.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"])

    def git(self, *args):
        return subprocess.check_output([self.real_git, *args], stderr=subprocess.STDOUT, text=True).strip()

    def run_script(self, branch="release/test", text=None, **env):
        script = self.root / "fixture.ps1"
        script.write_text(text or self.text, encoding="utf-8-sig")
        if os.name != "nt":
            runner = Path(os.environ["IGRA_TEST_PWSH"])
            runner.chmod(runner.stat().st_mode | 0o100)
        result = subprocess.run([os.environ["IGRA_TEST_PWSH"], "-NoLogo", "-NoProfile", "-File", str(script),
                                 "-Repository", "fixture/igra", "-Branch", branch, "-WorkRoot", str(self.root / "work"), "-SourceOnly"],
                                env=dict(self.env, **env), capture_output=True, text=True, timeout=120)
        return result

    def test_browser_auth_and_verified_remote_source(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("SOURCE_SAVED", result.stdout)
        self.assertTrue((self.root / "auth").exists())
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "refs/heads/release/test"), self.head)
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "refs/heads/main"), self.base)
        self.assertEqual(self.git("--git-dir", str(self.remote), "show", "release/test:game.txt"), "real game fixes")

    def test_inherited_git_worktree_cannot_redirect_the_checkout(self):
        result = self.run_script(GIT_DIR=str(self.source / ".git"), GIT_WORK_TREE=str(self.source))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git("-C", str(self.source), "branch", "--show-current"), "release-payload")
        self.assertEqual((self.source / "game.txt").read_text(), "real game fixes\n")

    def test_main_and_read_only_are_rejected(self):
        result = self.run_script(branch="main")
        self.assertNotEqual(result.returncode, 0)
        result = self.run_script(FIXTURE_PERMISSION="READ")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("--git-dir", str(self.remote), "for-each-ref", "--format=%(refname)", "refs/heads/release/"), "")

    def test_another_repository_fetches_public_bundle_prerequisite(self):
        self.git("-C", str(self.source), "checkout", "--orphan", "unrelated")
        (self.source / "game.txt").write_text("a different repository\n")
        self.git("-C", str(self.source), "add", ".")
        self.git("-C", str(self.source), "commit", "-m", "unrelated target")
        unrelated = self.git("-C", str(self.source), "rev-parse", "HEAD")
        self.git("-C", str(self.source), "push", "--force", str(self.remote), "HEAD:main")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "main"), unrelated)
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "release/test"), self.head)

    def test_corrupt_bundle_and_existing_branch_are_rejected(self):
        result = self.run_script(text=self.text.replace("$script:BundleHash = '", "$script:BundleHash = '0"))
        self.assertNotEqual(result.returncode, 0)
        self.git("--git-dir", str(self.remote), "update-ref", "refs/heads/release/test", self.base)
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "refs/heads/release/test"), self.base)

    def test_race_does_not_overwrite_a_branch(self):
        result = self.run_script(FIXTURE_RACE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "refs/heads/release/test"), self.base)

    def test_unverified_push_is_not_reported_saved(self):
        result = self.run_script(FIXTURE_VERIFY_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("SOURCE_SAVED:", result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
