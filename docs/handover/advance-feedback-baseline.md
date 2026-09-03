---
workstream: advance-feedback-baseline
status: review
branch: claude/current-state-review-oxfb7f
pr: none
plan: advance-feedback-baseline
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-03
next: Retire this file and the plan in the last commit before the pull request, then open and merge it
---

## Goal

`./joharness.sh sources` reports the sweep NOT dry on four unmarked findings
that predate the gate which stops new ones reaching that state (PR #181,
merged `847f64e3`). They live in workstream files deleted from every tree, so
they cannot be marked where they were written. Move `joharness.sh:FB_SINCE`
past that gate, and say in the comment which four the bump absorbs.

## Decisions

- **Re-measured on today's `main` before starting, not taken from the plan.**
  `./joharness.sh sources` (2026-09-03) reads 4 unmarked at the OLD literal
  and 0 at the new one. The plan's own
  evidence line was counted 2026-09-02, before PR 195, 196, 197 and 199
  merged; the check that matters is that those merges' own records are AFTER
  the new baseline and still counted, so this bump cannot hide anything
  recent.
- **Tier escalated sonnet to opus.** The plan asks `sonnet`; escalation is
  allowed, downgrade is not. Moving this literal moves the stop condition of
  unsupervised mode, and the plan's own first Trap is that a baseline a
  session moves to make its own backlog disappear is the thing PR 161's
  design note warns against.

## Rejected

## Review

Round one — verifier at opus on a10624a, three passes; each finding
re-checked here against its source before being accepted. It found no
behavioural defect: the bump is correct, the four findings are the right
four, and nothing merged after the new baseline is dropped. Everything below
is the justification text, which for a threshold IS the guard — nothing
automated pins this literal (r5).

- r1: (verifier) the comment table annotates PR 174 r2 as `(recorded — ...)`,
  and that finding ends in a bare `(recorded)` with nothing after it.
  Re-read here from its own merged blob: the bullet closes "...is the shape
  of a loop. (recorded)". Not cosmetic — `fb_marker`'s comment singles out
  the bare form as the STRONGER case for refusing it as a verdict, and the
  table erased the one instance of it (fixed in the comment; commit a10624a's
  message carries the same error and is already pushed, so it is corrected
  here rather than rewritten)
- r2: (verifier) "Before that gate, a branch could go from review straight to
  its retire commit ... and four findings did" is true for three.
  `lint_finding_markers` did not exist when PR 161 merged — `8a45fe3`
  (2026-08-31 11:59Z) is not an ancestor of `d0716e7` (11:08+02:00), checked
  with `git merge-base --is-ancestor`. PR 161 r6 escaped an ABSENT gate, not
  a skippable one (fixed)
- r3: (verifier) "PR 195's seventeen findings and PR 199's eleven" is a
  measured number with no command and no date, against step 5's rule that a
  measured number carries what produced it in the same sentence. The verifier
  re-counted both independently and got the same 17 and 11 (fixed — command
  and date named)
- r4: (verifier) the sentences this block sits under are wrong, and the
  diff's whole shipping story leans on them: "Unresolvable is BLIND now,
  never zero" and "which is BLIND and never zero". An unresolvable baseline
  is not blind — `fb_collect` counts EVERY finding and `cmd_sources` prints
  "ALL history — no baseline in this repo" with a real count.
  `.agents/harness/selftest/sources.sh` says so in as many words, "An
  UNRESOLVABLE baseline counts everything. Not blind", and pins it with three
  cases. The SAFETY the sentences claim is real (it can never read dry over
  an unbounded backlog); the mechanism named is not (fixed — pre-existing,
  and adjacent, but a reviewer of the next bump reads exactly this)
- r5: (verifier) nothing pins the literal, proved by mutation rather than
  grep: with `FB_SINCE` set to `origin/main`'s own tip — resolvable, and
  hiding all four findings plus everything since — `ci` passes and the suite
  reads 1286 passed, 0 failed, byte-identical. Correct for a threshold in a
  file that ships: an "ancestor of origin/main" assertion would red every
  consumer, and the comment already elects human diff-review as the guard.
  It is why r1-r4 outrank everything else in this round (no change — recorded
  so the next bump knows the record is the whole mechanism)
- r6: (verifier) "sweep dry, for the first time" is a snapshot, not a
  property, and THIS branch is the thing most likely to undo it: it merges
  after the new baseline, so any bullet in this very section landing without
  a verdict `fb_marker` accepts puts `sources` back to 1 unmarked the moment
  it merges (no change — every finding above carries one, and `sources` is
  re-run on the retired head before the pull request opens)
- r7: (verifier) the reproduction the comment hands a reader,
  `JOHARNESS_FEEDBACK_SINCE=847f64e3`, is silently ignored when
  `JOHARNESS_FEEDBACK_CACHE` names a populated directory: `fb_cache_key`
  keys on the ref tip and the limit only, while `FB_UNMARKED_SINCE` and
  `FB_SINCE_OK` both ride the cache. Pre-existing, and off for command-line
  runs, which is why the numbers here are trustworthy (fixed — the comment
  names the variable to unset; the cache-key defect itself is somebody's
  plan, not this one's)
- r8: (verifier) this file said `sources` "reads 4 unmarked at the default
  baseline and 0 with JOHARNESS_FEEDBACK_SINCE=847f64e3", which stops being
  true the moment the commit lands — after it the default IS 847f64e3, and a
  next session running the sentence reads 0 and concludes the record is wrong
  (fixed — old literal / new literal)
- r9: (verifier) `next:` carried three actions; the template says one (fixed)
- r10: (verifier, not a defect here) `docs/plans/unsupervised-drain-only.md`
  is an open queue plan that DELETES `FB_SINCE`, `fb_since_ok`, `cmd_sources`
  and `src_unmarked` outright, and names this plan in its own scope. Step 2's
  oldest-first ordering picked correctly — this plan is `1c607b7` 19:02, that
  one `ba8315c` 21:04 — and drain-only already anticipates the outcome. The
  change's shelf life is one merge (no change — recorded for whoever takes
  drain-only)
- r11: (verifier) `finish` is red mid-build as expected, and the retire
  commit owes BOTH files: the plan file is the last thing in the tree still
  asserting the old literal and the old count, so leaving it makes the tree
  contradict itself (fixed — the retire commit deletes both)

## Blockers

None.

## Where to look

- `docs/plans/advance-feedback-baseline.md` — the plan, its Traps, and the
  four findings it names.
- `joharness.sh:FB_SINCE` — the literal, and the comment that has to say what
  the bump absorbs.
