# MUSIC RIGHTS MEMO — the twelve Gemini-generated tracks (MUSIC-27)

Written 2026-10-26 by the arena release agent after a terms research pass.
This memo is the honest verification the owner asked for: what the licences
say today, what they do not say, and the three decisions available. It is not
legal advice; the final call is the owner's (RELEASE_CHECKLIST section 10,
owner step 1).

## The tracks in scope

Twelve music beds generated with Google's Gemini music generation and shipped
in `assets/audio/music/` (the district lit/dark beds and layer tracks listed in
`docs/ASSET_LICENSES.md`, Session 27 M1 row). The synthesized beds, the old
menu theme and the single boss theme are NOT in scope: they were produced by
this repository's own tools and carry no third-party question.

## What the terms say (checked 2026-10-26)

1. **Generative AI Additional Terms of Service / Gemini API Additional
   Terms**: Google does not claim ownership over original content generated
   by Gemini. A public Google support thread (Oct 2026) repeats this for
   free-plan music used in monetized videos:
   https://support.google.com/gemini/thread/473528984
2. **Google APIs Terms of Service, Section 5(e)** restricts modifying,
   selling, creating derivatives of, or distributing content returned from
   Google APIs unless authorized by the content owner or applicable law.
   Whether 5(e) reaches *original generated music* (as opposed to
   third-party content surfaced by an API) is exactly the ambiguity: a
   Oct-2026 thread on the official Google AI developer forum asking a Google
   team member to clarify commercial monetization, looping and combining of
   Lyria-generated music has **no official answer**:
   https://discuss.ai.google.dev/t/189157
3. The repository's own earlier reading (ASSET_LICENSES, Session 27) matches:
   "Google claims no ownership … and say nothing on commercial use".

## The honest verdict

- Ownership: no Google claim. Good.
- Distribution inside a shipped product (this game): the 5(e) reading is
  genuinely unsettled. Publishing the game with these tracks is defensible
  under the Generative AI Additional Terms, and questionable under a strict
  5(e) reading. No court or Google statement resolves it as of 2026-10-26.
- Therefore the tracks are **ship-able but not risk-free**, and the risk is
  the owner's to accept in writing.

## The three decisions (owner picks one before monetized rollout)

A. **Accept and document.** Ship the twelve tracks; add this memo's verdict
   to the store data-safety/licensing notes; accept the residual 5(e)
   ambiguity. Cost: zero. Risk: low-probability takedown/licensing dispute.
B. **Replace with the synthesized fallback.** The way back already exists:
   the synthesized beds, the old menu theme and the boss theme
   (`docs/store/HUMAN_CHECKLIST.md` music row). The twelve files get swapped
   for tool-synthesized equivalents (`tools/qa_sim/bed_synth.py`,
   `music_post.py` loudness house table), re-gated by the seam and loudness
   gates, and re-exported. Cost: one art pass on a machine with the engine.
   Risk: none; quality step-down.
C. **License replacements.** CC0/licensed library tracks that satisfy the
   lit-twin contract of `docs/AUDIO_COVERAGE.md`. Earlier per-gap web
   searches found no CC0 track that satisfies the contract; cost: real
   licensing money or search time.

Whatever is picked, record it as a dated row in `docs/ASSET_LICENSES.md`
and in the release acceptance record. Do not let the decision stay implicit.
