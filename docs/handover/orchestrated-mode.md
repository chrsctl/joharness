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
next: ci green after round three; open the pull request per step 7 (retire this file and the same-session plan in the last commit before it), then merge
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
- Loops are found from git, not from silence: `dispatch` prints commits
  since the base, the most rewritten file with its count (`churn_top`, the
  same metric `ci` warns the session with) and findings recorded; `LOOP?`
  at the churn threshold. The respawn after a loop carries the record and
  the churn rule, one tier up — the harness's own escalation, so the
  orchestrator picks no tier of its own.
- Roles read their own documents only. Under orchestrated, session start
  runs the handover hook with `HANDOVER_SCOPE=branch` (own files, no walk
  over remote refs) and skips the queue hook; both commands carry a
  read list and a never-open list. The orchestrator reads dispatch, the
  control plane and the Lineup table.
- The three open questions, answered on the requester's delegation
  ("Research and answer the 3 questions"): the requirement stands, with
  that provenance in its Goal; the knob defaults are measured from
  `origin/main` (2026-09-05: cap 4 = p90 of branches active per hour,
  stall 45 = p95 commit gap of 44 minutes, health 10 between the median
  gap and its p75; respawn limit still unmeasured) — command and counts
  in `orchestrated.md`; no heartbeat exists (`list_triggers`, one disabled
  one-shot for another repo) and the queue holds one research item, so
  the run waits on the Routines UI and on plans the human queues.
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
  goal nobody set if the human does not ratify it. (fixed — the requester
  answered "Research and answer the 3 questions"; the file now carries
  that delegation as its provenance line, and the change is said here
  rather than left as "no change", which r38 caught)
- r18: (verifier) `list_sessions` with `mine: true` cannot see another
  account's orchestrator, and two firing in one minute both pass the
  title check. (fixed in part — `mine` dropped; the same-minute race is
  named in the command and resolved by claim-by-push at the manager level)
- r19: (verifier) `JOHARNESS_MAX_MANAGERS=0` read as "wait for a manager
  to finish" forever. (fixed — cap 0 is PAUSED, the human's pause; the
  orchestrator exits)
- r20: (verifier, nit) a claim from a remote other than `origin` gets
  "push age unknown". (no change — said as unknown, never as zero)

Round three — the requester's two asks (loop detection with a recorded
respawn; each role reads only its own documents) and the three answered
questions; verifier at opus on the uncommitted delta over 0944070, each
finding re-checked against its source before being accepted:

- r21: (verifier) `doc` was not reset per in-flight row, so a branch the
  handover hook did not list — the 13th, under its default cap of 12 —
  printed its neighbour's finding count, and the LOOP record would have
  copied it. (fixed — every per-row value reset, `drain_hook` lifts
  `HANDOVER_MAX_ENTRIES` for readers that parse, findings read only from
  a document actually read)
- r22: (verifier) `LOOP?` fired at ci's WARNING threshold and took the
  CEILING's action; `JOHARNESS_CHURN_LIMIT` was read nowhere but `ci`.
  (fixed — the kill line is the limit, default twice the threshold, 0
  lifts it; the threshold names a warning on the work line; the conf
  says the two knobs are ci's too)
- r23: (verifier) a loop that went quiet printed STALL? only and got the
  plain kill: no record, no research step, no escalation. (fixed — the
  marks are independent and print side by side; a quiet-loop case pins
  it)
- r24: (verifier) the ledger carried one snapshot, so "head moved on 3
  passes with `next:` unchanged" was unevaluable, and the doc said "two
  passes". (fixed — `same=<n>` counts the passes; the rule reads
  `same=2` in the ledger plus this pass)
- r25: (verifier) a released hold that was also a wave-2 row lost its
  WAIT and went out beside its partner. (fixed — WAIT first; a released
  hold never lifts a same-pass collision)
- r26: (verifier) `PAUSED` said exit with managers in flight, orphaning
  them mid-run. (fixed — with anything in flight the health pass goes on;
  exit only over an empty fleet; case pins it)
- r27: (verifier) the banner and the compaction pointer named
  `.agents/docs/orchestrated.md`, the document both role commands forbid
  opening. (fixed — both point at the role's command, which IS its rules;
  the design doc is why-explanation and stays off both read lists)
- r28: (verifier) `manage.md` ended by running `drain`, which prints the
  queue and other branches' files the same command forbids reading.
  (fixed — merged means message the orchestrator and exit; no queue
  command)
