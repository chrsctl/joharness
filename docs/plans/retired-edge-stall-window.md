---
plan: retired-edge-stall-window
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.claude/commands/orchestrator.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/dispatch.sh, shared:.agents/harness/selftest.sh, shared:.agents/docs/orchestrator-reference.md
---

## Goal

A manager past its retire commit spends the rest of its life in `finish`,
and in local-checks mode `finish` pushes nothing for tens of minutes (ci,
verify, then the consumer's `local-check` with a 30-minute budget). Dispatch
marks that retired row `STALL?` at `JOHARNESS_STALL_MINUTES` (45), and the
health table acts on the FIRST matching row: `RUNNING | STALL?` → NUDGE, then
KILL, sits above `RUNNING | retired, no claim file` → merging. Seen on
chrsctl/gx: retired managers flagged `STALL?` at 50-63 min while RUNNING
`finish`. The nudge asks for `/handover, commit, push` on a branch whose
workstream file the retire commit deleted; any commit moves the head and
forces `finish` to run again; KILL interrupts `finish` and writes `## Blockers`
into a deleted file. Give a retired row a stall clock that fits `finish`,
and a nudge that does not ask for a handover.

## Scope

- `joharness.sh` — in dispatch's edge loop (the `retired, no claim file — a
  pull request is expected` row), mark `STALL?` only when push age is at
  least the retired-row window: `JOHARNESS_STALL_MINUTES +
  JOHARNESS_LOCAL_CHECK_MINUTES` (defaults 45 + 30 = 75 min). Name the window
  and both knobs in the `STALL?` text. Claimed rows keep the plain stall
  window. The aged-edge branch (`holds NO slot`) keeps its mark, on the same
  retired-row clock (at the default 4h slot window that changes nothing). The
  text is `(>= <W>m retired-row window: JOHARNESS_STALL_MINUTES <S> +
  JOHARNESS_LOCAL_CHECK_MINUTES <L>, since step 7 runs finish)`. The `stall :`
  header line names the retired-row window beside the plain one.
- `.claude/commands/orchestrator.md` — the `RUNNING | STALL?` NUDGE row: when
  the row is `retired, no claim file`, the message is "Orchestrator health
  pass: no push on <branch> for <N>m since retire. Reply with where finish
  stands. Do NOT run /handover or commit unless finish asks for a reconcile."
  KILL on a retired row skips the `## Blockers` write (no workstream file):
  interrupt, wait one pass, archive, RESPAWN to finish the merge (the
  existing `gone` edge row). The command's reading budget has no room for
  two rows: the NUDGE row points a retired row at a new ref § Retired
  stall, which carries the message and the kill (§ KILL and LOOP points
  there too; IDLE/PENDING's "NUDGE as above" reaches it through the NUDGE
  row).
- `.agents/docs/orchestrator-reference.md` — § Retired stall; the
  no-transport row's kill threshold names the retired window.
- `.agents/docs/orchestrated.md` — the knob table row for
  `JOHARNESS_STALL_MINUTES`: one clause naming the retired-row window.
- `.agents/harness/selftest/dispatch.sh` — new cases: a retired edge row
  pushed 60 min ago carries NO `STALL?`; pushed 80 min ago carries one naming
  the 75-minute window; a claimed row at 60 min still stalls. Existing cases
  that force a retired row's `STALL?` with `JOHARNESS_STALL_MINUTES=0` add
  `JOHARNESS_LOCAL_CHECK_MINUTES=0` (the window is the sum): same assertion,
  same strength.
- `.agents/harness/selftest.sh` — unset `JOHARNESS_LOCAL_CHECK_MINUTES` with
  the other knobs, so a session's own value cannot move the 75.

## Assumptions

- A1: a retired manager pushes nothing while `finish` runs — evidence:
  `joharness.sh` finish's `UNPUSHED` refusal (push before certifying) and
  `.agents/docs/consumer-repos.md` Local checks (local-check after ci and
  verify) — confidence: high
- A2: the edge-row `STALL?` is the `elif [ "$eage" -ge "$stall" ]` branch
  after `n_edge=$((n_edge + 1))` in the dispatch edge loop — evidence:
  `joharness.sh:dispatch_retired_edges` feeds it — confidence: high
- A3: `JOHARNESS_LOCAL_CHECK_MINUTES` is readable through `num_knob` in
  dispatch — evidence: grep its declaration in `joharness.sh` knob table —
  confidence: medium. Not declared = read it with the same default (30) and
  say so in `## Decisions`.
- A4: the health table's row order is deliberate (`selftest/dispatch.sh`
  comment "Its STALL? mark stays: the health table nudges and kills a hung
  RUNNING session by it") — keep the order, change the clock — confidence:
  high

## Out of scope

- Reordering the health table rows. A genuinely hung retired session must
  still be nudged and killed; only its clock moves.
- Changing `JOHARNESS_STALL_MINUTES` or any `joharness.conf` value (core path).
- Reading pull request state from dispatch (dispatch reads git only).

## Acceptance

- `./joharness.sh ci` — `ci: pass` (red: `ci: FAIL` naming the case); the
  new dispatch cases PASS. Without the change: `cp -r . "$T" && git show
  origin/main:joharness.sh >"$T/joharness.sh" && (cd "$T" && ./joharness.sh
  ci)` prints `FAIL and carries NO STALL? inside the retired-row window` and
  `FAIL past the retired-row window it stalls, naming the window and both
  knobs`.
- `./joharness.sh verify` — `0 failed` (red: a non-zero failed count).
- Consumer side, after its next sync: `./joharness.sh dispatch` prints a
  `stall     :` line carrying `a retired row with no claim file: 75 min` at
  the default knobs (red: the line lacks it).
- `grep -n "since retire" .agents/docs/orchestrator-reference.md` — one
  line, the retired-row nudge (red: none, as on `origin/main`);
  `grep -c "ref § Retired stall" .claude/commands/orchestrator.md` — 1.

## Where to look

- `joharness.sh:dispatch_retired_edges` — the edge scan.
- `joharness.sh:JOHARNESS_EDGE_SLOT_HOURS` — the aged-edge branch beside it.
- `.claude/commands/orchestrator.md:NUDGE` — the health table rows.
- `.agents/docs/orchestrator-reference.md:KILL and LOOP` — the kill steps.
- `.agents/harness/selftest/dispatch.sh:holds NO slot` — the existing edge cases.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- Shares `joharness.sh` and `.agents/docs/orchestrated.md` with
  `stranded-branch-plans`, and `orchestrator.md` with `stranded-branch-plans`
  and `heartbeat-read-cheaper`: reconcile, do not overwrite.
- `orchestrator.md` has a reading budget (`selftest/reading-budget.sh`,
  bound 23628 bytes; 12 free once `origin/main` moved on): the new text must fit it.
- `joharness.conf` is a core path: do not touch it.
