"""Check the game, export artifacts, record evidence. Never labels untested builds ready."""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time
import uuid
import zipfile

PREFIX = "__TLS_QA_"
FATAL = re.compile(r"(?m)^(?:SCRIPT ERROR:|ERROR: (?!\d+ resources still in use at exit|\d+ RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit\.)|.*(?:Parse Error:|Shader compilation failed))")
# Godot's dummy 3D backend queries material parameters on a null RID during
# mesh teardown. Require the exact backend stack; real-renderer errors stay fatal.
DUMMY_TEARDOWN = re.compile(r'(?m)^ERROR: Parameter "material" is null\.\r?\n\s+at: material_get_instance_shader_parameters \(servers/rendering/dummy/storage/material_storage\.cpp:264\)\r?\n?')
GATES = [
    ("compile", "compile_gate", r"COMPILE_GATE bad=0\b", 180),
    ("all_scripts", "compile", r"\[compile-all\] OK", 180),
    ("signals", "signal_arity_check", r"\[sig\] DONE fails=0\b", 120),
    ("api", "autoload_api_check", r"\[api\] DONE fails=0\b", 120),
    ("localization", "i18n_check", r"\[i18n\] fails=0\b", 120),
    ("assets", "asset_check", r"\[asset-check\] DONE fails=0\b", 120),
    ("world", "game_test_3d", r"\[3dtest\] ALL PASSED", 240),
    ("save", "save_integrity_check", r"\[save-integrity\] DONE fails=0\b", 120),
    ("craft", "craft_check", r"\[craft-check\] DONE fails=0\b", 120),
    ("security", "attack_sim", r"\[attack-sim\] DONE fails=0\b", 120),
    ("boot", "boot_check", r"\[boot\] DONE fails=0\b", 240),
    ("footsteps", "footstep_check", r"\[footstep-check\] DONE fails=0\b", 120),
    ("save_guard", "qa_guard_check", r"\[qa-guard-check\] DONE fails=0\b", 120),
    ("audio_start", "audio_hum_check", r"\[audio-hum\].*bad=0\b", 120),
    ("audio_bus", "audio_bus_check", r"\[audio-bus\] DONE fails=0\b", 120),
    ("loot_floor", "loot_floor_check", r"\[lootfloor\] DONE fails=0\b", 180),
    ("theme", "theme_unify_probe", r"\[theme-unify\] DONE bad=0\b", 120),
    ("settings", "settings_persist_probe", r"\[settings-persist\] DONE bad=0\b", 120),
    ("accessibility", "a11y_probe", r"\[a11y\] DONE bad=0\b", 120),
    ("layout", "ui_layout_check", r"\[uilay\] DONE fails=0\b", 180),
    ("release_polish", "release_polish_check", r"\[release-polish\] DONE checks=39 fails=0\b", 180),
    ("closeout", "closeout_check", r"\[closeout\] DONE .*fails=0\b", 900),
    ("goldmaster", "qa_headless_suite", r"\[qa\] DONE fails=0\b", 240),
    ("touch", "touch_probe", r"\[touch-probe\] DONE fails=0\b", 180),
]


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def judge(output, code, marker=None, engine=False):
    if code:
        raise RuntimeError(f"Process exited {code}")
    if marker and not re.search(marker, output):
        raise RuntimeError(f"Required completion marker missing: {marker}")
    if engine and FATAL.search(DUMMY_TEARDOWN.sub("", output)):
        raise RuntimeError("Godot reported a script/resource error; see the full log")


def clean_environment():
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("TLS_", "QA_", "CLOSEOUT_", "TIMING_", "GIT_"))}
    env.update({"GODOT_SILENCE_ROOT_WARNING": "1", "PYTHONUTF8": "1", "PYTHONIOENCODING": "utf-8"})
    return env


def copy_project(source, dest):
    excluded = {".git", ".godot", ".qa_logs", "build", "exports", "__pycache__", ".ruff_cache", ".venv", ".signing"}
    def ignore(_directory, names):
        return [name for name in names if name in excluded or name.startswith(".lint-demo-")
                or name.endswith((".jks", ".keystore", ".pfx", ".pem", ".env"))]
    shutil.copytree(source, dest, ignore=ignore)


