---
workstream: rescope-held-plans
status: in-progress
branch: claude/work-visibility-orchestrator-zvzo62
pr: none
plan: rescope-held-plans
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-10
next: Verifier r1-r3 fixed + recorded, rescope selftest cases green. Ready for human review as a PR (SUPERVISED ONLY: scope is protocol text)
---

## Goal

The orchestrator in `chrsctl/gx` reads 38 held plans and 2 free slots as
DRAINED; the requester asked for a manager mode that decomposes the held
work. Plan: `docs/plans/rescope-held-plans.md` — same-session plan, on this
branch, retired with this file.

## Decisions

- Not decomposition: the held plans are decomposed. Declarations are wrong —
  registries every plan appends to are declared exclusive, and the hook's
  asymmetry (one side's `shared:` voids nothing) holds the careful plans
  too. So the new kind edits `scope:` lines and nothing else.
- Rescope manager holds no slot, like a reporter; bounded by the ledger
  (`rescoped=<key>`), one per holder-set per orchestrator run.
- The holder's plan is edited on `main` while its manager holds it. Cost: a
  modify/delete conflict at that manager's step 7, resolved by keeping the
  delete — one line in `manage.md` section 4.
- Identity of a rescope branch: `workstream: rescope-<key>` and `plan: none`
  in its workstream file. `plan:` cannot name a plan that never existed
  (`joharness.sh:lint_graph`), and a synthetic plan file would be a session
  writing queue work from a detector.

## Rejected

- A lint on bare `docs/adr` / `docs/phases` in `scope:` — which directory is
  a registry is consumer knowledge.
- A slot for the rescope manager — would need a claim `dispatch` can count,
  and every claim shape is a plan on `main`.

## Review

Depth: opus tier, adversarial + one independent reader (verifier), on the
full diff. `./joharness.sh ci` green (`ci: pass`, 2026-09-10); harness
selftest 1787 passed 0 failed before the verifier's fixes, re-run after.

- r1: (verifier, correctness) `n_rescope_inflight` was keyed to the current
  holder set, so a rescope branch on a STALE key (the set drifts when a new
  manager claims an overlapping plan, or a co-holder merges, mid-rescope) was
  uncounted AND its row suppressed by the `n_rescope_inflight>0` display gate
  — dispatch printed `in flight: none` and OVERLAP-BOUND spawn, so the
  orchestrator would spawn a SECOND rescope onto the new key while the first
  ran, two managers colliding on `scope:`. (fixed: the active count ignores
  the key — any active rescope holds off a spawn; only SETTLED stays
  key-specific. A stale-key case pins it.)
- r2: (verifier, reporting) a `done`/`blocked` rescope set `rescope_settled`
  but not the active count, so the verdict said "see rescope block" while the
  block showed `in flight: none` — the cross-reference resolved to nothing.
  (fixed: every rescope branch is listed regardless of key/status; the block
  header is `rescope branch(es) in flight`; a case asserts the done row is
  shown.)
- r3: (verifier, reporting) the per-path "N held" and `n_rescope_holders`
  counted holdmap LINES (one per held-plan/holder pair), so a plan held by
  two branches double-counted against `n_hold`'s distinct-plan count.
  (fixed: paths counted by distinct held plan via `sort -u` on stem+path;
  reasoned, not reproduced — the fixture surfaced one holder per plan.)
- note: (verifier, housekeeping) a `done`-genuine rescope leaves an unmerged
  `rescope-<key>` branch standing; dispatch re-derives `settled` from it
  statelessly every pass, robust across ledger loss, but nothing retires the
  branch once the holders merge. (no change — out of correctness scope; the
  human deletes the branch, same as any leftover.)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — verdict ladder, `holdmap`.
- `.agents/harness/selftest/dispatch.sh` — HOLD fixtures.
