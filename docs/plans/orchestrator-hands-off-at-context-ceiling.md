---
plan: orchestrator-hands-off-at-context-ceiling
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:joharness.sh, shared:.agents/harness/selftest/orchestrated.sh, shared:.agents/harness/selftest.sh
---

## Goal

The orchestrator is the most expensive session in the fleet and the one
doing the least judgement. Read 2026-10-13 with `get_session` on gx's run of
that day (control-plane readings, not reproducible from this checkout): 13
health passes in one session, 2 h 15 m, `usage.cost_usd` 12.65,
`context_usage.used_tokens` 304,615, `cache_read_tokens` 26.4 M — against
0.23 to 0.37 USD for the curator, conduct and manager sessions it
supervised. `orchestrated.md` ("Start each run fresh") already records a
116.30 USD session. The cause is structural: `send_later` wakes the SAME
session, so pass N re-reads passes 1..N-1 at cache-read price, while the
only state a pass needs is already in the wake message ("The ledger comes
from your wake message, never from memory"). The heartbeat Routine cannot
fire more often than hourly, so a fresh session has to come from the
orchestrator itself: after a fixed number of passes it hands the ledger to a
successor and ends. The trigger is the pass count, a number the wake already
carries (`pass=`), never a control-plane field: `orchestrate.md` §2 records
`context_usage.used_tokens` as deciding nothing and `cost_usd` as frozen on
live sessions.

## Scope

- `.claude/commands/orchestrate.md` — §4 ("Schedule the next pass"): when
  the pass number this pass would arm (`pass=` plus one) exceeds
  `JOHARNESS_ORCHESTRATOR_PASSES`, hand off instead of arming `send_later`,
  in this order:
  1. read this session (`get_session`, no `session_id`): the model to copy
     is `configured_model`, else `session_context.model`; neither present,
     or `set_session_title` not among this session's tools (it is OPTIONAL
     in the tool list) = no hand-off this pass: arm `send_later` as today and
     report `hand-off skipped: <model unreadable | no set_session_title>`.
     A session never picks a tier ("Never: Pick a tier"), so a hand-off
     without a readable model does not happen;
  2. `set_session_title` this session to
     `orchestrator (handed off): <owner/repo>`, so §0.3's exact-title match
     in the successor no longer finds it;
  3. `create_session`: same `source_url`, the model from step 1, title
     `orchestrator: <owner/repo>`, and a prompt that is the wake message §4
     would have sent with `pass=1` and WITHOUT the `lead` lines, since a
     spawn prompt never carries a manager's text ("You relay a lead. You
     never act on one. Not into a spawn prompt"). `create_session` fails or
     is refused = restore this session's title with `set_session_title`,
     arm `send_later` as today, report `hand-off failed: <error>`; the pass
     is otherwise unchanged;
  4. the leads this wake carried are sent to the successor one by one with
     `send_message`, verbatim, the channel a manager's lead already uses —
     the same treatment a lead arriving after the hand-off gets (next
     bullet);
  5. report `HANDED OFF to <session id> after <n> passes` and end the turn.
  The successor runs §0 as any new session does.
- `.claude/commands/orchestrate.md` — a paragraph after §4: a session
  titled `orchestrator (handed off): …` that is woken by a manager's lead
  message (managers spawned before the hand-off carry its id as their lead
  address) forwards the message verbatim with `send_message` to the
  successor id its hand-off report named, arms nothing, and ends. A human
  message wakes it as any session; it answers by naming the successor,
  spawns nothing and arms nothing — an order to spawn is the successor's,
  since a manager spawned here would carry this retired id as its lead
  address.
- `.claude/commands/orchestrate.md` — the `Never` line "`send_message` to a
  child carries the health table's nudge text and nothing else" gains its
  one exception: to the successor orchestrator, a lead line verbatim (step
  4 above and the forward). Nothing else changes in that list.
- `.claude/commands/orchestrate.md` — "Report, every pass": `context:
  <used_tokens>` from the same `get_session` read, reported never decided
  on, so the pass number can be re-tuned from reports; and on the FIRST
  pass of a session, when `external_metadata.last_served_model` differs from
  the configured model, `served at <model>, configured <model>`. §2's line
  that `used_tokens` decides nothing stays as written.
- `.claude/commands/orchestrate.md` — §2, one sentence: `get_session` by the
  `session:` URL the ledger or `dispatch` carries is the per-manager read;
  `list_sessions` (one answer read at 99,920 characters, 2026-10-13) stays
  what §0.3 and the `@new` rebuild use, once per session.
