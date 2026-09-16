---
plan: unowned-block-age
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, .agents/harness/selftest/dispatch.sh
---

## Goal

Issue #254's third proposal, reduced to the half that needs no threshold. A
branch parked `blocked` sat 141 hours with nobody driving it, the row
printed identically on every pass, and it was fixed only when a person asked
directly six days later. The issue asks that something escalate rather than
reprint. Escalating needs a bound, and a bound is the human's number — but
the reason nobody could see the problem is that the row carries no duration
at all. `BLOCKED: the human's, holds no slot` reads the same at ten minutes
and at six days. Print how long the block has stood, and an unowned block
stops being indistinguishable from a fresh one by reading alone.

## Scope

- `joharness.sh` — in `cmd_dispatch`, where an in-flight row's `blocked`
  status already suppresses the hold annotation and the respawn, add the age
  of the BLOCK to that row: how long ago `status: blocked` was written into
  this workstream file, not how long ago the branch last pushed. The two
  differ and the difference is the point — a branch parked for six days may
  have pushed twenty minutes ago.

  The reading is git-only: the commit that most recently SET `status:
  blocked` in this file on this ref, and its committer date.

  `git log -S'status: blocked'` alone does not answer it, and the reason is
  the trap this bullet exists for. `-S` matches every commit where the
  COUNT of that string changed, which is the park (0 to 1) and the unpark
  (1 to 0) and the retire that deletes the file. Verified on this repo,
  2026-09-16: `git log --format=%h -S'status: blocked' --all --full-history
  -- docs/handover` returns a retire commit at the top of the list. So
  neither end of that list is the answer — newest may be an unpark, oldest
  is the first block the branch ever had, and a branch parked, unparked and
  parked again has both.

  The discriminator is the file's CONTENT at the candidate commit: walk the
  `-S` matches newest first and take the first one whose `<ws>` at that
  commit still says `status: blocked`. Write the walk against a fixture that
  parks, unparks and parks again, because a query that is right on a branch
  blocked once is right by accident.

  Unreadable is its own answer and says so — a shallow clone has no history
  for most refs, and printing 0h there would read as parked this minute.

- `.agents/harness/selftest/dispatch.sh` — cases, in the topic that already
  builds a blocked manager.

## Out of scope

- Proposal 2, blocked-versus-gone. Whether a session may respawn a branch a
  human parked is product direction; the issue says so and does not claim an
  answer. Nothing here reads the control plane or changes any respawn rule.
- Proposal 3's escalation itself. A bound is a threshold and thresholds here
  are the human's. This plan produces the number the bound would be set
  from; it sets none, adds no knob, and changes no verdict line.
- Re-deriving the issue's central example. The blocked-holder release
  predates the run it describes, so the four plans it names cannot have been
  held by that branch on this code — recorded on the issue, 2026-09-16.
  Nothing here depends on that example being right.
- Any change to what `blocked` means, who may write it, or `holds no slot`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- A fixture whose workstream file was committed `blocked` at a backdated
  time prints the block's age on that row, and the number is the BLOCK's,
  not the push's: the same fixture pushes again after the block, and the
  row's two ages differ. Both asserted — an age assertion that passes when
  the code prints the push age is the defect this exists to catch.
- A branch parked, unparked and parked again reports the age of the SECOND
  block. Asserted, and it is the case that separates a real walk from a
  `-S` list read at either end: the newest match there is the unpark, the
  oldest is the first block.
- A ref with no readable history for the file says so in words, and does not
  print an age. Asserted.
- A row that is not blocked gains nothing. Asserted as a refute AND with a
  positive control, since a refute alone passes when the feature is deleted.
- Proved by reverting, per Loop step 5: removing the annotation reds a
  positive assertion, not only a refute.
- `./joharness.sh perf` stays inside its pinned budget, or the budget moves
  in this same diff with the counted number and the command in the comment.
  This adds a git invocation per blocked row and `perf` counts exactly that.
- SHIPS: `joharness.sh` reaches every consumer. In a consumer, a blocked
  branch's `dispatch` row prints the block's age.

## Where to look

- `joharness.sh:cmd_dispatch` — the in-flight row builder, at the point
  where `$status` is already read and the hold annotation is already gated
  on it. The row's flag string is assembled there.
- `joharness.sh:dispatch_age_min` — the existing age reader and its text
  formatter, including its `</dev/null` guard: this runs inside a `while
  read` loop fed by a here-string, and a git left to inherit that stdin eats
  the loop's remaining lines. Any new git call here needs the same guard.
- `.agents/harness/selftest/dispatch.sh` — the blocked-manager fixture
  (`mgr-beta`), and the backdating idiom the stall cases already use.

## Traps

- The block's age is not the branch's age. Reading the push age is the
  cheap wrong answer and it prints a plausible number.
- Never respawn, kill or unpark anything from this row. It prints; it
  decides nothing.
- A git call inside the row loop without `</dev/null` consumes the loop's
  own input. The existing reader carries that guard and the reason.
- Escalate to opus if the parked-unparked-parked case cannot be separated
  from the first block by a git query alone — a row printing a confidently
  wrong duration is worse than one printing none.
