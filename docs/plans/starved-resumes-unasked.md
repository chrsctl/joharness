---
plan: starved-resumes-unasked
urgency: normal
agent: opus
effort: high
needs: starved-counts-green-runs
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/dispatch-park.sh, .agents/harness/selftest.sh, .claude/commands/manager.md, .agents/docs/manager-reference.md, .agents/docs/orchestrator-reference.md, .agents/docs/orchestrated.md, shared:.agents/docs/consumer-repos.md
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
  <the starved-counts-green-runs text>`. Dispatch counts k itself, never
  from the manager's text: the number of commits on the claim's branch
  whose workstream file went to `status: blocked` with `next:` starting
  `conflict: base outran finish` (git history, across orchestrator runs).
  A new knob `JOHARNESS_STARVED_RESUMES` (default 2) in `joharness.sh`'s
  knob table bounds it; never `JOHARNESS_RESPAWN_LIMIT`, which is per run.
  At the bound: the question and the
  label, with `starved-counts-green-runs`' human choices.
- `joharness.sh` dispatch: a claim blocked `conflict: base outran finish:
  resume <k>/<max>` with k < max, whose base (`origin/main`) has a commit
  newer than the block commit, is offered for respawn like a `core path:
  waiting on #<N>` claim on its merge, not counted blocked. `block_reason_ok`
  unchanged (`conflict:` stays valid).
- `.agents/harness/selftest/dispatch-park.sh`: a STARVED claim under the
  bound with a moved base is offered; with an unmoved base it is not; at the
  bound it is counted blocked.
- `.agents/docs/consumer-repos.md` § Local checks: one line on the resume.
- k is this block's number on the claim, the current block included (1 for
  the first); offered while k <= max, so `JOHARNESS_STARVED_RESUMES` is the
  number of resumes. The manager counts the same history with one `git log`
  command (manager-reference.md § Starved); dispatch reads only the
  `resume <k>/<max>` form from `next:`, never its numbers.
- The row the orchestrator acts on: `PARKED #<n> RESUME — STARVED`, #<n> the
  block's `drafted:` pull request, and its § Resume paragraph in
  `.agents/docs/orchestrator-reference.md`. A dispatch knob: its row in the
  `.agents/docs/orchestrated.md` table, its name in the selftest's unset list.
- manager-reference.md § Starved carries the new `next:` form (the prefix
  once), § Question its exception.

## Assumptions

- A1: Dispatch treats every `conflict:` block as a human's block today. —
  evidence: `joharness.sh:block_reason_ok`, the `n_blocked` "report to the
  human, never respawn" line in dispatch — confidence: high.
- A2: `starved-counts-green-runs` has landed and fixed the STARVED `next:`
  text and the OUTRUN count; this plan builds on that text. — evidence:
  `needs:` edge — confidence: high.
- A3: The bound must be counted from git, across orchestrator runs: a
  manager-written count can be reset (gx's relayed answer reset it), and
  `JOHARNESS_RESPAWN_LIMIT` is per run (`joharness.sh` knob table). The
  new knob lives in the knob table, never `joharness.conf`. — evidence:
  `joharness.sh` knob table (`JOHARNESS_RESPAWN_LIMIT|2|dispatch`) —
  confidence: high.

## Out of scope

- How STARVED is counted (plan `starved-counts-green-runs`).
- The certificate and scoped `local-check` (plan `local-check-scoped-green`).
- CATCH-UP's conditions or bound.
- Any core path (`./joharness.sh protocol-paths`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`; its selftest runs the new
  dispatch-park cases (`verify` runs the layer smoke test, not the selftest).
- `./joharness.sh verify` — `0 failed`.
- The case "STARVED under the bound, base moved: offered as a RESUME, no
  human" fails on `origin/main`'s `joharness.sh` and passes on the branch;
  both runs in `## Review`.
- dispatch-park cases: under the bound, base moved = a `PARKED #<n> RESUME —
  STARVED` row; base unmoved = `PARKED #<n> STARVED … waits for the base to
  move`, no RESUME; past the bound (next: still saying 1/2) = `BLOCKED: the
  human's`; the at-bound form (no `resume`) = never a RESUME.
- `grep -n 'resume <k>/<max>' .claude/commands/manager.md` — a hit in §4.
- Consumer side, after the sync: `./joharness.sh dispatch` in a consumer with
  a claim blocked `conflict: base outran finish: resume 1/2: ...`, `drafted:
  <n>`, and a base commit newer than the block prints `PARKED #<n> RESUME —
  STARVED`, not the claim under `manager(s) blocked`.

## Where to look

- `joharness.sh:block_reason_ok` — the reason list.
- `joharness.sh:dispatch_block_ts` — block commit time.
- `.agents/harness/selftest/dispatch-park.sh` — the `core path: waiting on`
  respawn cases to mirror.
- `.claude/commands/manager.md` — §4, "Behind again at merge?".

## Traps

- Never skip, disable or quarantine a test to get green.
- A test for the fix must FAIL without it.
- Respawn must stay bounded: an unbounded resume loops forever on a base
  that never stills.
- Glossary spellings: `ci` fails on the others.
