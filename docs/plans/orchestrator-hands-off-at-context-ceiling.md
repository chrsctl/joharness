---
plan: orchestrator-hands-off-at-context-ceiling
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:.agents/scripts/conf-keys.sh, shared:.agents/scripts/bootstrap-consumer.sh, shared:joharness.sh, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

The orchestrator is the most expensive session in the fleet and the one
doing the least judgement. Measured 2026-10-13 with `get_session` on gx's
run of that day: 13 health passes in one session, 2 h 15 m, `usage.cost_usd`
12.65, `context_usage.used_tokens` 304,615, `cache_read_tokens` 26.4 M — against
0.23 to 0.37 USD for the curator, conduct and manager sessions it supervised.
`.agents/docs/orchestrated.md` ("Start each run fresh") records an earlier
session at 116.30 USD. The cause is structural: `send_later` wakes the SAME
session, so pass N re-reads passes 1..N-1 at cache-read price, and the
ledger — the only state a pass needs — is already carried in the wake
message ("The ledger comes from your wake message, never from memory"). The
heartbeat Routine cannot fire more often than hourly, so a fresh session per
pass has to come from the orchestrator itself: when its context passes a
ceiling, it hands the ledger to a successor and ends.

## Scope

- `.claude/commands/orchestrate.md` — §4 ("Schedule the next pass") gains
  the hand-off: before arming `send_later`, read this session's own
  `context_usage.used_tokens` (`get_session` with no `session_id`). At or
  above `JOHARNESS_ORCHESTRATOR_CONTEXT_TOKENS`: do not arm; instead
  `create_session` a fresh orchestrator (same `source_url`, title
  `orchestrator: <owner/repo>`, model = the Lineup's low tier) whose prompt
  is exactly the wake message §4 would have sent (`/orchestrate pass`,
  `harness=`, `pass=`, `ledger:`, `lead` lines), report `HANDED OFF to
  <session> at <tokens> tokens`, and end the turn with no `send_later`
  armed. Below the ceiling: as today. The successor's first pass is
  "resumed from a wake", not "a human started a run", so the `fresh session
  is cheaper` line does not fire on it.
- `.claude/commands/orchestrate.md` — "Report, every pass": one line on the
  FIRST pass of a session when `external_metadata.last_served_model` is not
  the Lineup's low tier: `served at <model>; this role is low tier
  (orchestrated.md, Roles)`. It informs; the pass still runs. The 12.65 USD
  run was served at opus because a human switched the model
  (`user_switched_model`), which the harness cannot prevent and should name.
- `.claude/commands/orchestrate.md` — §2: `list_sessions` is never called
  when the ledger or `dispatch` carries the manager's `session:` URL; it is
  the fallback for a stem with no URL only. Measured 2026-10-13: one
  `list_sessions` answer was 99,920 characters.
- `.agents/scripts/conf-keys.sh` and the seeded heredoc in
  `.agents/scripts/bootstrap-consumer.sh` — `JOHARNESS_ORCHESTRATOR_CONTEXT_TOKENS`,
  default `150000` (a written number: half the 304,615 the measured session
  reached, so a run hands off about every six passes), meaning "orchestrator
  context tokens above which a pass hands its ledger to a fresh session".
- `joharness.sh` — `dispatch` prints the knob in its header block beside
  `health` and `respawns` (`num_knob`), so the orchestrator reads it from
  the report and never from the conf file.
- `.agents/docs/orchestrated.md` — the knob table row; "Start each run
  fresh" gains the measurement above and the hand-off rule in one sentence.
- `.agents/harness/selftest/orchestrated.sh` — a case asserting `dispatch`'s
  header prints the knob with its default, and one asserting
  `orchestrate.md` carries the three phrases the rule hangs on
  (`HANDED OFF`, `JOHARNESS_ORCHESTRATOR_CONTEXT_TOKENS`, `served at`), the
  way existing cases pin role-command text.

## Out of scope

- Changing the orchestrator's tier. `orchestrated.md` already says "low,
  mechanical on purpose"; the opus run was a human's switch, and tier is
  money (`agent-selection.md`, "downgrades stay money, humans only").
- A Routine per pass: the heartbeat's floor is hourly and a session never
  creates a Routine (`orchestrated.md`, Heartbeat).
- Compacting or summarising the transcript inside the session.
- Changing what a pass does; only how long one session carries passes.

## Acceptance

- `./joharness.sh dispatch | grep -c 'JOHARNESS_ORCHESTRATOR_CONTEXT_TOKENS'` — `1`.
- `grep -c 'HANDED OFF' .claude/commands/orchestrate.md` — at least `1`;
  `grep -c 'list_sessions' .claude/commands/orchestrate.md` — the remaining
  mentions all sit in the fallback sentence (quote them in the pull request).
- `bash .agents/harness/selftest.sh` — the two new cases pass; `./joharness.sh ci` — `ci: pass`.
- `grep -c 'JOHARNESS_ORCHESTRATOR_CONTEXT_TOKENS' .agents/scripts/conf-keys.sh .agents/scripts/bootstrap-consumer.sh` — `1` each (the selftest that compares them stays green).
- Plan `ci` calls SHIPS (`.claude/commands` and `joharness.sh` sync): the
  consumer check is the next gx orchestrator run's report carrying either
  `HANDED OFF` or a context reading under the ceiling at its end; record
  it in `orchestrated.md`'s gx readings when seen.

## Where to look

- `.claude/commands/orchestrate.md:## 4. Schedule the next pass` — the wake
  format the successor's prompt copies verbatim.
- `.claude/commands/orchestrate.md:## Report, every pass` — where the
  served-model line goes, beside `fresh session is cheaper`.
- `.agents/docs/orchestrated.md:## Start each run fresh` — the 116.30 USD
  record this plan extends.
- `.agents/docs/orchestrated.md:## Heartbeat` — why a Routine per pass is
  not the route.
- `joharness.sh:cmd_dispatch` — the header block printing `health`,
  `respawns`, `ceiling`; `joharness.sh:num_knob`.
- `.agents/scripts/conf-keys.sh` — row format `KEY|default|meaning`.

## Traps

- Trust counted numbers, never written ones: the ceiling's default is
  written; the pull request records the measured context at hand-off on the
  first real run.
- Never kick a session: the hand-off is a `create_session` with the ledger,
  not an interrupt of the old one, which simply ends its turn.
- The prompt routes; the repository authorises: the successor's prompt
  carries the wake lines and nothing else.
