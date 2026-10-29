---
plan: dispatch-edge-slot-window
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: 701
scope: joharness.sh, .agents/harness/selftest/dispatch.sh, .agents/docs/orchestrator-reference.md
---

## Goal

Issue #701: `./joharness.sh dispatch` counts every retired no-claim-file
branch (`n_inflight`, `n_edge`) against the manager cap for as long as its item
is on the base branch. Dispatch never reads pull request state and nothing times
the assumption "a pull request is coming" out, so a branch whose pull request
never opened held a slot 5 hours and starved 5 free items. Bound the slot hold
by a window: past it the row stays listed and its items stay withheld, but it
stops holding a slot.

## Scope

- `joharness.sh` — in `dispatch`, the edge loop (`dispatch_retired_edges`
  consumer, the `n_inflight=$((n_inflight + 1)); n_edge=...` block):
  read `JOHARNESS_EDGE_SLOT_HOURS` (default `6`; `0` = never time out, today's
  behaviour; non-numeric = default). An edge branch (not `human/*`, which
  already holds no slot) whose `eage` is known and `>= hours*60` minutes does
  NOT increment `n_inflight` or `n_edge`; it increments a new `n_edge_aged`
  and its row says: `retired, no claim file, no push for <age> (>= <h>h
  JOHARNESS_EDGE_SLOT_HOURS): holds NO slot — dispatch cannot see whether a
  pull request exists; the health pass looks it up (open = merging, none =
  report to the human). Its items stay withheld, never respawn blind`. Unknown
  age keeps holding a slot (cannot prove it old). The verdict section prints
  one line for `n_edge_aged > 0`, next to the `n_edge` line. The STALL? line
  logic is unchanged and still runs for aged rows.
- `.agents/harness/selftest/dispatch.sh` — extend the `mgr-eta` retire-commit
  block (near the `retired, no claim file — a pull request is expected` check):
  a second case with `JOHARNESS_EDGE_SLOT_HOURS` set below the branch's push age
  (use the fixture's existing clock or backdate the commit as neighbouring cases
  do) expects the slot back (`slots     : 4 of 8 free`), the new row text, and the
  item still not offered for spawning; `JOHARNESS_EDGE_SLOT_HOURS=0` expects the
  old row and slot count.
- `.agents/docs/orchestrator-reference.md` — one sentence near the
  `retired, no claim file` HELD BY HUMAN paragraph: an aged edge row holds no
  slot; the orchestrator looks the pull request up (GitHub MCP) and either
  confirms it is merging or reports it to the human.

## Assumptions

- A1: dispatch holds a slot for an edge branch with no pull request check —
  evidence: `joharness.sh` edge loop, `n_inflight=$((n_inflight + 1))` after the `human/*` case; the row text itself says it does not read pull request state — confidence: high
- A2: items of the edge branch are withheld via `edge_items`, built before the slot is counted, so skipping the count leaves them withheld — evidence: `joharness.sh` `edge_items="${edge_items} ${epath}@${ebranch} "` — confidence: high
- A3: `human/*` edges already hold no slot, so the window applies only to the other edges — evidence: same loop, `case "$ebranch" in human/*)` — confidence: high
- A4: harness commands never call the GitHub API, so the pull request state cannot be read inside dispatch — evidence: `.agents/harness/AGENTS.md` Loop step 7 last line — confidence: high
- A5: `dispatch_age_min` returns minutes and `$stall` is minutes — evidence: `joharness.sh` `eage -ge "$stall"` — confidence: medium (read `dispatch_age_min` first)

## Out of scope

- Reading pull request state in dispatch (A4). Suggestion (b) of the issue is met by the row text naming the health-pass lookup, not by an API call.
- Changing `orchestrator.md` respawn rows or the health table.
- `joharness.conf` (core path): the default lives in the script.
- Closing the root cause (step 7 retiring the workstream file before the pull request opens).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `bash .agents/harness/selftest/dispatch.sh` (or the selftest entry `./joharness.sh verify` runs for it) — 0 failed, including the new aged and `=0` cases.
- The new aged case FAILS on `origin/main`'s `joharness.sh` (run the new selftest against it: red on the slots line).
- `./joharness.sh verify` — 0 failed, count read from the output.

## Escape

Entry, Gate and Route answered in the pull request body. Entry: the edge-slot rule landed with the retired-edge scan (`git log -S'a pull request is expected' -- joharness.sh`). Gate: `.agents/harness/selftest/dispatch.sh` asserts the slot is held but no case ages it. Route: this plan adds the aged case.

## Where to look

- `joharness.sh:dispatch_retired_edges` — the scan feeding the edge loop.
- `joharness.sh:dispatch_age_min` — unit of `eage`.
- `joharness.sh:n_edge_stall` — the neighbouring count to mirror for naming.
- `.agents/harness/selftest/dispatch.sh:mgr-eta` — the fixture to extend.
- `.agents/docs/orchestrator-reference.md:HELD BY HUMAN` — where the doc sentence goes.

## Traps

- Withholding the items must stay: a freed slot with the items offered spawns a second manager on a branch that may be mid-merge.
- Never read pull request state in a harness command.
- Do not regress `release-halt.sh`: it asserts `retired, no claim file` rows; keep that text a prefix of the aged row.
- Another plan touching `joharness.sh` dispatch: none queued at writing; re-check `ls docs/plans`.
