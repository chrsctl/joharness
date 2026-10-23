---
plan: heartbeat-register-drained
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/keeper.md, .agents/docs/orchestrate-reference.md, .agents/docs/orchestrated.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

One orchestrator run, not two. Suppose an orchestrator finds no heartbeat on
a DRAINED run. REGISTER starts a keeper session with the prompt `/keeper`.
The keeper's first turn runs its full check, and by then the orchestrator
that made it has retired itself (RUN END). The keeper sees nothing LIVE and
starts a second orchestrator. That one reads the same DRAINED dispatch and
retires too. Observed 2026-10-23: `session_01AK15…` registered, its keeper
`session_01EFMp…` started `session_017DPK…`, and that session drained
41 seconds after it started. The keeper's first turn should only take its
post. The registering orchestrator has just read dispatch, so the next
hourly wake decides whether an orchestrator is needed.

## Scope

- `.agents/docs/orchestrate-reference.md` — REGISTER step 2: the keeper's
  `create_session` `prompt` = `/keeper register`. The Routine's `prompt`
  (step 3) stays `/keeper`.
- `.claude/commands/keeper.md` — a prompt carrying `register` (REGISTER's
  first turn) runs the guard and step 1, reports `keeper registered: parent
  <parent_session_id>`, and ends the turn. It starts nothing and swaps
  nothing.
- `.agents/docs/orchestrated.md` — the Heartbeat paragraph says the first
  turn takes the post and the first hourly wake does the check.
- `.agents/harness/selftest/orchestrated.sh` — pins for the new spellings.
  Update the pin for the old `prompt` = `/keeper` spelling in REGISTER
  step 2.

## Assumptions

- A1: a slash command's arguments reach the model, so `/keeper register`
  runs keeper.md and the model can read `register` — evidence: Claude Code
  custom commands pass the text after the name as arguments; the
  `/orchestrate pass=…` wake prompts already rely on this
  (`.claude/commands/orchestrate.md`, Pass entry) — confidence: high.
- A2: the heartbeat check reads only the Routine's prompt, never the keeper
  session's first prompt, so `prompt` staleness is unaffected — evidence:
  `.agents/docs/orchestrate-reference.md` § 0. Start step 5, the `prompt`
  reason reads `derived_state.prompt` — confidence: high.
- A3: REPLACE reuses REGISTER from step 2, so its new keeper also gets
  `/keeper register`. That is safe: a REPLACE runs inside a live pass, and
  a keeper started then would only report `orchestrator live` — evidence:
  orchestrate-reference.md step 5, REPLACE "then REGISTER from step 2" —
  confidence: high.
- A4: `./joharness.sh start` reads no prompt, so its routing lines need no
  change — evidence: `joharness.sh:cmd_start` prints "No shell can see a
  prompt" — confidence: high.

## Out of scope

- Any change to `joharness.sh` or dispatch: the bug is in role text.
- Changing the Routine's cron, prompt or binding: the hourly path works.
- Teaching the keeper to read dispatch: keeper.md forbids it ("no dispatch").
- Core paths: no change to `joharness.conf`, `.claude/settings.json` or
  `.github`.

## Acceptance

- `grep -c '/keeper register' .claude/commands/keeper.md
  .agents/docs/orchestrate-reference.md` — each file ≥ 1.
- `.agents/harness/selftest.sh` — `0 failed`. The new pins fail on
  `origin/main` (check: revert the doc lines, rerun, see FAIL).
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `.claude/commands/keeper.md:## Run` — the guard and steps 1–3.
- `.agents/docs/orchestrate-reference.md:## 0. Start` — step 5, REGISTER
  steps 1–3.
- `.agents/docs/orchestrated.md:## Heartbeat: making the fleet long`.
- `.agents/harness/selftest/orchestrated.sh` — the keeper.md and
  orchestrate-reference.md needle lists.

## Traps

- NEVER skip, disable or quarantine a test to get green: change a pin only
  when its spelling moves.
- No core path in the diff.
- Docs state the status quo: the 2026-10-23 incident belongs in git log,
  not in keeper.md.
