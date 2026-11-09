# Visual qualification decision journal

## 2026-11-02 — V1–V5 qualification begins

Baseline: release/finish-20261101 at 229697f. Runtime revision: 756a4f2. PR 47 remains a draft; no release acceptance is implied by passing engineering gates.

The owner authorizes autonomous design, implementation, agents, and publication. That authorization supersedes the older OpenCode-only branch/zone contract and optional design-confirmation steps. Repository edit, style, canon, gate, commit, and recordkeeping procedures still apply.

The four available reference sheets cover UI, screens, item icons, and store art. Dedicated world/material sheets mentioned in older records are absent. Sheet 2's photographic street tiles provide a mood reference, not an invented exact facade-material target. Permanent night and first-person gameplay remain canon; the historical `day` capture means restored power, not sunlight.

Options considered:

1. Publish the engineering candidate immediately. It preserves tested fixes but fails the newly required visual evidence. Rejected for release acceptance.
2. Add stronger post-processing. Cheap to render, but conceals the unresolved geometry/material gap and violates V5. Rejected.
3. Qualify each hero family with three distinct candidates, independent pairwise reviews, native-resolution inspection, actual engine views, Low-tier frames, and family checks. Selected. Existing assets are baseline evidence, never automatically accepted winners.

Menu round 1 uses three photographic street compositions: A, enclosed residential street with recessed entrances; B, corner frontage and transformer service lane; C, a wider courtyard with a single streetlight. All preserve the left menu's readable negative space, an eye-level camera, cold blue-teal materials and localized sodium light. No grain, vignette, contrast crush, or fog is added to disguise missing detail. These are candidate images, not screenshots of playable geometry.

The council comprises art_canon (canon/reference), integration_review (family/Low/store), and gpu_teardown (material/loupe/geometry). Each reviewer records their own verdict. Root must not invent votes or equate a preferred candidate with a completed four-stage acceptance.

Engineering evidence already retained: 28 native engine gates, 215 decoded audio assets, 36 loop seams, three winning autoplay seeds, 30/60/120 FPS timing checks, Windows/Web exports, and GitHub CI. The four mandatory engine gates passed again on this date. New runtime changes invalidate the relevant prior captures and require fresh gates before commit/export.

## Qualification order and falsifiers

- Inventory every named hero family and its actual consumers; explicitly record unused art and missing reference tiles.
- Generate A/B/C separately for the menu, inspect raw pixels, and rank against sheet 2 street imagery. Reject malformed geometry, disconnected reflections, clipped lamps, excessive baked haze, or unreadable composition.
- Mount candidates in an isolated project and capture the actual menu at native, close, and distant presentation sizes on High and Low; retain full uncropped frames.
- Apply the same procedure to loading, journal, maps, cards, icons, and relevant world/PBR families. At most five hero rounds or three non-hero rounds; any majority decision after the cap records dissent.
- Only accepted changes enter production paths. Missing reference evidence or unfinished family gates remains an explicit open item, never a fabricated PASS.

Publication requires green engineering checks and an honest visual status. Signed Android, physical-device performance, and store submission remain separate unverified release tasks.

## 2026-11-09 — restored current main before continuing

GitHub verification found PR 47 merged on November 5 as `35e297f9627c7deb49337ea57254db6a15cfabb5`. Current main is `bef60fdd`, 154 commits beyond the saved continuation. The previous local changes were backed up under `work/resume-local-20261109` outside the repository; the checkout was fast-forwarded and switched to main, as the owner explicitly requests. No newer changes were replaced by the old release bundle.

The current release report records signed Windows/Android artifacts and an emulator boot. These are newer evidence than the November 2 report; physical-device and store acceptance are still unverified. This pass does not equate those engineering results with photographic visual fidelity.

Menu source rework B3 is REJECTED: generative highlight editing softened the material detail. B4 preserves the original B pixels except channels above 236, using the owner's requested PowerShell workflow and the existing highlight-rolloff formula. Native resolution remains 1672×941. All lower-valued channels are byte-identical; no resize, sharpening, grain, haze, or shadow crushing is applied. The RGB delivery has SHA-256 `1446560b1acfaa2de64e85b8ff26e405d1ae4326de15d153e87ec67ef74b5fba`; source review alone does not close the new engine/family gates.

Old world candidate bindings are superseded. Main already includes the dedicated wet-asphalt shader and changes its material list; applying the November 2 probe would remove newer puddle work. New candidates must preserve that shader's standing-water behavior and current power-stage gains while evaluating actual material detail.

