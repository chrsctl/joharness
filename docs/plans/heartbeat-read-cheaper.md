---
plan: heartbeat-read-cheaper
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
serves: all
issue: none
scope: shared:.claude/commands/orchestrator.md, .agents/docs/orchestrator-reference.md
---

## Goal

Every orchestrator pass reads `list_triggers` with `include_completed` for
the Superseded check, and the heartbeat check reuses that answer. The flag
adds every fired one-shot `send_later` wake on the account, so the read is
large and paginated (seen on chrsctl/gx: a page full of fired wakes). Neither
check needs fired wakes: Superseded compares PENDING wakes, and a paused
heartbeat Routine is listed whenever `enabled` is left unset. The keeper
already uses the cheap read (`enabled true, recurring false, limit 100`).
Name the cheap reads in the spec.

## Scope

- `.claude/commands/orchestrator.md` — Pass entry, **Superseded**: replace
  "`list_triggers` with `include_completed`" with two reads: wakes =
  `list_triggers` `recurring` false, `enabled` true, `limit` 100;
  heartbeat = `list_triggers` `recurring` true, `enabled` unset (a paused one
  must show). **Duplicate** and **Heartbeat** read the answer they need.
- `.agents/docs/orchestrator-reference.md` — § 0. Start step 5 ("no filter:
  a paused one must show") → the `recurring` true read, `enabled` unset;
  § Out-of-band arm ("`list_triggers` with `include_completed`") → the wakes
  read. Step 3's LIVE check names the wakes read.

## Assumptions

- A1: a pending one-shot is listed without `include_completed`; only fired
  one-shots and project-moved tasks are hidden — evidence: the
  `list_triggers` tool description in a session (`include_completed`
  parameter) — confidence: high. Re-read the description in the building
  session and quote it in `## Decisions`.
- A2: omitting `enabled` lists paused and enabled Routines both — evidence:
  same description, `enabled` parameter ("Omit for both") — confidence: high
- A3: no check reads a fired wake — evidence: grep `include_completed` in
  `.claude/commands/` and `.agents/docs/` — confidence: medium. A hit that
  needs a fired wake = keep it there and say why in `## Decisions`.

## Out of scope

- `keeper.md`: it already uses the cheap read.
- Any `joharness.sh` change: harness commands never call the GitHub or
  control-plane API.

## Acceptance

- `grep -rn "include_completed" .claude/commands .agents/docs` — no hit, or
  only hits justified in `## Decisions`.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.claude/commands/orchestrator.md:Superseded` — the pass-entry read.
- `.agents/docs/orchestrator-reference.md:Heartbeat, here and on every pass` — step 5.
- `.agents/docs/orchestrator-reference.md:Out-of-band arm` — the arm read.
- `.claude/commands/keeper.md:fired` — the cheap read already in use.

## Traps

- Shares `orchestrator.md` with `retired-edge-stall-window` and
  `stranded-branch-plans`: reconcile, do not overwrite.
- A paused heartbeat must still be seen: never add `enabled: true` to the
  heartbeat read.
