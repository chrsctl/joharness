---
workstream: peer-divergence-in-conduct
status: in-progress
branch: claude/peer-divergence-in-conduct
pr: none
plan: peer-divergence-in-conduct
issue: none
session: https://claude.ai/code/session_011XQzvhT3gi1L4ZkAsjfdh4
agent: sonnet
updated: 2026-10-08
next: Verifier findings fixed and recorded below. Delete the research file
  (closed NO, graduated), run ./joharness.sh finish, open the PR and merge.
---

## Goal

Settle `docs/research/peer-divergence-in-conduct.md`: can two branches be
shown, from their artifacts alone (retired workstream files), to have faced
the SAME rule and answered it differently? Graduate the answer into
`.agents/docs/orchestrated.md`, delete the research file.

## Decisions

- The Method's written corpus is "this repository" (joharness), but the
  measured instance (issue #251: six waived a CI gate, two blocked) happened
  in a consumer, `chrsctl/gx`. Joharness's own 50-edge feedback window has
  zero comparable instances (one `status: blocked` edge, and it is a stale
  "in-progress" leftover label, not a real block) — no way to test a
  candidate rule's false-positive rate from joharness's own history alone.
  Added `chrsctl/gx` via `add_repo` to test against the real measured
  instance rather than reason about it in the abstract. This widens the
  corpus beyond what the file's Method section names; recorded here rather
  than silently, per "An unrecorded method is a failed file."
- gx's full history (depth=3000 fetch, reaches the initial commit) is
  readable; found issue #251's instance precisely via issue #266 (closed,
  names the exact commit `d87e17c8`, session id, and PR #351 as precedent).

## Rejected

- (none yet)

## Review

- r1: (verifier) the research file argued its own closure (Consequence:
  "Closes NO") but was never deleted; per `.agents/docs/research/README.md`
  "Graduating," done means deleted, and a `research:`-keyed file left in
  the tree is still read as an open node regardless of its prose. (fixed —
  deleted in the retire commit, last before the pull request.)
- r2: (verifier) the Verification section's tally didn't add up: "8 of 9
  GROUNDED" against claims that actually totalled 10 once the WEAK and
  UNGROUNDED ones are counted as their own bullets rather than subtracted
  from 9. (fixed — recounted against the actual 10 bullets: 8 GROUNDED, 1
  WEAK, 1 UNGROUNDED.)
- r3: (verifier) a corrected claim was tagged "CORRECTED by second
  context, originally claimed otherwise" instead of one of the three
  words `.agents/docs/research/README.md` requires ("GROUNDED, WEAK or
  UNGROUNDED... a vocabulary with no word for a refuted claim would push
  that into prose nobody greps"). (fixed — split into its own UNGROUNDED
  bullet naming the original wrong claim, followed by the corrected
  GROUNDED finding.)
- r4: (verifier) the PR #403 bullet was tagged GROUNDED in Findings while
  the Verification section called the same claim WEAK — Findings was never
  updated to match. (fixed — Findings now also says WEAK, with the
  overstated "nothing else" corrected to what the commit actually
  contains.)
- r5: (verifier) the Method section still read "Not yet run" while
  Findings opened "Run per Method" — contradictory within one file, and
  Method's own fenced block never named the commands actually used for
  the `gx` deviation. (fixed — Method rewritten to say what ran, in two
  blocks: the written corpus first, producing nothing to test; the
  deviation to `gx` second, with every command actually used.)
- r6: (verifier) the "exactly 3 blocked workstream files" finding named no
  reproducible command, only "full-history pickaxe search" in prose.
  (fixed — the exact `git log ... | grep` command is now in both Method
  and the Findings bullet.)
- r7: (verifier) the graduated paragraph in `orchestrated.md` said "two
  days earlier" for a gap that is six days (2026-09-11 to 2026-09-17) by
  the file's own other numbers, and "38 minutes EARLIER... not after" was
  ambiguous about earlier/later than what. (fixed — exact dates and an
  unambiguous "38 minutes BEFORE that block, not after.")
- r8: (session) after the verifier round, re-read my own "2 of 2 true
  positives, 0 false positives" line and found it implied a precision
  count I had not actually run: a day-scale window around the second
  incident would pair the block against however many same-window peers
  share the cause text (plausibly more than the one example, PR #439, I
  had cited), not against exactly one. That is not a false positive —
  correctly flagging many peers against one outlier is the point — but
  stating it as a 2-vs-0 count overclaimed a tally I never computed.
  (fixed in both files — reworded to what was actually tested: the rule
  keeps the three incidents apart from EACH OTHER across a month, which
  is the one false-positive shape this corpus could show and didn't; it
  drops the invented precision/recall framing.)

## Blockers

None.

## Where to look

- `docs/research/peer-divergence-in-conduct.md` — the question itself,
  Method section names the exact commands to run.
- `.agents/docs/orchestrated.md` — graduation target.