Cloudflare connector discovery returned no plugin. A local Worker/private-R2 deployment path is being prepared because existing Web PCK/WASM files exceed the static-hosting per-file limit. No Cloudflare account connection or deployment has been verified. “Dots” remains unidentified after the clarification request; the owner asked to continue silently, so independent game and agent work proceeds without inventing an integration.

The November 9 request explicitly chooses the current main-menu picture as the quality target for the rest of the interface and textures. Preserve that production image. B4 remains an exploratory candidate; its review does not authorize silently replacing the owner's selected target or changing the art-slot dimensions. The menu-only fog/grain removal exposes existing material detail. The remaining effort prioritizes world materials and actual interface gaps.

## 2026-11-10 — owner corrections and final verification

The owner's rejection supersedes the old button B/journal A and macro B approvals. Three new actual archive layouts were compared independently: root, world_finish and release_services each chose C>B>A. C preserves the illustration at its full aspect, gives it the dominant area, uses a dark reading column and quiet section navigation, and removes the visible Codex umbrella. Journal, quests, help and progression pages remain functional; removing the umbrella does not remove their game data. Discovered records replace the wall of question-mark buttons, and the locked count uses the canonical101 placed records. The main-menu picture and mouse parallax remain unchanged.

Controls use the licensed bundled full-Cyrillic Roboto Condensed face, natural case, explicit primary/secondary/ghost/row/tab states and48px minimum new action targets. The menu wordmark keeps Bebas. A real legacy Shop inheritance defect was fixed at the shared screen factory. Rejected MSDF text experiments are not shipped. The final typography uses the established20/36 size ladder; no operating-system font dependency is introduced.

Generic text notices and hover now stay silent. A real pickup retains its positional loot sample without an added generic procedural tone; explicit failures retain one cue. The selected new menu/restored music is human-composed Hymn/Moonlight by Scott Buckley under CC BY4.0, with exact official source hashes, conservative mastering and in-game attribution. Gemini produced playable candidates, but its download path did not yield valid media; none of those failed files is shipped. The model cannot audition audio, so numerical sound checks and artist provenance do not constitute a subjective listening verdict.

The latest owner map/darkness request has priority over old minimap plans: only restored, rendered illumination plus actual unobstructed observation grants persistent architectural memory. Unobserved ground remains blank; player, enemy, item and quest markers are excluded. The existing current-main implementation is tested before changing it. Only Russian and English are selectable; old13-locale reports describe historical builds.

The world material candidates remain rejected for distant repeated facades and weak Low-tier structure. No candidate is rolled into production merely to satisfy an artifact count, and no post-processing is added to conceal those defects. Whole-game photographic fidelity and physical-phone/store acceptance remain open until demonstrated.

Static verification exposed a separate Windows proof-parser bug: CRLF logs produced an unknown exit code although their normalized SHA and quoted evidence matched. A failing CRLF exit7 regression preceded the one-character regex fix; all309 historical proof rows now verify without rewriting evidence. Privacy classification now explicitly identifies inert music-attribution URLs. Fresh GitHub branch inventory and pruned refs confirm two old absorbed audit branches were already deleted; verification deleted no remote branch.

Cloudflare Worker/private-R2 tooling is locally tested but no account, bucket or deployment is connected. The unidentified Dots service remains unconnected. These are reported as unverified external integrations, never as completed game features.

Final gameplay verification exposed real integration regressions rather than justification for relaxed gates. Fixed touch slots could not contain translated labels plus the new font/padding; the HUD now packs all14 controls using their actual minimum sizes and reapplies safe-area/one-handed placement. Native inspection additionally caught missing action glyphs and English side captions left in Russian. Three existing bundled action textures replace unsupported glyphs, and every caption/tooltip refreshes before reflow. Sixteen actual EN/RU High/Low, small/large, normal/one-handed cases verify224 control records; logical hit-area checks do not substitute for physical-phone ergonomics.

LightGrid retained detached lights across scene transitions and read their invalid global transforms. The fix rejects unattached registrations, drops detached/freed entries before position reads and validates references before casts. A real lifecycle regression fails three cases before the fix and passes six afterward; the existing17 perception/cartography checks still pass. No light level, map disclosure rule or fatal-error judge was relaxed.

The release pipeline expected39 polish assertions although its non-capture invocation executes32. Seven additional assertions belong to optional screenshot capture. The pipeline now requires the complete32-check normal run with zero failures; an incomplete31-check result and a failed32-check result are both rejected by regression tests. The Windows Bash fixture now passes portable forward-slash paths. All14 release-judge tests and18 Windows PowerShell5.1 checkout/checksum fixtures pass.