- r29: (verifier) `orchestrate.md` Never forbade opening another branch's
  workstream file while KILL and LOOP read and write it. (fixed — the
  carve-out is stated at the ban)
- r30: (verifier) "prompt = exactly this block" contradicted the resume
  and loop lines other steps add, and a manager spawned into a released
  hold was never told the reconcile it would pay. (fixed — the block
  plus, when they apply, four named lines)
- r31: (verifier) `AGENTS.md` step 2 and the handover README still said
  the queue and the overlap print at every session start. (fixed — both
  name the orchestrated exception)
- r32: (verifier) the run plan's recovery command returned nothing: the
  endurance workstream file was never deleted, it is still on its branch.
  (fixed — `git show origin/claude/gastown-review-owjgzg:…`)
- r33: (verifier) `git ls-tree` without `-r` printed one directory name,
  not the file the bullet claimed. (fixed)
- r34: (verifier) the percentile awk took one rank too high on whole
  products, p90 28 where the 90th percentile is 27, and the pipeline had
  no `-200` bound. (fixed — nearest rank, ceil(p x N); `-200`; re-run
  2026-09-05: gaps=530 median=4 p90=27 p95=44, hours=137 median=2 p90=4
  max=9)
- r35: (verifier) the conf called 45 the measurement; the measurement is
  44. (fixed — "rounded")
- r36: (verifier) raising the churn threshold silently moves ci's
  ceiling. (fixed — said beside both knobs)
- r37: (verifier) the Gas Town paraphrase carried claims with no path
  beside them, the day after `main` dropped unsourced ones. (fixed — a
  path beside each)
- r38: (verifier) r17 said "no change" for a file the delta changed.
  (fixed — r17 corrected)
- r39: (verifier) the design doc restated the whole LOOP procedure, a
  second copy of the command. (fixed — the doc keeps the why and points
  at the command; one health table)
- r40: (verifier) `effort: xhigh` was written into a workstream file
  whose template has no such field. (fixed — effort crosses as prose in
  the successor's prompt, which is the only way it crosses)
- r41: (verifier) the perf row overflowed its column; its budget is the
  supervised row's, and the built shape exercises none of the
  orchestrated fork. (fixed the column; the budget stays 141 as the same
  margin, said in the row comment — the shape carries no claimed plan
  and building one there is a change to `perf_shape`, a plan for a
  supervised session if the number ever matters)
- r42: (verifier) two branches untested — the WAIT-only verdict and
  STALL-over-LOOP precedence. (fixed in part — the precedence is gone and
  the quiet-loop case pins both marks; the WAIT-only verdict stays
  unreachable while a partner is free and earlier, said in the code)

Diagram from the requester, 2026-09-05, verified against the build:

- Every hour, a dispatcher runs the queue reading and takes what it
  names: holds (`dispatch`, the heartbeat).
- Worker per item at the item's tier, one item per session, the Loop to
  a merged pull request: holds (the diagram's worker is this build's
  manager; the build adds worker subagents beneath it).
- Requirement to decompose goes to opus at xhigh: did NOT hold — the
  build sent a sonnet planning manager. Adopted: `dispatch` and the
  command say opus, effort xhigh.
- A merge wakes the dispatcher so the next item starts at once: did NOT
  hold — passes ran on the clock only. Adopted: the spawn prompt carries
  the orchestrator's session id, the manager messages "merged <stem>" on
  merge, the orchestrator runs a pass on that message.
- Dispatcher on Sonnet: the ask said low tier and the build wrote haiku;
  the tier is the Routine's model field, one word, and the roles table
  now says both and leaves it to the run.
- Kuba is human, writes a requirement, commits to main: holds
  (`product/README.md`, Human writes).
- Queue empty stops: holds, with one addition the diagram does not draw
  — managers still in flight keep the health pass going.
- Not in the diagram, added by the requester's later asks: health, kill,
  loop detection, holds and waves, the cap, per-role reading lists.

## Blockers

None.

## Where to look

- `joharness.sh:run_mode` — the third value; `unattended` beside it.
- `joharness.sh:cmd_dispatch` — the orchestrator's one read.
- `.claude/commands/orchestrate.md`, `.claude/commands/manage.md` — the roles.
- `.agents/docs/orchestrated.md` — the design and its bounds.
