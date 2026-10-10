---
workstream: plan-identity-is-its-filename
status: review
branch: claude/plan-identity-is-its-filename
pr: none
plan: plan-identity-is-its-filename
issue: none
session: https://claude.ai/code/session_012bxo4eAEpDFu4EzUFuRBCj
agent: opus
updated: 2026-10-10
next: Retire this file, open PR, merge, message @parent
---

## Goal

Settle `docs/research/plan-identity-is-its-filename.md` (a consumer report
from `chrsctl/gx`: two plan files for one defect), graduate the answer into
`.agents/docs/plans/README.md`, delete the node.

## Decisions

- Graduate as a section in plans/README.md, not a new key or dispatch dedupe: the node itself says a key is unproven (would two sessions write one value?) and dispatch reconciles too late.
- Re-checked on this head: TEMPLATE grew `issue:` since the node's 832f5fdd; clerk skips a PLANNED issue, so that is a planning-time dedupe for issue-born plans only. Recorded in the section.

## Rejected

- Keeping the node's grep `cascade` over `.agents/docs/`: the graduated text itself would contain the word and falsify its own claim; narrowed to `.claude/commands/`.

## Review

- r1: (verifier) tree check credited to `dispatch_curate_due`; it is `cmd_curate`'s DECLUTTER (`grep -n 'no path in its scope' joharness.sh` -> :8437 in cmd_curate at :8290), curate_due only gates cadence. Node carried same error. (fixed)
- r2: (verifier) "dispatch reads main" stale: `dispatch_branch_plans` (#297 fix) shows pushed branch plans; #297 paragraph dropped. (fixed — added as a reconciler bullet, visibility not pairing, #297 inference restored)
- r3: (verifier) search rule grepped workstream files, but gx duplicate sat in a branch's docs/plans/; pre-push gap unstated. (fixed)
- r4: (verifier) "only the queue's own routes file a plan" contradicts Loop step 2 direct ask, /plan, manage.md follow-up plans. (fixed — rule now names the cascade shape only, sanctioned routes listed as sanctioned)
- r5: (verifier) "issue: the one key two plans can share" false; requirement/needs/scope shared too. (fixed — "the one key naming where the work came from")
- r6: (verifier) cap counterfactual stated as fact; node marked it inference. (fixed)
- r7: (verifier) `docs/research/a-requirement-no-plan-can-serve.md` "Neighbours" line describes this node as keyed on scope paths. (wontfix — open node another session may hold; named in PR body for its owner)
- r8: (verifier) "re-checked" stamp carried no command. (fixed — section now carries the two grep commands)

## Blockers

None.

## Where to look

- `docs/research/plan-identity-is-its-filename.md` — the node, findings already written.
- `.agents/harness/queue-context.sh:stem`, `wave_split_hit` — identity and the one reconciler.
