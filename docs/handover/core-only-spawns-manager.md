---
workstream: core-only-spawns-manager
status: in-progress
branch: claude/core-only-spawns-manager
pr: none
plan: core-only-spawns-manager
issue: none
session: https://claude.ai/code/session_01J1YMK5BpmpDmvYP7cKXntH
agent: opus
updated: 2026-10-28
next: verify, reconcile origin/main, retire commit, PR, finish, merge
---

## Goal

"We should only wait for the PRs to be merged not the implementation." A
CORE ONLY plan gets a manager; the human only merges its `human/<stem>` PR.

## Decisions

- A1: confirmed — `manage-reference.md` § Human remainder: worktree, `ci`, PR, `human-review` label.
- A2: confirmed — `joharness.sh:cmd_dispatch` blocked claims raise `n_blocked`; `awaited_pr_merged` gives `PARKED #<n> RESUME — #<n> merged`.
- A3: confirmed — `.github/CODEOWNERS` header: "This file is the GUARANTEE".
- A4: refuted as written — the queue hook marks, refuses nothing; the Stop guard (`handover-guard.sh`) flags any core-path diff. Plan reworded.
- Retire never rides in the `human/` PR: § Human remainder step 2 keeps it to the core edit only.
- Wait line reads claims parked `core path: waiting on #<N>` whose merge the base lacks (git cannot see open/closed); printed under every verdict, not only DRAINED: a human merge is news whatever else runs. Ledger key `corewait=` keeps its name; its entries are `<stem>#<N>` so a re-park on a new PR pushes again.
- The hook puts unclaimed, unblocked CORE ONLY plans in its free set AFTER every rank-free plan, so overlap holds and waves apply to them.
- `ci`'s refusal of a core-paths-only added plan stays here; follow-up plan `core-only-scope-lint` in this PR.

## Rejected

None yet.

## Review

- r1: (plan-checker) a spawned CORE ONLY plan gets no wave/HOLD: the hook leaves it out of its free set — queue-context.sh added to scope (fixed)
- r2: (plan-checker) ci still reds a core-paths-only added plan — out of scope, follow-up plan core-only-scope-lint (fixed)
- r3: (plan-checker) retire in the human/ PR contradicts § Human remainder step 2 — retire stays on the manager branch (fixed)
- r4: (plan-checker) defect-park-calls-clerk edits the same dispatch lines (wontfix: both declare shared:, reconcile at step 7)
- r5: (plan-checker) acceptance fixture item not runnable — rewritten as named selftest cases (fixed)
- r6: (plan-checker) consumer-side acceptance not runnable here — reworded to the dispatch line a consumer reads after sync (fixed)
- r7: (plan-checker) acceptance item 1 had no expected output and wrong claim — rewritten (fixed)
- r8: (plan-checker) open PRs cannot be read from git — wait line reads unmerged parked claims (fixed)
- r9: (plan-checker) A4 half false — reworded (fixed)
- r10: (plan-checker) orchestrated.md rewrite list incomplete — table row, de-rank rationale, The one stop added (fixed)
- r11: (plan-checker) lead drop on CORE ONLY not addressed — removed with the never-spawn rule (fixed)
- r12: (plan-checker) "never spawning on it" quoted from the wrong file — corrected (fixed)
- r13: (plan-checker) chrsctl/gx history unverified (no change)
- r14: (verifier) bulk10 case asserted a wave number that depends on two commits sharing a second; ci went red on one run — asserts the row without the number (fixed)
- r15: (verifier) queue-context.sh unread-boundary text still said a core-path plan is one no session can finish (fixed)
- r16: (verifier) wait line listed a PR already merged before the block, or a block of unknown age — now only a block of known age whose PR the base never merged; selftest #79 case (fixed)
- r17: (verifier) corewait=<stem> never re-pushes a re-park on a new PR in the same run — key is now corewait=<stem>#<N> (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:drain_core_only` — the block being replaced.
