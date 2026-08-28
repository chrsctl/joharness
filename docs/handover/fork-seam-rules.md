---
workstream: fork-seam-rules
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: fork-seam-rules
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: retire plan + workstream, PR, merge
---

## Goal

Plan `docs/plans/fork-seam-rules.md`: the Loop's finish ritual assumes the
session that opens a pull request also merges it. A fork PR breaks that at
three points, all observed on PR #79. Three rule edits, one per observed
failure, at the anchors where sessions read.

## Decisions

- Plan wants `sonnet`; this session runs `opus`. Escalation of the
  implementer, allowed. Review depth follows the PLAN's tier, so `agent:`
  here records `sonnet` and the review is `/code-review` (high) on the full
  diff, not the opus multi-lens shape.
- The plan's two counted figures are STALE and are not repeated anywhere
  shipped. Re-counted 2026-08-28: `./joharness.sh cleanup` reports "none —
  the ritual ran" where the plan cites "1 already on origin/main" on
  2026-08-27; open fork PRs are 0, not 2 — #81 and #82 both merged
  2026-08-28. The rule gap is unaffected (it is about text, and #79's
  sequence is still replayable from history), but nothing here quotes a
  figure that no longer reproduces.
- AGENTS.md growth measured against the commit this branch started from,
  not a figure written anywhere: 184 lines -> 190, +6, inside the plan's
  "~6 lines". Max line length back to 99, the file's own pre-existing max.

## Rejected

- Keying the rule on "fork PR". A base-repo session handed a fork PR to
  drive HAS the merge button — merge permission is the base repo's, not the
  head's — so "a fork PR always" is false and would leave such a PR undriven.
  The rule keys on the merge button; the fork is named as the usual case.

## Review

`/code-review` (high) on the full diff — the depth this plan's `sonnet` tier
names. Six findings, all in the rule TEXT, which is the executable artifact
here; `ci` was green throughout and caught none of them.

- r1 The ownership line said "retire on their clock", the exact INVERSE of
  the rule it forwards to. A top-down reader waits for the human's merge to
  retire and strands the workstream file — PR #79's failure, re-caused by
  its own fix. (fixed: "retire BEFORE you ask, below")
- r2 "nothing of yours lands after the ask" is false, and collides with step
  7's own "no unresolved human review thread": a session getting review
  feedback on an open fork PR would believe it cannot push the fix and open
  a second PR — the stewardless shape this plan cites as failure 3. (fixed:
  the true consequence is their clock, not a closed door)
- r3 "(a fork PR always)" conflated fork with unmergeable and contradicted
  the line above it. (fixed — see Rejected)
- r4 "Fork session's pushes never reach this repo's refs" is factually
  wrong. Verified against the live remote 2026-08-28: `git fetch origin
  'refs/pull/79/head:refs/tmp/pr79'` resolves to `e0106a0`, that fork
  session's own commit, authored by the fork's owner. Branch refs are
  invisible; the PR head is not. `/who` was overstated too — its
  control-plane half sees a same-account fork session. (fixed: claim
  narrowed to branch refs, with the command that proves it)
- r5 "unrecoverable" is contradicted six lines later by `cleanup --apply`,
  and by PR #81, whose first commit was exactly that remedy. (fixed: costs a
  follow-up pull request)
- r6 The splice left a 140-character line where the file's max was 99.
  (fixed: re-wrapped)

Acceptance replay, #79's three failures against the new text: the stranded
file is named at step 7's ownership sentence AND again at the retire-timing
sentence; the dead inherited blocker is named where liveness is reasoned
about; the stewardless open PR is named in the same ownership sentence. A
literal reader hits each before repeating it.

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md:124` — "LAST COMMIT BEFORE", edit 1's anchor.
- `.agents/harness/AGENTS.md:89` — "Own =", edit 2's anchor.
- `.agents/docs/handover/README.md:196-224` — push-time-not-liveness, edit 3.
