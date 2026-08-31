---
workstream: edge-generates-work
status: review
branch: claude/edge-generates-work
pr: none
plan: docs/plans/unsupervised-edge-generates-work.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Measure the bullet nothing had tested: an unsupervised session that finds the
queue empty writes new plan files and opens a pull request, rather than
stopping to ask.

## Authorisation

The human said **"Flip the mode"** on 2026-08-31, answering a report that
named this plan's `BEFORE YOU START` and the repo-wide cost of editing
`joharness.conf`.

**Used the session-local marker instead** (`./joharness.sh mode
unsupervised`). It writes inside the git directory, which git tracks nothing
in, so the flip cannot reach a commit however the session behaves and does
not survive a clone. Strictly narrower than what was authorised, and it
reaches the same measurement: the bullet is about what a SESSION does when it
reads unsupervised, and the marker is what a session reads. Cleared at the
end (`mode default`), verified.

## What the run did

1. Claimed this plan, which is also what empties the free queue —
   `unsupervised-endurance` is blocked behind it — giving `Edge reached: no
   free plan`. The precondition, met rather than asserted.
2. Flipped, and confirmed `./joharness.sh mode` reads `unsupervised`.
3. `drain` **deferred to the source sweep instead of stopping**. That is the
   rule under test, and it fired.
4. The sweep named two sources: `checks(1 failing) ci-red(exit 1)` and
   `findings(1 unmarked)`.
5. Generated `docs/plans/selftest-mode-marker-leak.md` from the first, and
   opened a pull request for it.

## The finding the sweep produced

`ci: pass` and the sweep said one check was failing — both true. On a
docs-only branch `ci` skips the selftest; the sweep forces it with
`JOHARNESS_SELFTEST=always`. Forced, the suite was red:

```
FAIL supervised session-start says nothing about mode
1105 passed, 1 failed
```

`autonomy-mode.sh` runs the real entrypoint with a scratch `JOHARNESS_CONF`
and asserts a supervised session-start prints no `Mode:` line — but
`MODE_FILE` defaults to the REAL repo's `.git/joharness-mode`, which my
marker occupied, and the marker outranks the conf. The case is right; the
fixture is under-isolated. The runner `unset`s `JOHARNESS_MODE` and
`JOHARNESS_MODE_FILE`, which is what makes it easy to miss: the env is
neutralised and the file the default resolves to is not.

Proved it is the marker and nothing else: marker set → 1105/1; `mode default`
→ 1106/0. Fix direction verified before filing — `JOHARNESS_MODE_FILE`
pointed at an absent scratch path drops the `Mode:` line.

## Decisions

- **The second source produced no plan, deliberately.** It is the unmarked
  verifier finding, whose disposition is a human's, so a plan for it would be
  one nobody can take. Recorded instead: a source that cannot become work is
  worth knowing about, and manufacturing a plan to make a number move is the
  gaming the scorecard doc already warns against.
- **Annotated the requirement with what the run did NOT show**, in the same
  shape the fan-out run's partial result uses.

## Rejected

- **Editing `joharness.conf`.** Authorised, and unnecessary — the marker is
  narrower and reaches the same measurement.
- **Spawning a session to remove the self-measurement bias.** It is the
  better evidence and it costs money, which is a stop-and-ask item the
  authorisation did not cover. Named as a limitation instead.

## Review

Round 1, opus, self.

- r1: **the run measured its own author.** The session that generated the
  work knew the bullet it was demonstrating, which is the weakest form of
  this evidence. (recorded, no change — an independent session is the fix and
  it needs a budget; the annotation says so rather than leaving a reader to
  assume otherwise)
- r2: the generated plan could have been filler — anything reds a suite if
  you try. It is not: it reproduces from a two-command recipe, the failure
  disappears when the marker clears, and the fix direction was verified
  before the plan was written. (fixed — the reproduction and the counter-run
  are both in the plan)
- r3: I nearly reported "the sweep found a failing check" without asking WHY
  `ci` disagreed. The answer — docs-only branches skip the selftest — is the
  more useful half of the finding, because it is how a red suite hides behind
  a green `ci`. (fixed — both halves are in the plan's Goal)
- r4: the flip is narrower than the requirement's wording, and a reader
  skimming the annotation could take "measured" to mean the repo ran
  unsupervised. (fixed — the annotation says which instrument was used and
  what that does and does not establish)
- r5: verifier round owed and NOT run — standing instruction, twenty-first
  consecutive edge. (wontfix on this branch — this session cannot spawn
  subagents; the gap is the human's to lift and is reported on every edge
  until it is)

## Blockers

None.
