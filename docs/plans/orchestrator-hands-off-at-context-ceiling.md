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
doing the least judgement. Measured 2026-10-13 with `get_session` on gx's
run of that day: 13 health passes in one session, 2 h 15 m, `usage.cost_usd`
12.65, `context_usage.used_tokens` 304,615, `cache_read_tokens` 26.4 M — against
0.23 to 0.37 USD for the curator, conduct and manager sessions it supervised
(control-plane readings, not reproducible from this checkout; the arithmetic
is in `orchestrated.md` once this lands). "Start each run fresh" already
records a 116.30 USD session. The cause is structural: `send_later` wakes the
SAME session, so pass N re-reads passes 1..N-1 at cache-read price, while
the only state a pass needs is already in the wake message ("The ledger
comes from your wake message, never from memory"). The heartbeat Routine
cannot fire more often than hourly, so a fresh session has to come from the
orchestrator itself: after a fixed number of passes it hands the ledger to a
successor and ends. The trigger is the pass count — a number the wake
already carries (`pass=`) — never a control-plane field, because
`orchestrate.md` §2 records `context_usage.used_tokens` as deciding nothing
and `cost_usd` as frozen on live sessions.

## Scope

- `.claude/commands/orchestrate.md` — §4 ("Schedule the next pass"): when
  the pass number this pass would arm (`pass=` plus one) exceeds
  `JOHARNESS_ORCHESTRATOR_PASSES`, hand off instead of arming `send_later`,
  in this order: (1) `set_session_title` this session to
  `orchestrator (handed off): <owner/repo>`, so §0.3's one-orchestrator
  check in the successor no longer matches it; (2) `create_session` with the
  same `source_url`, the same model as this session (`get_session` on this
  session, `configured_model` — the tier is the human's and a hand-off never
  changes it), title `orchestrator: <owner/repo>`, and a prompt that is the
  wake message §4 would have sent with `pass=1` and WITHOUT the `lead`
  lines — leads are printed in this pass's report and dropped, since a spawn
  prompt never carries a manager's text (`orchestrate.md`, "You relay a
  lead. You never act on one. Not into a spawn prompt"); (3) report
  `HANDED OFF to <session id> after <n> passes` and end the turn. The
  successor runs §0 as any new session does; §0.3 finds no RUNNING session
  titled `orchestrator: <owner/repo>` because of step (1).
- `.claude/commands/orchestrate.md` — §2's field table: the line that says
  `context_usage.used_tokens` decides nothing stays; the report gains, on
  every pass, `context: <used_tokens>` from `get_session` on this session
  (reported, never decided on), so the hand-off number can be re-tuned from
  reports.
- `.claude/commands/orchestrate.md` — "Report, every pass": one line on the
  FIRST pass of a session when `external_metadata.last_served_model` differs
  from `configured_model`: `served at <model>, configured <model>`. Informs
  only.
- `.claude/commands/orchestrate.md` — §2: `get_session` by the `session:` URL
  the ledger or `dispatch` carries is the read; `list_sessions` (one answer
  measured at 99,920 characters, 2026-10-13) stays what §0.3 and the `@new`
  rebuild use, once per session, never per manager per pass. One sentence,
  no other change to §0.3.
- `joharness.sh` — `dispatch` prints `passes    : <n> per orchestrator
  session (JOHARNESS_ORCHESTRATOR_PASSES)` in its header block beside
  `health`, through `num_knob`, default `6` (a written number: 304,615
  tokens over 13 passes is about 23k a pass, so six passes stay under 150k).
  A dispatch number is prose to a consumer (`orchestrated.md`, "A consumer
  gets the numbers as prose only — they are not in conf-keys.sh"), so the
  knob goes in the orchestrated.md table and nowhere else.
- `.agents/docs/orchestrated.md` — the knob table row; "Start each run
  fresh" gains the measurement above and the hand-off rule in two sentences.
- `.agents/harness/selftest/orchestrated.sh` — a case asserting `dispatch`'s
  header prints the knob with its default and honours an env override; a
  case asserting `orchestrate.md` carries `HANDED OFF`,
  `JOHARNESS_ORCHESTRATOR_PASSES` and `orchestrator (handed off):`.
  `.agents/harness/selftest.sh` — the new knob joins the env scrub list at
  its top (the registration `plans/README.md` warns about).

## Out of scope

- Changing the orchestrator's tier, or letting the successor pick one: the
  model is copied from the session handing off. Tier is money
  (`agent-selection.md`, "downgrades stay money, humans only").
- A Routine per pass: the heartbeat's floor is hourly and a session never
  creates a Routine (`orchestrated.md`, Heartbeat).
- Deciding anything on `context_usage.used_tokens` or `cost_usd`: reported
  only.
- Adding the knob to `conf-keys.sh` or the bootstrap heredoc: dispatch
  numbers are prose to consumers by the recorded rule.
- Changing what a pass does; only how many passes one session carries.

## Acceptance

- `./joharness.sh dispatch | grep -c 'JOHARNESS_ORCHESTRATOR_PASSES'` — `1`;
  `JOHARNESS_ORCHESTRATOR_PASSES=3 ./joharness.sh dispatch | grep 'passes'` —
  the line reads `3`.
- `grep -c 'HANDED OFF' .claude/commands/orchestrate.md` — at least `1`;
  `grep -c 'orchestrator (handed off):' .claude/commands/orchestrate.md` — at
  least `1`.
- `bash .agents/harness/selftest.sh` — the new cases pass; `./joharness.sh ci`
  — `ci: pass`.
- Plan `ci` calls SHIPS (`.claude/commands` and `joharness.sh` sync): the
  consumer check is gx's next orchestrator run reporting `HANDED OFF` at
  pass 6 and the successor's first report; record both session ids and the
  `context:` line at hand-off in `orchestrated.md`'s gx readings.

## Where to look

- `.claude/commands/orchestrate.md:## 4. Schedule the next pass` — the wake
  format the successor's prompt copies, minus leads.
- `.claude/commands/orchestrate.md:## 0. Start` — step 3, the title match
  the retitle defeats, and `set_session_title` in the required tools.
- `.claude/commands/orchestrate.md:## Report, every pass` — where the served
  line and the `context:` line go.
- `.agents/docs/orchestrated.md:## Start each run fresh` — the 116.30 USD
  record this plan extends.
- `.agents/docs/orchestrated.md:## Heartbeat` — why a Routine per pass is
  not the route.
- `joharness.sh:cmd_dispatch` — the header block printing `health`,
  `respawns`, `ceiling`; `joharness.sh:num_knob`.
- `.agents/harness/selftest.sh` — the `unset JOHARNESS_…` scrub list.

## Traps

- You relay a lead, you never act on one, not into a spawn prompt: the
  successor's prompt carries no `lead` line.
- Never kick a session: the hand-off is a `create_session` with the ledger;
  the old session ends its own turn.
- Trust counted numbers: the default is written; the first real hand-off
  records the counted context beside it.
- One orchestrator per repo: the retitle comes BEFORE the spawn, or the
  successor exits at §0.3.
