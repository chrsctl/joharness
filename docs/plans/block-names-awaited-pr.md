---
plan: block-names-awaited-pr
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 596
scope: joharness.sh, .claude/commands/orchestrate.md, .agents/docs/orchestrate-reference.md, shared:.claude/commands/manage.md, .agents/harness/selftest/dispatch.sh
---

## Goal

A manager blocked on `core path:` waiting for a `human/<stem>` pull request
is never respawned, and nothing names that PR's merge as the unblock signal
(issue #596: one human relay message per blocked item). A `core path:` block
may name the PR it waits on; `dispatch` lists the item resumable once git
shows that PR merged.

## Scope

- `joharness.sh` — `block_reason_ok` keeps accepting `core path:`; `cmd_dispatch` parses `waiting on #<N>` in a blocked `next:`, and when `origin/<base>` carries a `Merge pull request #<N> from` commit prints the item as a `PARKED #<N> RESUME — #<N> merged, ...` row, taking one slot as the defect resume rows do.
- `.claude/commands/manage.md` — §3: a `core path:` block names the awaited PR as `core path: waiting on #<N>: <question>`; "a blocked item is never respawned" gains this one exception.
- `.claude/commands/orchestrate.md` — the RESUME and `blocked` rows: a `PARKED #<n> RESUME — #<n> merged` row is the one more respawn exception; every other `blocked` row stays "never respawn".
- `.agents/docs/orchestrate-reference.md` — § Resume: the merged-PR row's own resume `next:` wording, distinct from the defect wording so STUCK/UNPLANNED never count it.
- `.agents/harness/selftest/dispatch.sh` — case: blocked item with merged PR resumes; open PR does not. Fails without the change.

## Assumptions

- A1: no code today reads a blocking PR's merge — evidence: `grep -n "waiting on #" joharness.sh .claude/commands/manage.md` prints nothing — confidence: high
- A2: parked-defect `RESUME` rows in `cmd_dispatch` give the resume mechanism to reuse — evidence: `joharness.sh:cmd_dispatch` "PARKED #... RESUME" — confidence: medium
- A3: "A blocked item is never respawned" must keep holding for every block without a merged awaited PR — evidence: `.claude/commands/manage.md` §3 — confidence: high

## Out of scope

- A new selftest topic file: `selftest.sh` lists topics, so the case goes in the existing `dispatch.sh`.

- Other block reasons; an unmerged or closed PR (no resume).
- Merging, labelling or approving the human PR: no session does.
- Any GitHub API read in a harness command.

## Acceptance

- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed.
- `.agents/harness/selftest.sh | grep 'awaited PR'` — every line `PASS`; with the `cmd_dispatch` change reverted, at least one `FAIL`.
- Consumer side, after sync: `./joharness.sh dispatch` with a `core path: waiting on #<N>` block whose PR merged prints `PARKED #<N> RESUME — #<N> merged`.

## Where to look

- `joharness.sh:block_reason_ok`, `joharness.sh:cmd_dispatch` — block grammar and resume rows (`fx_*` arrays; `dispatch_defect_state` computes the defect rows' state).
- `.agents/docs/orchestrate-reference.md` § Resume — what the orchestrator writes on a RESUME row.
- `.claude/commands/manage.md` §3 — block text.

## Traps

- `human-half-order-and-park-pr` (issue #597) tells a human PR that renames a path to merge WITH or AFTER its code half; this plan covers a code half that waits for a human PR that is independent of it. Do not widen the awaited-PR rule to renames.

- `joharness.sh` is not a core path; `.github` and the conf are: touch neither.
- Never wake a block silently: the resume row names the PR.
- `manage.md` and `joharness.sh` may overlap other plans: reconcile by merge.
