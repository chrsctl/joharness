---
plan: dispatch-edge-slot-window
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: 701
scope: joharness.sh, .agents/harness/selftest/dispatch.sh, .agents/docs/orchestrator-reference.md, .agents/docs/orchestrated.md, .claude/commands/orchestrator.md
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
  read `JOHARNESS_EDGE_SLOT_HOURS` (default `4`, under the 5 h of the incident; `0` = never time out, today's
  behaviour; non-numeric = default). An edge branch (not `human/*`, which
  already holds no slot) whose `eage` is known and `>= hours*60` minutes does
  NOT increment `n_inflight` or `n_edge`; it increments a new `n_edge_aged`
  and its row says: `retired, no claim file, no push for <age> (>= <h>h
  JOHARNESS_EDGE_SLOT_HOURS): holds NO slot — dispatch cannot see whether a
  pull request exists; the health pass looks it up (open = merging, none =
  report to the human). Its items stay withheld, never respawn blind`. Unknown
  age keeps holding a slot (cannot prove it old). The verdict section prints
  one line for `n_edge_aged > 0`, next to the `n_edge` line. The STALL? line
  does NOT run for aged rows (they are neither counted in `n_stall` nor in
  `n_inflight`, so the stopped-fleet test `n_stall == n_inflight - n_blocked`
  stays true to its meaning). No `verdict   : DRAINED` line fires while an aged
  edge exists: a new `NOT DRAINED — … aged edge: look up its pull request
  first` branch ahead of every DRAINED printf (the `n_inflight - n_blocked`
  test and the exit lines below it).
- `joharness.sh` — add a `KNOBS` row for `JOHARNESS_EDGE_SLOT_HOURS`.
- `.agents/docs/orchestrated.md` — add its row to the knob table, beside
  `JOHARNESS_STALL_MINUTES`.
- `.claude/commands/orchestrator.md` — the `held-human` rule (spawn `slots` plus
  one per ledger entry still listed `retired, no claim file`) must also exempt
  an aged-edge row, as it does a `human/` row: dispatch already freed that slot.
- `.agents/harness/selftest/dispatch.sh` — extend the `mgr-eta` retire-commit
  block (near the `retired, no claim file — a pull request is expected` check):
  a second case with `JOHARNESS_EDGE_SLOT_HOURS` set below the branch's push age
  (fixture commits carry the real time, age ~0: backdate the eta retire commit
  with `GIT_COMMITTER_DATE` more than 1 h and under the 4 h default, the smallest
  window, by amend and force-push of the fixture ref, then set the ref back to
  the saved tip so later cases read the commit they read before) expects the slot back (`slots     : 4 of 8 free`), the new row text, and the
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
- A6: `.claude/commands/orchestrator.md` adds one slot per held-human entry still listed `retired, no claim file` (line ~168) — evidence: grep `held-human` there — confidence: medium
- A5: `dispatch_age_min` returns minutes and `$stall` is minutes — evidence: `joharness.sh` `eage -ge "$stall"` — confidence: medium (read `dispatch_age_min` first)

## Out of scope

- Reading pull request state in dispatch (A4). Suggestion (b) of the issue is met by the row text naming the health-pass lookup, not by an API call.
- Changing `orchestrator.md` respawn rows or the health table.
- `joharness.conf` (core path): the default lives in the script.
- Closing the root cause (step 7 retiring the workstream file before the pull request opens).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed, including the dispatch selftest's new aged and `=0` cases and `knobs-declared` (never run `selftest/dispatch.sh` alone: not runnable alone, it writes at `/`).
- `./joharness.sh ci` — ship-scope names this plan as SHIPS to consumers: the same `verify` is the check a consumer runs after sync.
- A dispatch fixture of its own holding only an aged edge (the shared one always has an item free or a manager in flight): `verify` red if its verdict reads `verdict   : DRAINED` or lacks `aged edge: look up its pull request first`.
- The new aged case FAILS on `origin/main`'s `joharness.sh`: `git show origin/main:joharness.sh >joharness.sh && ./joharness.sh ci`, red on `an edge older than the window gives its slot back`, then `git checkout joharness.sh`.
- `./joharness.sh verify` — 0 failed, count read from the output.

## Escape

Entry, Gate and Route answered in the pull request body. Entry: the edge-slot rule landed with the retired-edge scan (`git log -S'dispatch_retired_edges()' -- joharness.sh`, `a4399846`). Gate: `.agents/harness/selftest/dispatch.sh` asserts the slot is held but no case ages it. Route: this plan adds the aged case.

## Where to look

- `joharness.sh:dispatch_retired_edges` — the scan feeding the edge loop.
- `joharness.sh:dispatch_age_min` — unit of `eage`.
- `joharness.sh:n_edge_stall` — the neighbouring count to mirror for naming.
- `.agents/harness/selftest/dispatch.sh:mgr-eta` — the fixture to extend.
- `.agents/docs/orchestrator-reference.md:HELD BY HUMAN` — where the doc sentence goes.

## Traps

- Withholding the items must stay: a freed slot with the items offered spawns a second manager on a branch that may be mid-merge.
- Never read pull request state in a harness command.
- Do not regress `release-halt.sh`: it asserts `retired, no claim file` rows; keep that text a substring of the aged row.
- Another plan touching `joharness.sh` dispatch: none queued at writing; re-check `ls docs/plans`.
