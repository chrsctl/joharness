---
plan: block-names-awaited-pr
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 596
scope: joharness.sh, shared:.claude/commands/manage.md, .agents/harness/selftest/block-resume.sh
---

## Goal

A manager blocked on `core path:` waiting for a `human/<stem>` pull request
is never respawned, and nothing names that PR's merge as the unblock signal
(issue #596: one human relay message per blocked item). A `core path:` block
may name the PR it waits on; `dispatch` lists the item resumable once git
shows that PR merged.

## Scope

- `joharness.sh` — `block_reason_ok` keeps accepting `core path:`; `cmd_dispatch` parses `waiting on #<N>` in a blocked `next:`, and when `origin/<base>` carries a `Merge pull request #<N> from` commit prints the item as `RESUME — #<N> merged` (one slot, as the other resume rows).
- `.claude/commands/manage.md` — §3: a `core path:` block names the awaited PR as `core path: waiting on #<N>: <question>`.
- `.agents/harness/selftest/block-resume.sh` (new) — case: blocked item with merged PR resumes; open PR does not. Fails without the change.

## Assumptions

- A1: no code today reads a blocking PR's merge — evidence: `grep -n "waiting on #" joharness.sh .claude/commands/manage.md` prints nothing — confidence: high
- A2: parked-defect `RESUME` rows in `cmd_dispatch` give the resume mechanism to reuse — evidence: `joharness.sh:cmd_dispatch` "PARKED #... RESUME" — confidence: medium
- A3: "A blocked item is never respawned" must keep holding for every block without a merged awaited PR — evidence: `.claude/commands/manage.md` §3 — confidence: high

## Out of scope

- Other block reasons; an unmerged or closed PR (no resume).
- Merging, labelling or approving the human PR: no session does.
- Any GitHub API read in a harness command.

## Acceptance

- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed.
- New selftest fails with the `cmd_dispatch` change reverted.

## Where to look

- `joharness.sh:block_reason_ok`, `joharness.sh:cmd_dispatch` — block grammar and resume rows.
- `.claude/commands/manage.md` §3 — block text.

## Traps

- `joharness.sh` is not a core path; `.github` and the conf are: touch neither.
- Never wake a block silently: the resume row names the PR.
- `manage.md` and `joharness.sh` may overlap other plans: reconcile by merge.
