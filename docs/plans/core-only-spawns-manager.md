---
plan: core-only-spawns-manager
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/queue-context.sh, .agents/harness/selftest/dispatch.sh, .agents/harness/selftest/dispatch-order.sh, shared:.agents/harness/selftest/dispatch-park.sh, .agents/harness/selftest/queue-context-core-only.sh, .agents/harness/selftest/orchestrated.sh, shared:.agents/docs/orchestrated.md, .agents/docs/plans.md, .agents/docs/manage-reference.md, .agents/docs/orchestrate-reference.md, shared:.claude/commands/orchestrate.md, .claude/commands/manage.md
---

## Goal

A human should wait only for a pull request to be merged, never for an implementation. The requester, 2026-10-28: *"We should only wait for the PRs to be merged not the implementation."*

Today, a plan whose `scope:` holds a core path (`joharness.conf`, `.claude/settings.json`, `.github`) is `CORE ONLY`:
- dispatch ranks it out of the free list;
- it prints it under `NOT YOURS — … only a human builds it, by hand. Never spawn a manager on these`;
- it reads `DRAINED` with a wait line on the human.

So the human must write the code. In the consumer chrsctl/gx, `compose-ci-check` and `e2e-ci-check` waited 14 days that way. An agent then built both in one `human/` pull request in under an hour, once a human asked for it (chrsctl/gx#1041).

The parts that let a manager do this already exist:
- a manager already opens a `human/<stem>` pull request labelled `human-review` for a core edit (`manage-reference.md` § Human remainder);
- it already blocks `core path: waiting on #<N>`;
- dispatch already RESUMEs it once that pull request merges (`PARKED #<n> RESUME — #<n> merged`).

The one missing piece is that dispatch never spawns the manager.

## Scope

- `.agents/harness/queue-context.sh`: the hook already ranks a `CORE ONLY` plan after every free plan (`rank + 2`), but leaves it out of the free set, so it gets no `wave`, `WAIT` or `in flight: … overlaps` line. An unclaimed, unblocked `CORE ONLY` plan joins the free set after every plan ranked free, so overlaps hold and wave it like any other. The edge line stops naming `CORE ONLY`.
- `joharness.sh` (dispatch):
  - A `CORE ONLY` plan becomes spawnable. It is ranked after every free plan, so it never takes a slot ahead of work that needs no human. Its spawn row says the core edit goes in a `human/<stem>` pull request a human merges.
  - Replace the `NOT YOURS — CORE ONLY` block, and the wait line `<n> plan(s) wait on a human core edit`. The new wait line counts the pull requests named by claims parked at `core path: waiting on #<N>` whose merge the base does not carry yet (git cannot tell open from closed; a closed one stays listed until the human answers the block): `<n> pull request(s) wait on a human merge: #<N> …`. This is read from git and the claims (as RESUME is today), never from the GitHub API.
  - `DRAINED` stays the verdict when nothing is left but claims parked on a human merge.
- `.agents/harness/selftest/dispatch.sh`, `.agents/harness/selftest/dispatch-order.sh`, `.agents/harness/selftest/dispatch-park.sh`, `.agents/harness/selftest/queue-context-core-only.sh`:
  - A `CORE ONLY` plan is spawned when slots are free and no free plan is waiting.
  - It ranks after a free plan.
  - Its claim parked `core path: waiting on #N` holds no slot and appears on the new wait line.
  - A merge of `#N` RESUMEs it, using the existing mechanism, unchanged.
- `.claude/commands/manage.md` / `.agents/docs/manage-reference.md` § Human remainder. A manager on a `CORE ONLY` plan:
  1. builds the non-core part on its own branch;
  2. builds the core edit in the `human/<stem>` worktree, with `ci` green there;
  3. opens and labels that pull request.

  If its Acceptance needs the core edit merged (a CI job that must run green, a hook that must be registered), it blocks `core path: waiting on #<N>`. Once resumed, it verifies and retires as normal. The retire stays on the manager's own branch: the `human/` pull request carries ONLY the core-path edit (§ Human remainder step 2).
- `.claude/commands/orchestrate.md` / `.agents/docs/orchestrate-reference.md`:
  - remove "Never spawn on it" (`orchestrate-reference.md` § Core wait) and the lead drop on `CORE ONLY` (`orchestrate.md`, `orchestrate-reference.md`): the stem now has a manager;
  - the orchestrator pushes the new wait line's pull request links to the human once per run, so the human's only action is a merge.
- `.agents/docs/orchestrated.md` (the `dispatch` wait line table row, Bounds including the de-rank rationale and "A `CORE ONLY` plan is a wait on a human", The one stop) and `.agents/docs/plans.md` ("A core path in `scope:`"): rewrite to "the agent builds it, a human merges it". The human's split-by-hand move goes.

## Assumptions

- A1: A manager can already open a labelled `human/<stem>` PR for a core edit — evidence: `.agents/docs/manage-reference.md:Human remainder` — confidence: high
- A2: `core path: waiting on #<N>` blocks hold no slot and RESUME on merge — evidence: `.agents/docs/orchestrate-reference.md:Resume` (`PARKED #<n> RESUME — #<n> merged`) — confidence: high
- A3: The core-path guarantee is CODEOWNERS plus branch protection, not dispatch's ranking, so spawning does not weaken it — evidence: `.agents/docs/orchestrated.md` Bounds ("`.github/CODEOWNERS` … is the guarantee") — confidence: high
- A4: The Stop guard still flags a core-path change on the manager's branch — evidence: `.agents/harness/handover-guard.sh` reads `./joharness.sh protocol-paths` — confidence: high. (The queue hook only marks; it refuses nothing.)

## Out of scope

- Letting any session merge a core-path pull request. The human still merges, the `human-review` label stays, and only a human removes it.
- Changing the core-path list.
- Reading GitHub from harness commands (git only, as today).
- `ci`'s refusal of an added plan whose `scope:` is core paths ONLY (`joharness.sh:lint_plans_in_diff`, `.claude/commands/clerk.md`): follow-up plan `core-only-scope-lint`.

## Acceptance

- `bash .agents/harness/selftest.sh` prints `0 failed`, with these cases among the passes (fails before this change):
  - `dispatch.sh`: a lone partly-core plan, 4 slots — its spawn row carries `CORE ONLY — build it`, the verdict reads `NOT DRAINED — 1 free item(s) now`, and no `NOT YOURS` line prints.
  - `dispatch-order.sh`: one free plan and one `CORE ONLY` plan, 2 slots — both under `spawn`, the free plan's row first.
  - `dispatch.sh`: a `CORE ONLY` plan whose scope overlaps a claimed plan reads `HOLD — overlaps`.
  - `dispatch-park.sh`: a claim parked `core path: waiting on #77` holds no slot and prints `1 pull request(s) wait on a human merge: #77 (own-w)`; once `#77` merges, the line is gone and the RESUME row prints.
  - `queue-context-core-only.sh`: a lone `CORE ONLY` plan is free work in the hook (no `Edge reached` line).
- `./joharness.sh ci` prints `ci: pass`; `./joharness.sh verify` prints `0 failed`.
- Consumer-side, after its next sync: `./joharness.sh dispatch` in a consumer lists each unclaimed `CORE ONLY` plan under `spawn` with `CORE ONLY — build it`, and prints no `NOT YOURS` block.

## Where to look

- `joharness.sh:drain_core_only` — the `NOT YOURS — CORE ONLY` block's source.
- `joharness.sh:dispatch` — `Free = neither claimed, blocked nor CORE ONLY` (the spawn filter) and the wait line.
- `.agents/docs/manage-reference.md:Human remainder` — the `human/<stem>` PR procedure the manager reuses.
- `.agents/docs/orchestrate-reference.md:Resume` — `core path: waiting on #<N>` and its RESUME.

## Traps

- **The gate stays.** An agent builds a core edit only on a `human/<stem>` branch from a separate worktree, labelled `human-review`. It never merges it, never relabels it, and never pushes to it again unless the human asks.
- **Fail closed.** A claim whose `#<N>` cannot be read is not RESUMEd (existing UNREADABLE).
- **One wait, one push.** The orchestrator tells the human about each pull request once per run, not once per pass.