def configure_profile(project, name):
    if not re.fullmatch(r"__TLS_QA_[a-f0-9]{32}", name):
        raise ValueError("Invalid disposable profile name")
    config = project / "project.godot"
    text = config.read_text(encoding="utf-8")
    text = re.sub(r'^config/name="[^"]*"$', f'config/name="{name}"', text, flags=re.M)
    text = re.sub(r'^config/(?:use_custom_user_dir|custom_user_dir_name)=.*\n?', '', text, flags=re.M)
    # A unique application name also keeps the shell user-data guard on the
    # exact same directory as Godot. Custom directories use a different root.
    # Keep use_custom_user_dir=false: a custom directory moves the profile out of
    # Godot/app_userdata, away from the directory the shell user-data guard snapshots.
    # The name is still written because the pre-existing release-profile gate asserts
    # application/config/custom_user_dir_name == application/config/name; with the flag
    # off Godot ignores it and uses the (unique, disposable) application name.
    text = text.replace("[application]",
                        '[application]\nconfig/use_custom_user_dir=false\nconfig/custom_user_dir_name="' + name + '"', 1)
    config.write_text(text, encoding="utf-8")


@contextmanager
def import_configuration(project):
    """A fresh editor cannot load a font-backed custom theme before importing fonts."""
    path = project / "project.godot"
    original = path.read_bytes()
    text = original.decode("utf-8")
    text = re.sub(r'(?m)^theme/custom\s*=.*$', 'theme/custom=""', text)
    path.write_text(text, encoding="utf-8")
    try:
        yield
    finally:
        path.write_bytes(original)


def verified_profile(output, expected):
    for line in output.splitlines():
        if line.startswith("[release-profile] {"):
            data = json.loads(line[len("[release-profile] "):])
            path = Path(data["path"]).resolve()
            if data["name"] == expected and path.name == expected and expected.startswith(PREFIX):
                return path
    raise RuntimeError("Disposable profile was not confirmed by the engine; no saves may be modified")


def reset_profile(path, expected):
    if path.name != expected or not re.fullmatch(r"__TLS_QA_[a-f0-9]{32}", expected):
        raise RuntimeError("Refusing profile cleanup outside this job")
    # No user-selected or normal game directory can enter this path.
    for candidate in (path, path.with_name(path.name + ".qa_snapshot"), path.with_name(path.name + ".qa_snapshot.tmp")):
        if candidate.is_symlink():
            raise RuntimeError("Refusing a symlink in a QA profile")
        if candidate.exists():
            shutil.rmtree(candidate)


