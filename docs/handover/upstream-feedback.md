---
workstream: upstream-feedback
status: in-progress
branch: claude/orchestrator-review-child-repos-tb0z79
pr: none
plan: upstream-feedback
issue: none
session: https://claude.ai/code/session_01XAYv4zxtpBFMpabWuYvxig
agent: sonnet
updated: 2026-09-06
next: Implement cmd_upstream in joharness.sh, then the conf key, then the docs
---

## Goal

The requester asked for a variable that lets the orchestrator route what a
child repo found, after a manager finishes, into defect and improvement report
pull requests on joharness — and then corrected the ask to: a feedback
mechanism, disabled by default, shape ours to choose.

## Decisions

- **The switch is `JOHARNESS_UPSTREAM_FEEDBACK`, `off` by default.** Same
  off/on shape as `JOHARNESS_REVIEW`: off means the report is available and
  nothing acts on it, on means a role acts. It fails closed on any other
  value, like every other switch in `joharness.sh`.
- **The report is a research node in canonical, not a requirement.** A
  requirement is the human's goal to set and `lint_requirement_writes` reds
  an unattended branch that adds one. A research file with a `research:` key
  is a real queue item canonical lists, claims and deletes on the merge that
  answers it — so the report enters by rules already written, with no new
  node type and no new lint.
- **`joharness.sh` reports; the command files.** `cmd_upstream` opens
  nothing and pushes nothing, which is what lets a human run it anywhere.
  The pull request is `.claude/commands/upstream-report.md`'s, and only when
  the switch is on.
- **The reporter is a session, spawned once per merged edge, and it does not
  hold a manager slot.** Dispatch counts managers from git and a reporter
  cuts no branch in the child, so it cannot be counted there. The cost is
  named where the switch is documented: on, this is one session beyond
  `JOHARNESS_MAX_MANAGERS`.
- **Canonical reports nothing.** `JOHARNESS_CANONICAL=1` and `upstream` says
  CANONICAL and stops: findings here are already in the repo that owns the
  fix.

## Rejected

- **The orchestrator writing the report itself.** It edits one file, a
  killed manager's workstream file, and reads no plan. Giving it a second
  write and a second repository is the bound this mode inherited from
  `.agents/docs/unsupervised.md`, spent for nothing a spawn does not do.
- **A GitHub issue instead of a pull request.** The requester asked for pull
  requests, and an issue in canonical enters the queue ahead of plans with
  no evidence attached and no shape the graph lints.
- **Filing the fix.** A child asserting canonical's fix is the reverse of
  § 1 of `.agents/docs/feedback.md`: the signal that you fought the harness
  is not evidence the harness is wrong. The report carries the measurement
  and canonical decides.
- **A sixth bootstrap interview question.** `.agents/docs/orchestrated.md`
  already refused that cost for its own knobs; the sync naming the key is
  the channel that reaches a child.

## Review

Pending — step 5 not run yet.

## Blockers

None.

## Where to look

- `.agents/docs/feedback.md:When the consumer is the detector` — the five
  steps this mechanizes.
- `joharness.sh:review_mode` — the off/on shape copied here.
