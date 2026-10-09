---
plan: guard-quiet-on-empty-branch
urgency: normal
agent: sonnet
effort: low
needs: none
requirement: none
scope: shared:.agents/harness/handover-guard.sh, shared:.agents/harness/selftest/handover-guard.sh
---

## Goal

Issue #296. An orchestrator's branch has zero commits ahead of the base
and a clean tree. It holds no work. `handover-guard.sh` still blocks every
one of its stops with `branch has no upstream — git push -u origin HEAD`.
Measured in a consumer: every turn from 19:34Z to 23:36Z, each needing an
extra reply. The fact exists for work "invisible to every other session".
A branch with nothing on it has nothing to make invisible. A warning that
is wrong every time for one role teaches the reflex reply, and that reply
also passes the real case.

## Scope

- `.agents/harness/handover-guard.sh`, the unpushed-commits section, the
  `elif [ "$branch" != "$BASE_BRANCH" ]` arm. Before `add_fact`, count
  commits ahead of the base:
  `git rev-list --count "origin/${BASE_BRANCH}..HEAD"`. Add the fact only
  when the count is greater than 0. If the count cannot be read (no
  `origin/<base>` ref), keep today's behaviour: add the fact. A guard that
  cannot read the base must not go quiet.
- `.agents/harness/selftest/handover-guard.sh` — one case: a new branch cut
  from the base, no commit, clean tree, never pushed → the guard prints
  nothing about `no upstream`. The existing case `"never-pushed branch told
  to push"` (a branch WITH a commit) must still pass unchanged.

## Out of scope

- The uncommitted-changes fact. It already covers a dirty tree on its own.
- The workstream-file fact. It already fires only when the branch changes
  something.
- Any orchestrator-specific branch (role detection). The rule is "no
  commits, nothing to push", whoever holds the branch.

## Acceptance

- `bash .agents/harness/selftest.sh` → `0 failed`, and its `handover-guard` lines all pass. The topic files are "Not runnable alone" — never run one by itself
  included.
- Revert the guard change. The new case must FAIL. Restore it.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `.agents/harness/` reaches consumers. The consumer check is an
  orchestrator session in a consumer ending a turn on an untouched branch,
  with no Stop block.

## Where to look

- `.agents/harness/handover-guard.sh` — the `remote_ref` / `elif` block
  that adds `branch has no upstream`. The `ahead` count two lines above is
  the shape to copy.
- `.agents/harness/selftest/handover-guard.sh` — the `sgnew` fixture,
  `"never-pushed branch told to push"`.

## Traps

- `orchestrated-only` also edits both files (its scope lists them). Both
  plans mark them `shared:` where this plan does. Reconcile at step 7.
- `BASE_BRANCH` is the guard's own variable. Do not hardcode `main`.
- A failed `rev-list` must not read as `0`. Use the guard's existing
  error style, and test the no-base case by reading, not by assuming.
