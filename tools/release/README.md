# Last Streetlight 1.0.1 release candidate

The generated **Igra-MegaRelease.ps1** includes the actual game changes as a
SHA256-checked Git bundle. It is not a prompt for another AI and does not rely on
an earlier chat, patch download, local game folder, or the old upload-only script.

Run it on Windows 10/11 from an ordinary PowerShell window:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Igra-MegaRelease.ps1
```

`ExecutionPolicy Bypass` applies only to this process. GitHub CLI stores its own
login using its normal credential flow. Global Git configuration, main branch,
and existing project folders are preserved. Git/GitHub CLI/Python installations may use
Windows' own installer prompts when absent. Downloaded executables are official;
Godot 4.7.2 editor and export templates have pinned SHA256 hashes.

## What happens

1. Verify the embedded source before writing to GitHub.
2. Ask for `owner/repository` (default `maxxxxx55555/igra`). GitHub CLI opens its
   browser/device authorization flow if the active account is not logged in.
   A read-only account or archived repository stops the job. Use `gh auth switch`
   before rerunning if the wrong account is active. Workflow permission can be
   requested by GitHub because the release branch enables CI.
3. Create a fresh job directory, clone the remote, obtain the public baseline,
   verify the bundle and its expected revision, and restore the included game.
   Create a unique `release/1.0.1-...` branch. An empty expected remote lease
   prevents even a concurrent branch creation from being overwritten. Verify
   the uploaded commit by reading the remote. Only then print `SOURCE_SAVED`.
4. Install a private Python environment and official Godot editor/templates.
   The templates download is approximately **1.3 GB**. Allow **10 GB free disk**
   for the source, editor, templates, two project copies, logs and artifacts.
5. Run the static battery, full script/scene compile, localization, save/security,
   world/craft/boot, audio routing/startup silence, floor, UI/accessibility,
   new lifecycle/terminal regressions, closeout, GOLDMASTER and touch gates.
   Then finish three input-driven bot runs and compare gameplay at 30/60/120 FPS.
   A timeout, nonzero exit, missing completion marker or script/resource error
   blocks the build. Known Godot resource-retention diagnostics and the exact
   dummy-renderer material teardown diagnostic remain in logs and report counts;
   other material/resource errors fail the job.
6. Export Windows Desktop and Web release builds. Package each separately with
   the exact source commit, full logs, JSON report and SHA256SUMS.
7. Upload those files to a **GitHub draft release**, tied to that exact commit.
   Builds are release assets, not oversized binary commits in the source branch.

The source is uploaded before tool installation and long verification. If a later
stage fails, the console gives the existing remote branch and local working path;
the failed stage's full log and report remain under `verification`. A failure is
never printed as a completed release. The optional `-SourceOnly` stops after
verified source upload and explicitly skips checks/builds.

QA runs a separate project copy with an engine-verified random custom user-data
directory. Only that exact disposable directory can be cleared between tests.
Original game saves/settings are not reset. The export copy retains the game's
real name and user directory; test settings are never shipped. The original
audio bus layout is restored after editor import in each copy.
During the very first import the copy's custom GUI theme is deferred until its
fonts have been imported. The original project configuration is restored even
if that import fails; normal QA and exported games use the original theme.

## Android signing

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Igra-MegaRelease.ps1 -Android
```

Android additionally needs an installed **JDK 17**, Android SDK command-line tools
under `cmdline-tools/latest`, accepted SDK licenses, and the owner's existing
release/upload keystore and alias. The script asks for paths and a hidden
password. It never generates a replacement signing identity or puts passwords
in the repository, its Godot command-line arguments or report. Godot handles
the signing tools internally. Keystore environment
variables are cleared on exit. The SDK package versions match the pinned
4.7.2 template's `config.gradle`: API 36, build-tools 36.1.0, NDK 29.0.14206865.
Missing licenses must be accepted with Android's own `sdkmanager --licenses`.
The optional signed AAB is uploaded only after export succeeds. No Play Console
upload or store approval is claimed.

Version name is 1.0.1 and Android version code 7, following the public branch's
code 6. If a higher version code has already been uploaded to Play Console,
increase the preset before the next signed build. Android and Windows
authenticode signing are different: the Windows executable is not code-signed.

## Review before publishing

The report ends at `BUILDS_CREATED_MANUAL_REVIEW_PENDING`. It does not turn
unknown checks into passes. Review Windows controls, a full real-device session,
save/continue, all ending screens, headphones/speakers, native performance and
touch controls on a physical Android device. Check music/art/font rights and
the actual store listing, rating and privacy answers. Web builds must be served
by HTTP(S), not opened with `file://`.

After reviewing those items, the owner can publish the draft in GitHub Releases.
Publishing to an app store still requires its account, signing, forms and review.
The script cannot truthfully certify these human/platform checks automatically.

## Development and evidence

`python tools/release/provision.py --root <toolchain>` downloads the pinned
toolchain. `pipeline.py --help` exposes the cross-platform verification/export
driver. Its output must be outside the source checkout. `--allow-dirty` is for
development; the normal mega driver requires a committed source tree.

`python tools/release/test_release.py` checks failure detection and profile
boundaries. Set `IGRA_TEST_PWSH` to a real PowerShell executable to also run the
bootstrap against disposable local Git remotes, including browser-auth routing,
bundle corruption, read-only access, protected/existing branches, a racing
branch creation and failed remote verification. Those tests never contact or
push to the owner's GitHub repository.

`python tools/release/package.py <output.ps1>` builds the self-contained file
from a clean, committed tree. The bundle has public prerequisite `a4b1943`; it
preserves the newer public release art and all original project history.
