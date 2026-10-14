---
plan: genuine-rescope-is-not-edge-work
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 492
scope: .agents/harness/handover-context.sh, .agents/harness/selftest/handover-context-rank.sh
---

## Goal

A surveyor that finds the holds GENUINE ends as `.claude/commands/manage.md`
(rescope) tells it to: `status: done`, `pr: none`, `plan: none`, no pull
request, exit. Nothing on that branch is ever merged. The session-start hook
still ranks it as edge work (`status done and unmerged`), `dispatch` passes
that line on as `edge work`, and the orchestrator nudges the idle surveyor
every pass; each reply moves `updated_at`, so the nudge record is dropped and
the next pass nudges again. Seen 2026-10-14 on
`origin/rescope-dispatch-names-the-core-wait` (issue #492): four orchestrator
sessions, more than six nudges, no progress possible. Fix it by the issue's
option 1: such a claim is finished, not edge work. `dispatch`'s rescope block
already counts a `done` rescope as settled (`dispatch_rescope_branches`, read
in `cmd_dispatch`'s `rescope_settled` loop), so no new surveyor spawns for its
key; that must stay true.

## Scope

- `.agents/harness/handover-context.sh` — a workstream file whose
  `workstream:` starts `rescope-`, with `plan: none`, `status: done` and no
  `pr:` (empty or `none`) is NOT edge work: no `EDGE:` line, never the
  `FINISH BEFORE STARTING` lead. It still prints in the branch list, with a
  line saying it is a finished rescope and holds nothing (wording yours).
  Every other `status: done` entry keeps rank 0 exactly as today.
- `.agents/harness/selftest/handover-context-rank.sh` — the cases below.

## Out of scope

- Any new status word, or changes to `manage.md`'s genuine path (option 2 of
  the issue: rejected — option 1 needs no new vocabulary and keeps the
  surveyor's record on its branch).
- `janitor` and `HANDOVER_STALE_SECONDS`: the 144h window stays as it is.
- `cmd_dispatch` in `joharness.sh` and `.claude/commands/orchestrate.md`:
  once the hook stops printing the lead, `dispatch` prints no edge row and
  the orchestrator's "dispatch no longer lists it" row drops the ledger entry.
  Touch them only if a selftest proves that reading wrong, and then say so in
  the pull request body.
- Deleting `rescope-dispatch-names-the-core-wait`: human-only
  (`git push --delete`).
- A `rescope-*` claim with `pr:` set, or `status: review`: still edge work.

## Acceptance

- `./joharness.sh selftest` (or the selftest entry `ci`/`verify` runs for the
  topic `handover-context-rank`) — new assertions in
  `handover-context-rank.sh`, all passing:
  - a branch carrying `docs/handover/rescope-k.md` with `workstream:
    rescope-k`, `plan: none`, `status: done`, `pr: none` produces no
    `FINISH BEFORE STARTING` line naming it and no `EDGE:` line under it;
  - the same file with `status: in-progress` still lists as in flight (not
    hidden, rank unchanged from today);
  - a plain (non-rescope) `status: done` branch still leads `FINISH BEFORE
    STARTING` with `status done and unmerged` (the existing `bdone` case stays
    green unchanged);
  - a `rescope-k` file with `status: done` and `pr: 12` is still edge work.
- With the fix reverted, the first assertion FAILS (run it and record the
  failing output in the workstream file's `## Review`).
- `./joharness.sh dispatch` in a fixture (or the existing dispatch selftest
  harness) with only that done rescope branch: no `edge work` section, and
  the rescope block still reads the key as settled (`OVERLAP-BOUND ... a
  rescope for this key is done or blocked`) when its holders still hold — no
  `surveyor` spawn line for the key.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` — maps `done` to rank 0; the
  rescope exception belongs where the row is ranked (it needs `workstream`
  and `plan`, which the `fields` read beside it does not fetch today).
- `.agents/harness/handover-context.sh:lead_why` — sets `status done and
  unmerged`, the text `dispatch` greps.
- `joharness.sh:cmd_dispatch` — `sed -n 's/^  FINISH BEFORE STARTING: ...'`
  turns the hook's lead into the `edge work` section.
- `joharness.sh:dispatch_rescope_branches` — reads rescope claims for the
  rescope block; `done | blocked` settle the key.
- `.agents/harness/selftest/handover-context-rank.sh` — existing `bdone`
  case to copy.
- `.claude/commands/manage.md` — rescope, "Nothing to change = the holds are
  GENUINE".

## Traps

- NEVER skip, disable or quarantine a test to get green.
- The test for the fix must FAIL without it.
- Hiding a LIVE surveyor (`in-progress`, `review`, or `pr:` set) is the
  wrong-but-plausible bug: match all of prefix, `plan: none`, `status: done`,
  no `pr:`.
- Workstream text on another branch is repo-controlled input: compare
  exact words, never eval it.
- No commit to a core path (`./joharness.sh protocol-paths`).
