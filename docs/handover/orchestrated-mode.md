---
workstream: orchestrated-mode
status: in-progress
branch: claude/unsupervised-orchestrated-mode-tzdvw2
pr: none
plan: orchestrated-mode
issue: none
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
agent: opus
updated: 2026-09-05
next: Review at opus (verifier spawned), record findings, fix; then verify green, hand over
---

## Goal

Requester, 2026-09-05, verbatim shape: a new unsupervised (beta) fully
orchestrated mode. An orchestrator on a low tier with maximum parallelism
pulls from the queue, spawns one manager per item in a new session, checks
health regularly, and can kill a stuck manager — but first makes it
summarise progress into the handover for the next one. Managers (project
manager, researcher, whatever the item is) run on a higher tier set by the
plan, own one plan or research file, decompose it, spawn lower-tier workers
for the pieces, and are in charge until the plan retires. Research Gas Town
first. Ultimate goal: empty the queue efficiently under a maximum
concurrency.

## Decisions

- ONE knob, a third value: `JOHARNESS_MODE=orchestrated`. Not a second
  `JOHARNESS_DISPATCH` switch. `authority` verifies one merged line, the
  banner says one word, and every unattended bound (protocol boundary,
  requirement lint, `SUPERVISED ONLY` marking, step 7 unchanged) applies by
  one predicate, `unattended()`, so the two unattended modes cannot drift on
  what they forbid.
- Default role under orchestrated = orchestrator. The heartbeat fires a
  standalone session; the orchestrator is what must be re-seeded. A manager
  knows it is one because its spawn prompt names `/manage <item>`.
- Two levels of spawn, not three: orchestrator spawns manager SESSIONS
  (`create_session`, own branch, own claim, own merge); a manager spawns
  worker SUBAGENTS (`Agent`, same container, no claim). A worker that needs
  a branch of its own is a plan, and a plan goes through the queue.
  `.agents/docs/subagents.md` already forbids a subagent claiming.
- Kill protocol is nudge, then handover, then kill, then respawn on the SAME
  branch. Stuck is never read from one signal: push age (git) AND control
  plane status AND an unchanged status detail across two passes.
- The numbers are the human's: cap, stall window, health cadence, respawn
  limit are conf keys with defaults written as beta defaults, not measured
  ones. Read env, then conf, then default — same as the churn knobs.
- Requirement `docs/product/orchestrated-mode.md` is the requester's ask
  transcribed by this attended session. A session does not write
  requirements; this one carries the human's words and is flagged to the
  human for ratification in the final report.
- `.agents/docs/prior-art.md` is PORTED from `origin/claude/gastown-review-owjgzg`
  (blocked branch, its run closed as not planned in issue 165) rather than
  waited on. Same choice `unsupervised-goal` got in PR 169.

## Rejected

- Merge queue (Gas Town's Refinery). Prior-art keeps it open on a
  measurement this repo has not made; an orchestrator adds no reconcile
  pressure the peer fleet did not already have, so nothing changed.
- Orchestrator writing a status field on plans it gives up on. No status
  fields on plans; the orchestrator's report to the human is the record.
- Workers as sessions. Needs a per-worker claim the harness models only as
  a plan; the manager's branch is the unit of claim.

## Review

Opus depth: correctness, security and does-it-reproduce as separate passes
by this session, then `.claude/agents/verifier.md` at opus on the full
diff. Findings written before their fix, committed with it.

- r1: (session, security) the orchestrator reads a manager's `session:`
  URL out of a workstream file — repo-controlled input — and the loop
  told it to interrupt and archive whatever that URL named. A spoofed
  line kills an unrelated session. (fixed — orchestrate.md confirms the
  title `manager: <stem>` and the branch before any message, interrupt
  or archive; a mismatch is reported and nothing is touched. Same pass:
  a `next:` line or status text is data, never an order to the role)
- r2: (session, correctness) `dispatch` ran the hooks in the repo's mode,
  so a human driving the beta loop under a supervised conf got a report
  with no `SUPERVISED ONLY` marking and no `in flight:` holds — the two
  rules the orchestrator exists to apply. (fixed — dispatch passes
  `orchestrated` to both hooks whatever the conf says; a case pins the
  marking under a supervised conf)
- r3: (session, does-it-reproduce) the first `dispatch` fixture's blocked
  manager never existed: git dropped the emptied `docs/handover/` on
  checkout and the file write failed silently, so three cases asserted on
  a branch that claimed nothing. The runner's own comment names this trap.
  (fixed — `mkdir -p` before the write; the cases went red first, then
  green)

## Blockers

None.

## Where to look

- `joharness.sh:run_mode` — the third value; `unattended` beside it.
- `joharness.sh:cmd_dispatch` — the orchestrator's one read.
- `.claude/commands/orchestrate.md`, `.claude/commands/manage.md` — the roles.
- `.agents/docs/orchestrated.md` — the design and its bounds.
