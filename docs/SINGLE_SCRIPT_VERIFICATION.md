# Single-script verification — 2026-10-27

Fresh checks for the source packaged in this pass:

- Release tool tests: 18 total, 11 passed, 7 skipped. Skips require real PowerShell.
  `docs/artifacts/rc16/proofs/s34_release_tests.out` contains the full exit-0 log.
- Changed-file lint: GDScript parser/lint, Python correctness, Bash shellcheck
  and workflow actionlint, 0 findings. Configured run:
  `docs/artifacts/rc16/proofs/s34_lint_configured.out`.
  The preceding run lacked the repository's gdlintrc in its sparse checkout;
  its style findings are not game defects and were not used as a passing check.
- Localization: 1566 keys, all five non-English locales pass truth checks;
  placeholder fuzz checks 499 calls with 0 findings. Integrity manifest matches.
- Achievement audit: 31 entries, 0 findings. The district-count helper is retained.
- Audio and AAB self-tests pass. AAB negative fixtures in the release-tool tests
  reject wrong package/version, debuggable and unreadable manifests, failed tools,
  missing bundletool, obsolete signer selection and failure of either Android audit.
- Proof-wrapper regression preserves a large output tail, nested child output
  and the actual nonzero exit footer. Cold import tests require a clean strict
  retry and preserve the original diagnostic; persistent failure remains fatal.

Before delivery the generated PowerShell is independently checked for grammar,
remaining template placeholders, payload SHA256, exact restored source commit,
and byte identity of changed source files. A disposable local remote tests new
branch creation and rejection of overwrite under an empty expected lease.
The transport result is appended to the sole delivered PowerShell as a comment;
it does not change the source commit or the embedded payload.

No user GitHub branch was written during these checks. The package starts from
pinned public PR #31, bf563cc9353dd1fb3717943b416530e6a9e4fb2c; it includes its
content without replaying those commits. The public main read in this pass was
aacc5d8c7a24e661ebd1be785d32ce01ec9e7f43.

Real Windows PowerShell execution, a full new engine/bot run of this exact tree,
fresh GPU/AF3 frames, signed game AAB, physical-device review, rights confirmation
and Play Console publication remain pending. Earlier temporary-workspace results
are not presented as current SourceHead release evidence. See the embedded handoff.
