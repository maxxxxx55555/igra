# MUSIC RIGHTS MEMO — the twelve Gemini-generated tracks (MUSIC-27)

Written 2026-10-28 by the arena release agent after a terms research pass and corrected in review the same day (Session 37).
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

## What the terms say (checked 2026-10-28)

1. **Ownership (read 2026-10-28):** the Google Terms of Service ("Your content") and the Gemini API Additional Terms ("Use of Generated Content": "Google won't claim ownership over that
   content") say that Google claims no ownership of content generated with its services. The "Generative AI Additional Terms of Service" that this memo first named do not contain that sentence
   and, as their page says, no longer apply to most users since 2024-05-22. None of these texts says anything about commercial use of the output. A thread of the Gemini Apps Community asks
   exactly that for free-plan music used in monetized videos, but the page as fetched shows the question and no answer, so it is no evidence either way:
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
4. **Which terms govern these tracks (review note, 2026-10-28):** the twelve tracks were made in the Gemini **app** (its Music skill), not through the paid API. Section 5(e) was read on developers.google.com/terms and says what is summarised in item 2, but it governs content *returned from the APIs*; for app-made tracks it is the nearest published restriction, not necessarily the governing
   one. The first thing to read is the terms of the account that made the tracks: the Google Terms of Service, the Generative AI Additional Terms and the Gemini Apps terms. The verdict below stands as a statement of
   risk, not of law. One more line of the Google Terms of Service ("Don't abuse our services", read the same day) forbids misleading others into thinking that generative AI content was created by a human:
   the store listing, the credits and the marketing must not present the tracks, or the repainted images of `docs/ART_PASS_2.md`, as human-made.

## The honest verdict

- Ownership: no Google claim. Good.
- Distribution inside a shipped product (this game): the 5(e) reading is
  genuinely unsettled. Publishing the game with these tracks is defensible
  under the ownership statements of item 1, and questionable under a strict
  5(e) reading. No court or Google statement resolves it as of 2026-10-28.
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
