---
workstream: harness-review-step
status: in-progress
branch: claude/harness-review-step-xrnmu7
pr: none
plan: none
session: https://claude.ai/code/session_01B5Pq9Ps7b9PSzJ3Hf9MjT7
agent: opus
updated: 2026-08-24
next: Implement JOHARNESS_REVIEW knob + `joharness.sh review` + ci gate, then selftest coverage
---

## Goal

Human: research, then add a review step to the harness, off by default,
enabled by config. Harness already ORDERS review (Loop step 5, review depth
by tier) but nothing checks it happened — instruction only. Gap: the record
lives in the workstream file's `## Review`, and only a human reading the
hook output ever notices it is empty. Opt-in gate closes it.

## Decisions

- Knob `JOHARNESS_REVIEW` in `joharness.conf`, values `off` (default) /
  `on`. Off = zero cost, zero output, `ci` byte-identical to today. Same
  doctrine as `JOHARNESS_ENV_SETUP=lazy`.
- Gate lives in `ci`, not in a Stop hook. Stop-hook enforcement of protocol
  discipline was weighed and rejected once already (harness-review
  workstream, PR #6): blocking Stop hooks need loop guards and JSON. `ci` is
  the gate a session cannot skip — same argument the churn ceiling and graph
  lint already rest on.
- Gate checks the RECORD, not the finding count. Findings-per-round is no
  signal (agent-selection.md, review churn: "false both ways"). A clean pass
  records one line saying so. Enforcing recording is honest; enforcing
  findings would teach sessions to invent them.
- `./joharness.sh review` runs with the knob off too — recipe on demand
  costs nothing and a session may want it. Knob decides only whether `ci`
  gates.
- Depth recipe read from the workstream `agent:` tier, falling back to the
  claimed plan's tier, then sonnet. Same tier the review-depth rule already
  keys on; no second vocabulary.

## Rejected

- Stop-hook enforcement — see Decisions; rejected before, nothing new
  changes it.
- Counting findings, or requiring N>0 real findings. Review churn rule says
  finding counts carry no signal. Gate would reward theatre.
- Gating on the diff alone (no workstream file needed). Copy/sync tasks and
  plan-queue PRs carry NO workstream file by protocol ("When NOT to write
  one"), so a diff-only gate reds exactly the branches the protocol tells to
  have no record. Gate prints the hole instead of faking coverage.

## Review

(pending — edge review runs before PR)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_review` — the step. Reads the working tree, not a ref:
  `ci` judges what this branch is about to push.
- `joharness.sh:cmd_ci` — gate wired after churn, only when enabled.
