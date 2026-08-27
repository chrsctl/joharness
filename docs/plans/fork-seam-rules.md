---
plan: fork-seam-rules
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/AGENTS.md, .agents/docs/handover/README.md
---

## Goal

The Loop's finish ritual assumes the session that opens a pull request also
merges it. A fork PR breaks that assumption at three points, all observed
on PR #79 (head `DaniloNaujoksi/joharness`, merged by the human
2026-08-26): the session cannot merge, so the human merges at a time the
session does not control and the workstream file strands on `main`
(`./joharness.sh finish` on 2026-08-27 counts it: "1 already on
origin/main"); the fork session's later state is invisible to this repo's
hook, so the next session here inherited a blocker ("wait for approval on
PR 79") that had been resolved for ~21 hours; and the fork session's own
repair PR (#81) sits open with no steward, because step 7 forbids driving
any other session's PR and the fork session cannot merge its own. Fix the
rule text so the seam is named where sessions read.

## Scope

Three edits, each answering one observed failure.

**1. Retire timing when the merge is not yours.** Step 7 says the
workstream file deletes in "the LAST COMMIT BEFORE the pull request
opens". On a self-merged branch the session controls the gap between
review and merge; on a fork PR the human merges whenever they get to it,
and no commit can land in between. #79's file said `in-progress` (waiting
on human review), so the `status: done` edge gate never fired, and the
merge stranded it. Add one line at that sentence: when the merge is a
human's (any PR the session cannot merge itself — a fork PR always), the
review record and the retire commit both land BEFORE asking the human;
ready-for-human is the edge, not ready-for-merge.

**2. Name the fork seam at "Own =".** Step 7's ownership sentence never
says what opening a PR the session cannot merge means. Add one line: a
fork PR is never self-mergeable — opening one hands the merge to the
human, so plan for edit 1's timing; and a session that finds an open fork
PR whose session ended flags it to the human (Decide alone already has the
flag rule) instead of assuming someone watches it. Counted 2026-08-27: 2
open fork PRs (#81, #82), 0 drivable by any base-repo session under the
current text.

**3. Fork state is invisible to liveness checks.** The handover README's
push-time-not-liveness section reasons entirely from this repo's refs.
A fork session's pushes never appear in them, and `/who` cannot see the
fork session either. Add one line where that reasoning lives: across a
fork seam the PR on GitHub is the only shared state — re-fetch it at
every check, never inherit a conclusion about it from a handover file or
a scheduled check-in.

## Out of scope

- Who merges. The self-merge rule (ratified 2026-08-23) stands; fork PRs
  are human-merged by construction, not by a new rule.
- Gate mechanism. Making `ci`/`finish` detect a human-merge PR with a live
  workstream file is a `joharness.sh`/selftest change — its own plan if
  the rule text proves insufficient, and a scope conflict with
  `ci-scope-selftest` this plan deliberately avoids.
- Driving or adopting PRs #81 and #82. The human's call; this plan only
  makes the next stranded PR visible sooner.
- Any change to where workstream files live or when self-merged branches
  retire them.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `.agents/harness/AGENTS.md` grows by no more than ~6 lines. Measure
  `wc -c` at the commit you start from, not any figure written here.
- Replay #79's sequence against the new text: each of the three failures
  (stranded file, inherited dead blocker, stewardless open PR) is now
  named by a rule a literal reader hits before repeating it.

## Where to look

- `.agents/harness/AGENTS.md`, step 7 "LAST COMMIT BEFORE" sentence —
  edit 1's anchor.
- `.agents/harness/AGENTS.md`, step 7 "Own =" sentence — edit 2's anchor.
- `.agents/docs/handover/README.md`, push-time-not-liveness reasoning —
  edit 3's anchor.
- PR #79 and #81 on GitHub — the evidence; #81's body documents the
  broken retire from the fork session's side.
- `docs/handover/loop-autonomy-review.md`, retired on this plan's own
  branch — findings f1–f3 with sources
  (`git log --all --full-history --oneline -- docs/handover/loop-autonomy-review.md`).

## Traps

- Caveman style: one line per rule at the anchor; reasoning that needs
  more goes to `.agents/docs/`, not into `.agents/harness/AGENTS.md`.
- The harness names no environment and no repository. Write the seam
  generically — "a PR the session cannot merge", never a fork's name.
- Scope shares both files with `harness-rules-field-review` — never the
  same wave; whichever merges second reconciles the step-7 text.
- Do not resurrect the declined caps or touch the ratified self-merge
  conditions while editing next to them.
