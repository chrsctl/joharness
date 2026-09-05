---
workstream: orchestrated-mode
status: review
branch: claude/unsupervised-orchestrated-mode-tzdvw2
pr: none
plan: orchestrated-mode
issue: none
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
agent: opus
updated: 2026-09-05
next: ci green after round two; open the pull request per step 7 (retire this file and the same-session plan in the last commit before it), then merge
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
- `.agents/docs/prior-art.md` stays retired. A first draft of this branch
  restored it from `origin/claude/gastown-review-owjgzg`, not knowing
  `main` had deleted it the day before (`a14a804`, 2026-09-04: arguments
  live in the documents that own each decision, quotations dropped, the
  NOTICE entry with them). Reverting a merged decision unread is the
  finding (r4); what Gas Town gave this mode is paraphrased in
  `orchestrated.md`, ideas only, with a NOTICE entry of the same shape as
  the graph-engineering one.
- `joharness.conf` joins `protocol_paths`. Found by the verifier (r7): the
  run plan, scoped to the conf, read as free work for the fleet whose mode
  it flips. The mode line is what `authority` verifies; a session that may
  rewrite it authorises itself.
- No beta path past `authority`. Both role commands first said "supervised
  = a human invoked this, proceed"; the session cannot check that claim
  (r10). The beta run flips the mode through a pull request first.

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

Round two — verifier at opus on f9d5c95, each finding re-checked by this
session against its source before being accepted:

- r4: (verifier) `.agents/docs/prior-art.md` restored whole, with four new
  Gas Town quotations, one day after `main` deleted it with a written
  rationale (`a14a804`) and removed the NOTICE entry covering exactly
  those quotations; `consumer-repos.md` still tells every consumer to
  `git rm` the file the sync would re-deliver. (fixed — file deleted
  again; what the mode took from Gas Town is paraphrased in
  `orchestrated.md`, ideas only, with a NOTICE entry of the
  graph-engineering shape; every link to prior-art rewritten to the
  document that owns the argument)
- r5: (verifier) the workstream record called the branch "waited on"
  where `main` had decided; reverting a merged decision unread is the
  defect, and the record hid it. (fixed — Decisions says so)
- r6: (verifier) the hold rule dropped the free side's `shared:` paths
  before comparing, so `sharer` (`shared: src/x`) against a claimed
  `holder` (`src/x`) got no hold where the waves split them; and a claimed
  plan scoped only to shared paths was skipped outright. (fixed — the hook
  calls `wave_split_hit` with all four scope halves; a case pins the
  one-sided shared hold)
- r7: (verifier) `docs/plans/orchestrated-run.md`, scoped to
  `joharness.conf`, read as free work for an unattended fleet: `drain` and
  `dispatch` both offered it, and its first Scope bullet flips the mode. A
  prose gate in a plan is what attempt four proved a fleet does not read.
  (fixed — `joharness.conf` joins `protocol_paths`, with the reason at the
  list: the mode line is what `authority` verifies, and a session that may
  rewrite it authorises itself; the guard's path loop counts 7)
- r8: (verifier) `dispatch` said `DRAINED — nothing in flight: exit` over
  a plan on HOLD behind a BLOCKED branch, so every heartbeat generation
  exited and the held plan starved on a human's clock. (fixed — a hold
  behind a blocked branch is released, the reconcile named as the cost)
- r9: (verifier) `dispatch` forced both hooks to `orchestrated` under a
  supervised conf and printed NOT YOURS over a plan `drain` was handing
  out on the same tree — two readers, two answers, the PR 170/187/190
  failure — and falsified unsupervised.md's supervised-sees-nothing claim.
  (fixed — under any other mode `dispatch` prints NOT ORCHESTRATED and
  stops, naming the preview; r2's forced-mode fix is withdrawn with it,
  since the scenario it served no longer exists)
- r10: (verifier) both role commands told a session to proceed on
  `authority`'s NOT CLAIMED — "a human invoked this" — the first
  proceed-anyway path past the repository-authorises rule, and a claim
  the session cannot check. (fixed — anything but VERIFIABLE is a stop in
  both commands; the beta run flips the mode through a pull request)
- r11: (verifier) `n_free` counted wave-2 rows the same output told the
  reader not to spawn. (fixed — WAIT rows counted separately; the verdict
  says what may be spawned now and how many wait)
- r12: (verifier) `check_choice`'s `"$c")` arm matched an EMPTY value
  when the third choice was empty, so `--review ""` died silently under
  `set -e` instead of being refused with a message. (fixed — tested
  outside the case; a case pins the refusal and one pins `--mode
  orchestrated` accepted)
- r13: (verifier) two branches unpinned: the orchestrated gate on the
  `in flight:` lines, and the handover hook's rules pointer — mutating
  either left the suite green. (fixed — cases for both; `mutate` now reds
  2 and 1 cases respectively, run 2026-09-05)
- r14: (verifier) the perf gate measured the queue hook under
  `unsupervised` only, so the per-claimed-plan fork this mode adds ran
  unbudgeted. (fixed — a `queue-orchestrated` row, budget 141 against a
  shape count of 126, `./joharness.sh perf queue-orchestrated` 2026-09-05)
- r15: (verifier) nudge memory and the respawn count lived only in the
  orchestrator's context window across hour-long `send_later` wakes,
  against the requirement's own no-state-store constraint. (fixed — the
  wake message carries the ledger: nudged items with the head at the
  nudge, respawns per item; read from the message, written into the next)
- r16: (verifier) the four knobs are not in `conf-keys.sh`, so no
  consumer's update names them. (wontfix — that registry drives the
  bootstrap interview, which asks every key it declares; four questions
  about a beta mode the interview never offers is the wrong cost, and the
  bootstrap already says the mode is set by hand after reading
  `orchestrated.md`, where the knobs are. Revisit when the mode leaves
  beta)
- r17: (verifier) `docs/product/orchestrated-mode.md` is a requirement
  written by a session; honest in the diff, and it lands on `main` as a
  goal nobody set if the human does not ratify it. (no change — flagged
  in the final report as the human's to ratify or delete)
- r18: (verifier) `list_sessions` with `mine: true` cannot see another
  account's orchestrator, and two firing in one minute both pass the
  title check. (fixed in part — `mine` dropped; the same-minute race is
  named in the command and resolved by claim-by-push at the manager level)
- r19: (verifier) `JOHARNESS_MAX_MANAGERS=0` read as "wait for a manager
  to finish" forever. (fixed — cap 0 is PAUSED, the human's pause; the
  orchestrator exits)
- r20: (verifier, nit) a claim from a remote other than `origin` gets
  "push age unknown". (no change — said as unknown, never as zero)

## Blockers

None.

## Where to look

- `joharness.sh:run_mode` — the third value; `unattended` beside it.
- `joharness.sh:cmd_dispatch` — the orchestrator's one read.
- `.claude/commands/orchestrate.md`, `.claude/commands/manage.md` — the roles.
- `.agents/docs/orchestrated.md` — the design and its bounds.