class Pipeline:
    def __init__(self, args):
        self.args = args
        self.source = Path(args.source).resolve()
        self.out = Path(args.output).resolve()
        if self.out == self.source or self.source in self.out.parents:
            raise ValueError("Output must be outside the source checkout")
        self.out.mkdir(parents=True, exist_ok=False)
        (self.out / "logs").mkdir()
        (self.out / "artifacts").mkdir()
        self.env = clean_environment()
        self.env.update({"GODOT": args.godot, "PY": sys.executable})
        self.commit = subprocess.check_output(["git", "-C", str(self.source), "rev-parse", "HEAD"], text=True).strip()
        self.report = {"schema": 1, "source_commit": self.commit,
                       "started_utc": datetime.now(timezone.utc).isoformat(), "state": "CHECKING", "checks": [],
                       "manual_review": {"real_device_controls_audio_performance": "PENDING", "asset_music_rights": "PENDING",
                                         "android_store_signing_and_testing": "PENDING"}, "artifacts": []}
        self.profile = None
        self.profile_name = PREFIX + uuid.uuid4().hex
        self.qa = self.out / "qa-project"
        self.save_report()

    def save_report(self):
        path = self.out / "artifacts" / "release-report.json"
        path.write_text(json.dumps(self.report, ensure_ascii=False, indent=2), encoding="utf-8")

    def command(self, name, command, cwd=None, timeout=300, env=None, marker=None, engine=False, raw=None):
        print(f"[{len(self.report['checks']) + 1}] {name}", flush=True)
        log = self.out / "logs" / (name + ".log")
        started = time.monotonic()
        with log.open("wb") as stream:
            creation = {"start_new_session": True} if os.name != "nt" else {"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP}
            proc = subprocess.Popen(list(map(str, command)), cwd=cwd or self.source, env=env or self.env,
                                    stdout=stream, stderr=subprocess.STDOUT, **creation)
            try:
                code = proc.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                if os.name == "nt":
                    subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"], capture_output=True, check=False)
                else:
                    os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
                code = 124
        output = (raw or log).read_text(encoding="utf-8", errors="replace") if (raw or log).exists() else ""
        item = {"name": name, "exit_code": code, "seconds": round(time.monotonic() - started, 2), "log": str(log.relative_to(self.out))}
        item["known_dummy_teardown_messages"] = len(DUMMY_TEARDOWN.findall(output))
        item["resource_retention_messages"] = len(re.findall(r"ERROR: \d+ resources still in use at exit", output))
        item["dummy_texture_retention_messages"] = len(re.findall(r"RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE'", output))
        self.report["checks"].append(item)
        try:
            judge(output, code, marker, engine)
        except RuntimeError as error:
            item["result"] = "FAIL"
            item["error"] = str(error)
            self.save_report()
            raise RuntimeError(f"{name}: {error}; log: {log}") from error
        item["result"] = "PASS"
        if raw and raw.exists():
            shutil.copy2(raw, self.out / "logs" / (name + ".engine.log"))
        self.save_report()
        return output

    def engine(self, name, project, extra, marker=None, timeout=240, env=None, windowed=False):
        run_env = dict(env or self.env)
        # The proof wrapper records the source revision without changing the checkout.
        git_dir = subprocess.check_output(["git", "-C", str(self.source), "rev-parse", "--absolute-git-dir"], text=True).strip()
        run_env.update({"GIT_DIR": git_dir.replace("\\", "/"), "GIT_WORK_TREE": self.source.as_posix()})
        raw = project / ".qa_logs" / "proofs" / (name + ".out")
        command = [self.args.bash, (project / "tools/qa_sim/proof_run").as_posix(), "--launch", name, "--", self.args.godot.replace("\\", "/"),
                   "--windowed" if windowed else "--headless", "--path", project.as_posix(), *extra]
        return self.command(name, command, cwd=project, timeout=timeout, env=run_env, marker=marker, engine=True, raw=raw)

    def gate(self, name, scene, marker, timeout, extra=(), env_extra=None, user_args=(), windowed=False):
        if self.profile:
            reset_profile(self.profile, self.profile_name)
        env = dict(self.env, TLS_UDG_GUARDED="1", QA_SOAK_SEC="20")
        if env_extra:
            env.update(env_extra)
        args = [*extra, f"res://scenes/tools/{scene}_scene.tscn"]
        if user_args:
            args += ["--", *user_args]
        return self.engine(name, self.qa, args, marker, timeout, env, windowed=windowed)

    def full_battery(self):
        git_dir = subprocess.check_output(["git", "-C", str(self.source), "rev-parse", "--absolute-git-dir"], text=True).strip()
        env = dict(self.env, GIT_DIR=git_dir.replace("\\", "/"), GIT_WORK_TREE=self.qa.as_posix(),
                   TLS_SKIP_REIMPORT="1", QA_SOAK_SEC="20")
        for number in (1, 2):
            reset_profile(self.profile, self.profile_name)
            name = f"full_battery_{number}"
            try:
                self.command(name, [self.args.bash, "tools/check.sh", "--all"], cwd=self.qa,
                             timeout=5400, env=env, marker=r"Всё зелёное.*Проверок пройдено:", engine=True)
            finally:
                logs = self.qa / ".qa_logs"
                if logs.exists():
                    shutil.copytree(logs, self.out / "logs" / name, dirs_exist_ok=True)

    def import_project(self, project, name):
        with import_configuration(project):
            try:
                self.engine(name, project, ["--editor", "--import", "--quit"], timeout=600)
            except RuntimeError:
                first = self.report["checks"][-1]
                if first["name"] != name or first["exit_code"] != 0:
                    raise
                self.engine(name + "_verify", project, ["--editor", "--import", "--quit"], timeout=600)
                first.update(result="RECOVERED_IMPORT", recovered_by=name + "_verify")
                self.save_report()
        shutil.copy2(self.source / "default_bus_layout.tres", project / "default_bus_layout.tres")

    def add_artifact(self, path):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Empty or missing artifact: {path}")
        self.report["artifacts"].append({"file": path.name, "bytes": path.stat().st_size, "sha256": sha256(path)})

    def export(self, project, preset, directory, filename):
        dest = self.out / "builds" / directory
        dest.mkdir(parents=True)
        target = dest / filename
        self.engine("export_" + directory, project, ["--export-release", preset, str(target)], timeout=1200)
        if not target.exists():
            raise RuntimeError(f"Godot did not create {target}")
        if directory == "web" and not all((dest / ("index." + ext)).is_file() for ext in ("wasm", "pck", "js")):
            raise RuntimeError("Incomplete Web export")
        if directory == "android":
            shutil.copy2(target, self.out / "artifacts" / target.name)
            self.add_artifact(self.out / "artifacts" / target.name)
        else:
            # Godot may leave its unembedded Windows template beside the EXE.
            # It is an export intermediate, not a runtime dependency.
            for temp in dest.glob("*.tmp"):
                temp.unlink()
            (dest / "BUILD_INFO.json").write_text(json.dumps({"source_commit": self.commit, "godot": "4.7.2.stable",
                   "built_utc": datetime.now(timezone.utc).isoformat(), "platform": directory,
                   "manual_device_review": "PENDING"}, indent=2), encoding="utf-8")
            archive = self.out / "artifacts" / ("LastStreetlight-1.0.1-" + directory + ".zip")
            with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as files:
                for path in sorted(dest.rglob("*")):
                    if path.is_file():
                        files.write(path, path.relative_to(dest))
            self.add_artifact(archive)

    def android(self, project):
        sdk = Path(self.args.android_sdk).resolve()
        java = Path(self.args.java_home).resolve()
        tools = sdk / "cmdline-tools/latest/bin"
        manager = tools / ("sdkmanager.bat" if os.name == "nt" else "sdkmanager")
        if not manager.is_file() or not (java / "bin" / ("java.exe" if os.name == "nt" else "java")).is_file():
            raise RuntimeError("Android needs Android SDK command-line tools (latest) and JDK 17; see tools/release/README.md")
        keys = ["GODOT_ANDROID_KEYSTORE_RELEASE_PATH", "GODOT_ANDROID_KEYSTORE_RELEASE_USER", "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"]
        if any(not self.env.get(key) for key in keys):
            raise RuntimeError("Existing Android release keystore credentials are required")
        self.env.update({"JAVA_HOME": str(java), "ANDROID_HOME": str(sdk), "ANDROID_SDK_ROOT": str(sdk)})
        self.env["PATH"] = str(java / "bin") + os.pathsep + self.env.get("PATH", "")
        if not self.args.bundletool or not Path(self.args.bundletool).is_file():
            raise RuntimeError("Android requires --bundletool from provision.py --android")
        required = ["platform-tools", "platforms/android-36", "build-tools/36.1.0", "ndk/29.0.14206865", "cmake/3.10.2.4988404"]
        if any(not (sdk / directory).is_dir() for directory in required):
            raise RuntimeError("Android SDK packages are incomplete. Run the mega PowerShell driver with -Android to install them.")
        settings = Path(self.args.godot).parent / "editor_data/editor_settings-4.7.tres"
        if not settings.exists():
            raise RuntimeError("Self-contained editor settings missing after import")
        text = settings.read_text(encoding="utf-8")
        for key, value in (("export/android/android_sdk_path", sdk), ("export/android/java_sdk_path", java)):
            line = key + "=" + json.dumps(str(value).replace("\\", "/"))
            text = re.sub(r"^" + re.escape(key) + r"=.*$", "", text, flags=re.M) + "\n" + line + "\n"
        settings.write_text(text, encoding="utf-8")
        source = Path(self.args.templates) / "android_source.zip"
        # Godot's own Gradle source archive; reject any unexpected traversal.
        android_build = project / "android/build"
        android_build.mkdir(parents=True, exist_ok=True)
        (android_build / ".gdignore").write_text("\n", encoding="utf-8")
        with zipfile.ZipFile(source) as files:
            for member in files.infolist():
                target = (android_build / member.filename).resolve()
                if android_build.resolve() not in target.parents and target != android_build.resolve():
                    raise RuntimeError("Unsafe Android template path")
            files.extractall(android_build)
            if os.name != "nt":
                for member in files.infolist():
                    mode = (member.external_attr >> 16) & 0o777
                    if mode:
                        (android_build / member.filename).chmod(mode)
        (project / "android/.build_version").write_text("4.7.2.stable", encoding="utf-8")
        self.export(project, "Android", "android", "LastStreetlight-1.0.1.aab")
        self.audit_android(self.out / "builds/android/LastStreetlight-1.0.1.aab")

    def audit_android(self, bundle):
        self.command("android_signature_integrity", [sys.executable, "tools/qa_sim/aab_check.py", str(bundle),
                     "--secrets", "--bundletool", self.args.bundletool], timeout=300, marker=r"aab_check: PASS\b")
        self.command("android_package_audit", [sys.executable, "tools/qa_sim/release_export_check.py", "--aab",
                     str(bundle)], timeout=300)

    def run(self):
        try:
            dirty = subprocess.check_output(["git", "-C", str(self.source), "status", "--porcelain"], text=True)
            self.report["source_tree_dirty"] = bool(dirty.strip())
            if dirty.strip() and not self.args.allow_dirty:
                raise RuntimeError("Commit the source before a release build; exact revisions are required")
            version = self.engine("godot_version", self.source, ["--version"], marker=r"4\.7\.2\.stable")
            self.report["godot_version"] = version.strip()
            self.command("static", [self.args.bash, "tools/check.sh", "--static"], timeout=1200,
                         marker=r"Всё зелёное.*Проверок пройдено:")
            copy_project(self.source, self.qa)
            configure_profile(self.qa, self.profile_name)
            self.import_project(self.qa, "qa_import")
            output = self.gate("profile", "release_profile_check", r"\[release-profile\] DONE fails=0", 120)
            self.profile = verified_profile(output, self.profile_name)
            for gate in GATES:
                self.gate(*gate)
            if self.args.full_release:
                self.full_battery()
                self.gate("windowed_performance", "perf_check", r"\[perf\] DONE fails=0\b", 600, windowed=True)
                self.gate("windowed_audio", "audio_truth_gate", r"\[audio-truth\] PASS overall", 180, windowed=True)
            for seed in (1, 2, 3):
                output = self.gate(f"bot_{seed}", "qa_autoplay", rf"\[bot s{seed}\]   result.*WIN", 1200,
                                   env_extra={"QA_SEED": str(seed), "QA_TIME_SCALE": "4"})
                self.command(f"bot_counters_{seed}", [self.args.bash, "tools/qa_sim/bot_counter_check.sh",
                             str(self.out / "logs" / f"bot_{seed}.engine.log")])
            timing_logs = []
            for fps in (30, 60, 120):
                self.gate(f"timing_{fps}", "timing_equiv", rf"\[timing\] DONE fps={fps}\b", 360,
                          extra=("--fixed-fps", str(fps)), user_args=(f"--tfps={fps}",))
                timing_logs.append(str(self.out / "logs" / f"timing_{fps}.engine.log"))
            self.command("timing_compare", [sys.executable, "tools/qa_sim/timing_compare.py", *timing_logs], marker="PASS")
            self.report["state"] = "AUTOMATION_PASSED"
            self.save_report()
            if self.args.verify_only:
                self.report["state"] = "GAME_CHECKS_PASSED_MANUAL_REVIEW_PENDING"
                self.save_report()
                print(self.report["state"] + ": " + str(self.out / "artifacts"), flush=True)
                return
            build = self.out / "export-project"
            copy_project(self.source, build)
            self.import_project(build, "export_import")
            self.export(build, "Windows Desktop", "windows", "LastStreetlight.exe")
            self.export(build, "Web", "web", "index.html")
            if self.args.android_sdk:
                self.android(build)
            self.report["state"] = "BUILDS_CREATED_MANUAL_REVIEW_PENDING"
            self.save_report()
        except BaseException as error:
            self.report["state"] = "FAILED"
            self.report["error"] = str(error)
            self.save_report()
            raise
        finally:
            if self.profile:
                reset_profile(self.profile, self.profile_name)
            self.report["finished_utc"] = datetime.now(timezone.utc).isoformat()
            self.save_report()
            archive = self.out / "artifacts" / "verification-logs.zip"
            with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as files:
                for path in sorted((self.out / "logs").rglob("*")):
                    if path.is_file():
                        files.write(path, path.relative_to(self.out))
            paths = sorted(p for p in (self.out / "artifacts").iterdir() if p.name != "SHA256SUMS.txt")
            (self.out / "artifacts" / "SHA256SUMS.txt").write_text("".join(f"{sha256(p)}  {p.name}\n" for p in paths), encoding="utf-8")
        print("BUILDS_CREATED_MANUAL_REVIEW_PENDING: " + str(self.out / "artifacts"), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--bash", required=True)
    parser.add_argument("--templates", default="")
    parser.add_argument("--android-sdk", default="")
    parser.add_argument("--java-home", default="")
    parser.add_argument("--bundletool", default="")
    parser.add_argument("--verify-only", action="store_true", help="Run checks and bots without exports or a release")
    parser.add_argument("--full-release", action="store_true", help="Also run check.sh --all twice and real windowed GPU/audio probes")
    parser.add_argument("--allow-dirty", action="store_true", help="Development only; report records a dirty source tree")
    Pipeline(parser.parse_args()).run()
