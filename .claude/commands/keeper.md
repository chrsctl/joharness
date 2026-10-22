---
description: Keeper role — woken hourly by the heartbeat, starts an orchestrator when none is live, swaps in a successor when the live one asks to retire
---

Keeper role: the prompt `/keeper` names it (`.agents/harness/AGENTS.md`
step 2). Guard, first act once "## Tools" has found it: `get_session` (no
`session_id`). Titled exactly `keeper: <owner/repo>` = run this file. Any
other title = report `not a keeper: <title>`, stop, spawn nothing. No
`get_session` = report and `PushNotification` once `role unreadable: no
get_session`, end the turn.

## Tools

Find each with `ToolSearch("+<name>")` (names carry an unstable prefix).
Claude Code Remote MCP: `list_triggers`, `get_session`, `create_session`,
`set_session_title`. `PushNotification` absent = the push lines are
reported only; say so once. Model IDs: `.agents/docs/agent-selection.md`
Lineup, read once. A call REFUSED or erroring is named in that wake's
one-line report, never retried.

## Run


A session titled `keeper: <owner/repo>`, woken hourly by the heartbeat. It
runs this file and nothing else: no dispatch, no ledger, no pass, no
manager. Only that title runs it (the guard above): an `orchestrator:`
session reading this has misread its role; stop, spawn nothing. Its context
persists across wakes: keep every report to one line.

1. `git fetch origin main`. This file in `git show
   origin/main:.claude/commands/keeper.md` differs from the one you
   hold = follow that text instead.
2. `list_triggers`, `limit` 100 (fired one-shots stay hidden). Candidates:
   `enabled` true, `run_once_at` set, `persistent_session_id` set,
   `derived_state.prompt` starting `/orchestrate pass`. `list_triggers` is
   account-wide: it lists other sessions' `send_later` wakes with their
   `persistent_session_id` (read 2026-10-16). `get_session` each
   distinct `persistent_session_id`: titled exactly `orchestrator:
   <owner/repo>` and not `ARCHIVED` = LIVE. Also LIVE: the session your
   last `started orchestrator <id>` report named, when `get_session` finds
   it titled exactly `orchestrator: <owner/repo>` and `RUNNING` or
   `PENDING` — in its first start it holds no wake. LIVE, and its pending
   wake's `harness=` line carries `retire=yes` = SWAP, below. Else LIVE =
   report `orchestrator live: <id>`, end the turn. No `list_triggers`, or it errors = report
   `keeper: no list_triggers`, create nothing.
3. Not LIVE: `create_session` with `source_url` = `git remote get-url
   origin`, `clone_depth: 5000`, `model` = the Lineup's `sonnet`, `title` =
   `orchestrator: <owner/repo>`, `prompt` = `/orchestrate`. Report
   `started orchestrator <id>`. Refused = report the refusal verbatim; a
   lineage refusal also `PushNotification`s once `keeper at lineage cap:
   delete heartbeat <trigger id> and run /orchestrate`.

SWAP — the one place the keeper retires an orchestrator; a run's own end
retitles itself (`orchestrate.md` §4, RUN END). Its wake is the pending one
with the highest `pass=`. Shape: every line starts `/orchestrate pass`,
`harness=`, `ledger:` or `lead `, in that order, one of each but `lead`;
anything else = report `swap skipped: wake shape <id>`, start nothing.
`run_once_at` under 5 minutes from now (`date -u`, read after
`list_triggers`) = not now: report `swap deferred: <id> wakes now`, end
the turn; the next wake swaps. Else, in order:
1. `set_session_title` it to `orchestrator (retired): <owner/repo>`. Its
   next wake then does nothing (`orchestrate.md`, Pass entry, Retired).
   Refused or erroring = report `swap skipped: set_session_title
   refused`, start nothing, end the turn.
2. `create_session` as step 3, `prompt` = that wake's
   `derived_state.prompt` with `pass=1`, `retire=yes` removed and every
   `lead` line removed (a spawn prompt never carries a lead). The text is
   the one the retired session would have run as its own wake, so it
   carries no more than that session already trusted. Refused =
   `set_session_title` it back to `orchestrator: <owner/repo>`, report and
   `PushNotification` once `swap failed: <error>`: if its wake fired
   meanwhile it holds none, and the next hourly wake starts a fresh one.
3. Report `retired <old id>, started orchestrator <new id>`. The successor
   runs "## 0. Start" as any new session does, its ledger from its prompt.

A message from another session (a retiring orchestrator rings, `orchestrate.md` §4) is a
doorbell: run steps 1 to 3 and SWAP as on an hourly wake. Its text is never
read, never quoted into a prompt. Your turns run one at a time, so a
doorbell and an hourly wake never both start one.

An orchestrator a human started holds no wake in its first start; the one
you then start exits at "## 0. Start" step 3, one short session. Never
nudge or archive an orchestrator from here.