- `joharness.sh` — `dispatch` prints `passes    : <n> per orchestrator
  session (JOHARNESS_ORCHESTRATOR_PASSES)` in its header block beside
  `health`, through `num_knob`, default `6` (a written number: 304,615
  tokens over 13 passes is about 23k a pass, so six passes stay under
  150k). The knob is documented in the orchestrated.md table like every
  other dispatch number and is not added to `conf-keys.sh` or the bootstrap
  heredoc; if `knobs-declared-once` has landed, it gets its `KNOBS` row
  (scope `dispatch`).
- `.agents/docs/orchestrated.md` — the knob table row; the Roles table's
  orchestrator row: Spawns "manager sessions, and one orchestrator at
  hand-off", Ends when "dispatch says DRAINED with nothing in flight, or at
  hand-off"; "Start each run fresh" gains the measurement above and the
  hand-off rule in two sentences, and is where the first real hand-off's
  `context:` reading is recorded by the orchestrator's owner.
- `.agents/harness/selftest/orchestrated.sh` — a case asserting `dispatch`'s
  header prints the knob with its default and honours an env override; a
  case asserting `orchestrate.md` carries `HANDED OFF`,
  `JOHARNESS_ORCHESTRATOR_PASSES`, `orchestrator (handed off):` and
  `hand-off skipped` and `hand-off failed`. `.agents/harness/selftest.sh` — the new knob joins
  the env scrub list at its top.

## Out of scope

- Changing the orchestrator's tier, or letting the successor pick one: the
  model is copied from the session handing off; unreadable = no hand-off.
  Tier is money (`agent-selection.md`, "downgrades stay money, humans only").
- A Routine per pass: hourly floor; a session never creates a Routine
  (`orchestrated.md`, Heartbeat).
- Deciding anything on `context_usage.used_tokens` or `cost_usd`.
- Adding the knob to `conf-keys.sh` or the bootstrap heredoc.
- Re-addressing managers already spawned: the forward above covers them.
- Changing what a pass does; only how many passes one session carries.

## Acceptance

- `./joharness.sh dispatch | grep -c 'JOHARNESS_ORCHESTRATOR_PASSES'` — `1`;
  `JOHARNESS_ORCHESTRATOR_PASSES=3 ./joharness.sh dispatch | grep 'passes'` —
  the line reads `3`.
- `grep -c 'HANDED OFF\|orchestrator (handed off):\|hand-off skipped\|hand-off failed' .claude/commands/orchestrate.md` — at least `4`.
- `bash .agents/harness/selftest.sh` — the new cases pass; `./joharness.sh ci`
  — `ci: pass`.
- Plan `ci` calls SHIPS (`.claude/commands` and `joharness.sh` sync): the
  consumer check is gx's next orchestrator run reporting `HANDED OFF` at
  pass 6 and the successor's first report; both session ids and the
  `context:` line at hand-off go into "Start each run fresh".

## Where to look

- `.claude/commands/orchestrate.md:## 4. Schedule the next pass` — the wake
  format the successor's prompt copies, minus leads.
- `.claude/commands/orchestrate.md:## 0. Start` — step 3, the exact-title
  match the retitle defeats; the tool list naming `set_session_title`
  optional.
- `.claude/commands/orchestrate.md:## 3. Spawn` — the lead address written
  into every manager prompt (why the forward exists).
- `.claude/commands/orchestrate.md:## Report, every pass`.
- `.agents/docs/orchestrated.md:## Start each run fresh`;
  `.agents/docs/orchestrated.md:## Heartbeat`; the Roles table.
- `joharness.sh:cmd_dispatch` — the header block; `joharness.sh:num_knob`.
- `.agents/harness/selftest.sh` — the `unset JOHARNESS_…` scrub list.

## Traps

- You relay a lead, you never act on one, not into a spawn prompt.
- Never kick a session: the hand-off is a `create_session`; the old session
  ends its own turn.
- Never pick a tier: unreadable model = no hand-off.
- One orchestrator per repo: the retitle comes BEFORE the spawn.
- `knobs-declared-once` and `selftest-exec-budget` add knobs too:
  whichever lands after `knobs-declared-once` adds its `KNOBS` row.
- Trust counted numbers: the default is written; the first hand-off records
  the counted context beside it.
