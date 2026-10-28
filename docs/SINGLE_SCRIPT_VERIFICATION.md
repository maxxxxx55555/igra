# Single-script verification — 2026-10-28

Fresh checks for the source packaged in this pass. The s35 source-hash
manifest records the exact checked files; documentation-only packaging does
not change those bytes. Full engine and device acceptance are still pending:

- Release tool tests: 20 total, 13 passed, 7 skipped. Skips require real PowerShell.
  `docs/artifacts/rc16/proofs/s35_release_tests.out` contains the full exit-0 log.
- Changed-file lint: GDScript parser/lint, Python correctness, Bash shellcheck
  and workflow actionlint, 0 findings. Configured run:
  `docs/artifacts/rc16/proofs/s35_lint.out`.
  The run covers 20 GDScript, 7 Python, 2 Bash and 1 workflow files.
  Earlier s34 logs remain historical evidence, not the new runtime validation.
- Localization: 1570 keys, all five non-English locales pass truth checks;
  placeholder fuzz checks 504 calls with 0 findings. Integrity manifest matches.
- Achievement audit: 31 entries, 0 findings. The district-count helper is retained.
- Audio and AAB self-tests pass. AAB negative fixtures in the release-tool tests
  reject wrong package/version, debuggable and unreadable manifests, failed tools,
  missing bundletool, obsolete signer selection and failure of either Android audit.
- Proof-wrapper regression preserves a large output tail, nested child output
  and the actual nonzero exit footer. Cold import tests require a clean strict
  retry and preserve the original diagnostic; persistent failure remains fatal.

- New tests verify two literal full-battery passes, preservation of failed
  pass logs, and that verify-only mode never exports while retaining its log
  archive and checksums. QA application names match the shell guard's path.
- New GDScript regressions cover the source fixes listed in
  `RELEASE_COMPLETION_20261028.md`; they pass parsing/lint but were not executed
  in Godot here. The new menu art was rendered from SVG to PNG and inspected.
- `s35_locale_and_content.out` records locale truth/fuzz, integrity and the
  achievement audit. `s35_source_hashes.sha256` identifies the verified files.

Before delivery the generated PowerShell is independently checked for grammar,
remaining template placeholders, payload SHA256, exact restored source commit,
and byte identity of every changed or added file against the local committed
source. Deleted paths, if any, must also be absent. A disposable local remote tests new
branch creation and rejection of overwrite under an empty expected lease.
The transport result is appended to the sole delivered PowerShell as a comment;
it does not change the source commit or the embedded payload.

No user GitHub branch was written during these checks. The package starts from
pinned public PR #31, bf563cc9353dd1fb3717943b416530e6a9e4fb2c; it includes its
content without replaying those commits. The public main read in this pass was
aacc5d8c7a24e661ebd1be785d32ce01ec9e7f43.

The full static battery was not run on this sparse checkout (its original
assets are fetched when restoring the public base). Targeted checks above are
the actual results. Real Windows PowerShell execution, a full new engine/bot
run of this exact tree,
fresh GPU/AF3 frames, signed game AAB, physical-device review, rights confirmation
and Play Console publication remain pending. Earlier temporary-workspace results
are not presented as current SourceHead release evidence. See the embedded handoff.
