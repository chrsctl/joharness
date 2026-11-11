---
plan: starved-resumes-unasked
urgency: normal
agent: opus
effort: high
needs: starved-counts-green-runs
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/dispatch-order.sh, .claude/commands/manager.md, .agents/docs/manager-reference.md, shared:.agents/docs/consumer-repos.md
---

## Goal

A STARVED head (manager.md §4) is green and drafted; the base simply moves
faster than `finish`. Today it blocks `conflict: base outran finish`, which
like every non-`defect:` block posts `decision needed:` and labels
`human-review` (manager-reference.md § Question), and dispatch counts it
blocked, never respawns. Twice in chrsctl/gx on 2026-11-11 the human removed
the label and the answer was "catch up and merge". Make the first STARVED
blocks resume without a human, and ask only when the bound is spent.
Settled in `.agents/docs/consumer-repos.md` § Local checks (research
`scoped-local-check-certificate`).

## Scope

- `.claude/commands/manager.md` §3 and §4, `.agents/docs/manager-reference.md`
  § Question. A STARVED block whose resume count (below) is under the bound:
  draft the pull request (`drafted: <N>`), post no question, apply no
  `human-review`, `next:` = `conflict: base outran finish: resume <k>/<max>:
  <the starved-counts-green-runs text>`. At the bound: the question and the
  label, with `starved-counts-green-runs`' human choices.
- `joharness.sh` dispatch: a claim blocked `conflict: base outran finish:
  resume <k>/<max>` with k < max, whose base (`origin/main`) has a commit
  newer than the block commit, is offered for respawn like a `core path:
  waiting on #<N>` claim on its merge, not counted blocked. `block_reason_ok`
  unchanged (`conflict:` stays valid).
- `.agents/harness/selftest/dispatch-order.sh`: a STARVED claim under the
  bound with a moved base is offered; with an unmoved base it is not; at the
  bound it is counted blocked.
- `.agents/docs/consumer-repos.md` § Local checks: one line on the resume.

## Assumptions

- A1: Dispatch treats every `conflict:` block as a human's block today. —
  evidence: `joharness.sh:block_reason_ok`, the `n_blocked` "report to the
  human, never respawn" line in dispatch — confidence: high.
- A2: `starved-counts-green-runs` has landed and fixed the STARVED `next:`
  text and the OUTRUN count; this plan builds on that text. — evidence:
  `needs:` edge — confidence: high.
- A3: The bound defaults to 2 (`JOHARNESS_RESPAWN_LIMIT`'s default) unless
  the implementer finds a reason; a new knob lives in `joharness.sh`'s knob
  table, never `joharness.conf`. — evidence: `joharness.sh` knob table
  (`JOHARNESS_RESPAWN_LIMIT|2|dispatch`) — confidence: medium.

## Out of scope

- How STARVED is counted (plan `starved-counts-green-runs`).
- The certificate and scoped `local-check` (plan `local-check-scoped-green`).
- CATCH-UP's conditions or bound.
- Any core path (`./joharness.sh protocol-paths`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`, the new dispatch-order cases in its
  count.
- The new "offered" case fails on `origin/main` and passes on the branch;
  both runs in `## Review`.
- `grep -n 'resume <k>/<max>' .claude/commands/manager.md` — a hit in §4.
- Consumer side, after the sync: `./joharness.sh dispatch` in a consumer
  with a claim blocked `conflict: base outran finish: resume 1/2: ...` and
  a base commit newer than the block lists that claim as offered, not under
  `manager(s) blocked`.

## Where to look

- `joharness.sh:block_reason_ok` — the reason list.
- `joharness.sh:dispatch_block_ts` — block commit time.
- `.agents/harness/selftest/dispatch-order.sh` — the `core path: waiting on`
  respawn cases to mirror.
- `.claude/commands/manager.md` — §4, "Behind again at merge?".

## Traps

- Never skip, disable or quarantine a test to get green.
- A test for the fix must FAIL without it.
- Respawn must stay bounded: an unbounded resume loops forever on a base
  that never stills.
- Glossary spellings: `ci` fails on the others.
