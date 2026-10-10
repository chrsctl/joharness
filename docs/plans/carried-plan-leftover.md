---
plan: carried-plan-leftover
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, shared:.agents/docs/orchestrated.md
---

## Goal

`dispatch_branch_plans` prints a plan another branch carried to the base and
retired as a live "plan on a branch". Print it as a leftover instead: the
human closes the pull request and deletes the branch. Evidence: see
`.agents/docs/orchestrated.md`, "A plan the queue cannot see".

## Scope

- `joharness.sh` — in `dispatch_branch_plans`, when the plan path is absent on
  the base, test `git log --full-history -m --diff-filter=D --format=%h -1
  refs/remotes/origin/<base> -- <plan>`; non-empty = the base added and
  retired it, AND that retire is not an ancestor of the branch's merge base. Do not print it in the plans-on-a-branch block; print a
  leftover row worded like `dispatch_retired_edges` (its item landed and
  retired by another branch; commits nothing; the human closes the pull
  request and deletes the branch), counted as NOT in flight.
- Selftest — a fixture: branch adds plan P; base later adds and deletes P on a
  second branch merged by merge commit. Must FAIL without the change.
- `.agents/docs/orchestrated.md` — drop "until `carried-plan-leftover` lands".

## Out of scope

- `dispatch_retired_edges`: a branch that only adds is not an edge.
- Any rule that auto-closes pull requests.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- The new fixture fails with the change reverted.
- Ships to consumers: a consumer's `./joharness.sh dispatch` after sync prints the carried plan's branch as a leftover, not in the plans-on-a-branch block.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the `cat-file -e` base check.
- `joharness.sh:dispatch_retired_edges` — leftover wording, and the skip.

## Traps

- A later, different plan with a retired stem's name must still show: require the retire commit to postdate the branch's merge base with the base.
- Plain `--diff-filter=D` misses the retire; `--full-history -m` is required.
- Do not edit `joharness.conf`, `.claude/settings.json`, `.github`.
