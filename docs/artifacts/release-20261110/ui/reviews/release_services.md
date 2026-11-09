# Archive macro council: independent bee 3

Date: 2026-11-10. Reviewer: release_services. Scope: journal macro composition only; approval to integrate, not approval of the entire game or final release.

Read `../README.md`. Inspected the actual native 1920x1080 engine frames for A/B/C English High and Russian Low, then C Russian High at original resolution. A pixel comparison of every candidate's English and Russian High/Low pair found all six pairs identical. Thus the inspected composition and text also survive these captured Low settings; this is not a claim about unobserved world rendering.

## Pairwise decisions

| Pair | Winner | Reason visible in the frames |
| --- | --- | --- |
| A versus B | B | The larger, complete artifact is easier to appreciate. A divides attention between a relatively small elevated photograph and a detached, oversized pale transcription block below it; the combined split feels less like one physical evidence view. |
| A versus C | C | C makes the intact illustration dominant and keeps the transcription next to it on a restrained dark field. A's broad pale lower panel competes with the object and spends much of the screen on empty paper. |
| B versus C | C | B improves artifact scale but its tall pale right wall attracts more attention than the manuscript and feels like an application document pane. C has a clear photograph-to-title-to-transcription path, intact cool/warm lighting, and quiet natural-width section navigation. |

Ranking: **C > B > A**. **APPROVE C for integration**, subject to the concrete final-binding checks below. This is an independent composition vote; the owner's rejection of earlier button/window studies overrides those old votes.

## Reference and native inspection

Compared the actual `igra-filtered/docs/art/style_reference/sheet_2_screens.webp` journal tile with the candidate frames. The sheet's useful identity is physical manuscript/photo evidence, cold darkness and warm local illumination. C carries that identity through the existing full-aspect illustration without pretending its screen layout is an exact reproduction of the sheet. No new texture, fog, grain or post-processing was added by this review.

At native size, C's paper edge, tape, blueprint lines and table grain remain visible. Its photograph has no aspect distortion or UI-induced seam; the lamp's existing bright core is part of the unchanged source, not a new concealment effect. The Russian title wraps to two complete lines and body copy remains separated from the photograph; the long Russian selector fits its row. Section names at the foot remain readable without a wall of equal-width buttons. I observed no cut-off glyph, overlapping selector/body, or washed-out body text in these frames. This does not establish readability on a phone or with a long document.

## Required checks after binding

- The reviewed C prototype still visibly contains `Codex`/the Russian shell title at top-left. Remove the unwanted shell label in the final binding requested by the owner; do not claim it was absent from this evidence.
- The shown progress says found 1 of 101 while the locked count says 120. Verify both against the same actual catalog before presenting the final frame. Do not hard-code a cosmetically plausible count.
- Capture and inspect the final bound C English/Russian High/Low family, including long reader content, scroll, selection/focus and the other archive pages. These prototype images cannot approve those unseen consumers.
- Preserve the owner's existing main-menu artwork and the journal illustration. The vote approves arrangement, not replacing those assets or changing their identity.

Evidence: `ui-archive-candidates/{a,b,c}/frames/journal_{en,ru}_tier{2,0}.png`. No source files, engine state or production assets were changed by this review.
