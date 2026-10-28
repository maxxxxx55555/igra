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
from types import SimpleNamespace
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pipeline import Pipeline, configure_profile, import_configuration, judge, verified_profile, reset_profile  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/qa_sim"))
import aab_check  # noqa: E402


class JudgeTests(unittest.TestCase):
    def test_full_battery_runs_twice_and_keeps_failed_pass_logs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pipeline = object.__new__(Pipeline)
            pipeline.args = SimpleNamespace(bash="bash")
            pipeline.source = root / "source"
            pipeline.qa = root / "qa"
            pipeline.out = root / "output"
            pipeline.env = {"GODOT": "godot"}
            pipeline.profile_name = "__TLS_QA_" + "c" * 32
            pipeline.profile = root / pipeline.profile_name
            logs = pipeline.qa / ".qa_logs"
            logs.mkdir(parents=True)
            (logs / "engine.log").write_text("full diagnostic")
            pipeline.command = Mock()
            with patch("pipeline.subprocess.check_output", return_value="/fixture/git"):
                pipeline.full_battery()
                self.assertEqual(pipeline.command.call_count, 2)
                for call in pipeline.command.call_args_list:
                    self.assertEqual(call.args[1], ["bash", "tools/check.sh", "--all"])
                    self.assertEqual(call.kwargs["env"]["GIT_WORK_TREE"], pipeline.qa.as_posix())
                pipeline.command = Mock(side_effect=RuntimeError("gate failed"))
                with self.assertRaisesRegex(RuntimeError, "gate failed"):
                    pipeline.full_battery()
                self.assertEqual(pipeline.command.call_count, 1)
            self.assertEqual((pipeline.out / "logs/full_battery_1/engine.log").read_text(), "full diagnostic")

    def test_verify_only_never_exports_and_archives_its_checks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pipeline = object.__new__(Pipeline)
            pipeline.args = SimpleNamespace(allow_dirty=False, full_release=False, verify_only=True, bash="bash")
            pipeline.source = root / "source"
            pipeline.out = root / "output"
            pipeline.qa = root / "qa"
            (pipeline.out / "logs").mkdir(parents=True)
            (pipeline.out / "artifacts").mkdir()
            pipeline.report = {"checks": []}
            pipeline.env = {}
            pipeline.profile = None
            pipeline.profile_name = "__TLS_QA_" + "d" * 32
            for name in ("engine", "gate", "command", "save_report", "import_project", "export", "android"):
                setattr(pipeline, name, Mock(return_value="4.7.2.stable"))
            with patch("pipeline.subprocess.check_output", return_value=""), patch("pipeline.copy_project"), \
                    patch("pipeline.configure_profile"), patch("pipeline.verified_profile", return_value=root / pipeline.profile_name):
                pipeline.run()
            self.assertEqual(pipeline.report["state"], "GAME_CHECKS_PASSED_MANUAL_REVIEW_PENDING")
            pipeline.export.assert_not_called()
            pipeline.android.assert_not_called()
            self.assertTrue((pipeline.out / "artifacts/verification-logs.zip").is_file())
            self.assertTrue((pipeline.out / "artifacts/SHA256SUMS.txt").is_file())

    def test_android_requires_all_audits_and_propagates_failure(self):
        pipeline = object.__new__(Pipeline)
        pipeline.args = SimpleNamespace(bundletool="official.jar")
        pipeline.command = Mock()
        pipeline.audit_android(Path("release.aab"))
        calls = pipeline.command.call_args_list
        self.assertEqual(len(calls), 2)
        self.assertIn("--secrets", calls[0].args[1])
        self.assertEqual(calls[0].args[1][-2:], ["--bundletool", "official.jar"])
        self.assertEqual(calls[0].kwargs["marker"], r"aab_check: PASS\b")
        self.assertIn("tools/qa_sim/release_export_check.py", calls[1].args[1])
        for failure in (0, 1):
            pipeline.command.reset_mock(side_effect=True)
            pipeline.command.side_effect = [None] * failure + [RuntimeError("audit rejected")]
            with self.assertRaisesRegex(RuntimeError, "audit rejected"):
                pipeline.audit_android(Path("release.aab"))
            self.assertEqual(pipeline.command.call_count, failure + 1)

    def test_manifest_rejects_wrong_release_debug_and_missing_tool(self):
        expected = aab_check.release_identity()
        xml = ('<manifest xmlns:android="http://schemas.android.com/apk/res/android" '
               'package="{package}" android:versionCode="{versionCode}" '
               'android:versionName="{versionName}"><application /></manifest>').format(**expected)
        self.assertEqual(aab_check.manifest_identity(xml), expected)
        with tempfile.TemporaryDirectory() as directory:
            jar = Path(directory) / "bundletool.jar"
            jar.touch()
            with patch.object(aab_check, "tool", return_value=(0, xml)) as command:
                self.assertEqual(aab_check.manifest_check(Path("release.aab"), jar), 0)
                self.assertIn("--bundle=release.aab", command.call_args.args)
                self.assertTrue(command.call_args.kwargs["stdout_only"])
            invalid = [xml.replace(expected[key], "wrong", 1) for key in expected]
            invalid += ["<manifest", xml.replace("<application />", ""),
                        xml.replace("<application />", '<application android:debuggable="true" />')]
            for data in invalid:
                with patch.object(aab_check, "tool", return_value=(0, data)):
                    self.assertEqual(aab_check.manifest_check(Path("release.aab"), jar), 1)
            with patch.object(aab_check, "tool", return_value=(1, xml)):
                self.assertEqual(aab_check.manifest_check(Path("release.aab"), jar), 1)
            self.assertEqual(aab_check.manifest_check(Path("release.aab"), ""), 1)
        old, current = "11" * 32, "ab" * 32
        self.assertEqual(aab_check.recorded_signer(f"SHA-256 fingerprint `{old}`\nSHA-256 fingerprint `{current}`"), current)
        self.assertEqual(aab_check.recorded_signer("Old certificate " + old), "")

    def test_cold_import_requires_clean_retry_and_keeps_diagnostics(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            project = root / "qa"
            project.mkdir()
            (project / "project.godot").write_text('[gui]\ntheme/custom="theme"\n')
            (root / "default_bus_layout.tres").write_text("original buses")
            for code, retry_fails in ((0, False), (0, True), (124, False)):
                pipeline = object.__new__(Pipeline)
                pipeline.source = root
                pipeline.report = {"checks": []}
                pipeline.save_report = Mock()
                def run(name, *_args, **_kwargs):
                    item = {"name": name, "exit_code": code, "result": "FAIL", "error": "preload error"}
                    pipeline.report["checks"].append(item)
                    if name == "import" or retry_fails:
                        raise RuntimeError("preload error")
                    item.update(exit_code=0, result="PASS")
                pipeline.engine = Mock(side_effect=run)
                if code or retry_fails:
                    with self.assertRaises(RuntimeError):
                        pipeline.import_project(project, "import")
                    self.assertEqual(pipeline.report["checks"][0]["result"], "FAIL")
                else:
                    pipeline.import_project(project, "import")
                    self.assertEqual(pipeline.report["checks"][0]["result"], "RECOVERED_IMPORT")
                    self.assertEqual(pipeline.report["checks"][0]["error"], "preload error")
                    self.assertEqual((project / "default_bus_layout.tres").read_text(), "original buses")
                self.assertEqual(pipeline.engine.call_count, 1 if code else 2)
                self.assertIn('theme/custom="theme"', (project / "project.godot").read_text())

    def test_proof_preserves_a_large_output_tail_and_failure_exit(self):
        bash = shutil.which("bash")
        if not bash:
            self.skipTest("Bash is needed for the proof wrapper")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            self.assertEqual(subprocess.run(["git", "init", str(project)], capture_output=True).returncode, 0)
            script = project / "tools/qa_sim/proof_run"
            script.parent.mkdir(parents=True)
            shutil.copy2(ROOT / "tools/qa_sim/proof_run", script)
            child = 'import sys; print("x" * 800000); print("REQUIRED_DONE_MARKER"); sys.exit(7)'
            result = subprocess.run([bash, str(script), "burst", "--", sys.executable, "-c", child], capture_output=True)
            self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
            output = (project / ".qa_logs/proofs/burst.out").read_text()
            self.assertTrue(output.endswith("REQUIRED_DONE_MARKER\n# EXIT=7\n"))
            self.assertEqual(output.count("x" * 800000), 1)
            child = 'for n in 1 2 3; do "$1" -c "print(\'child-\' + \'$n\' + \'x\' * 200000)"; done; exit 9'
            result = subprocess.run([bash, str(script), "nested", "--", bash, "-c", child, "fixture", sys.executable], capture_output=True)
            self.assertEqual(result.returncode, 9, result.stdout + result.stderr)
            output = (project / ".qa_logs/proofs/nested.out").read_text()
            self.assertTrue(output.endswith("# EXIT=9\n"))
            for number in (1, 2, 3):
                self.assertEqual(output.count(f"child-{number}" + "x" * 200000), 1)

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
            text = (project / "project.godot").read_text()
            # false keeps the profile inside Godot/app_userdata, where the shell guard looks.
            self.assertIn('config/use_custom_user_dir=false', text)
            # The pre-existing release-profile gate asserts custom_user_dir_name == config/name;
            # Godot ignores the field while the flag is false, so it cannot move the directory.
            self.assertIn('config/custom_user_dir_name="%s"' % name, text)
            self.assertIn('config/name="%s"' % name, text)
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
        text = text.replace("@@HANDOFF@@", "Fixture handoff")
        text = text.replace("@@PLAY_CHECKLIST@@", "Fixture Play checklist")
        text = text.replace("bf563cc9353dd1fb3717943b416530e6a9e4fb2c", self.base)
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
