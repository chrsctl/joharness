---
workstream: merged-ref-batch-prose
status: review
branch: claude/drain-8jr601
pr: none
plan: merged-ref-batch-prose-vs-code
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Retire this file and the same-session plan, open the pull request, merge when checks are green
---

## Goal

Close `docs/research/merged-ref-batch-prose-vs-code.md`: three sentences
left beside the merged-ref batch no longer say what their subject measures.
Repair them, land the why in the file `graduates:` names, delete the node.
Same-session plan `docs/plans/merged-ref-batch-prose.md` carries scope and
tier; deleted in the same pull request.

## Decisions

- Taken as `/drain`'s item on 2026-09-16: `drain` named PR #10's branch as
  edge work, but PR #10 is CLOSED unmerged (2026-08-21) and its session is
  not in `list_sessions`, so it is deadwood for a human to triage, not work.
  Curate: nothing due. No open issue. `docs/plans/orchestrated-run.md` is
  older but its own BEFORE YOU START gates on money and a stocked queue the
  human decides; the research node is the oldest thing a session can act on.
- WEAK row re-measured: the canonical runner counts what a laptop counts.
  GitHub run 567 on `main` (2026-09-12, job `lint`, `./joharness.sh ci`)
  printed session-start 276/287, queue-context 104/117, drain 287/308 —
  identical to `./joharness.sh perf` here on 2026-09-16. The +1 the
  consumer's workflow recorded is that repo's, so headroom on session-start
  is 11 here, not 10.
- Finding 3: restate the headroom as counted, not raise the four budgets.
  `perf_rows`' own doctrine sizes a ceiling from the regression it must
  catch (+25 per ref, +20 per edge) and says to LOWER a literal on the same
  terms as raising one; raising four budgets to recover a number the prose
  liked would be taste, the thing the sentence disclaims.

- The `drain` row's gate reading (287) is 21 under its budget, so a +20
  per-edge fork passes; the budget was sized against the 297 curate case.
  Pre-batch the row read 336 against 357 — the gap is older than the batch.
  Written into the doctrine paragraph, not fixed: pinning
  `JOHARNESS_CURATE_PLANS=1` in the row changes what the gate measures,
  which this plan's Out of scope excludes. A follow-up plan if wanted.

## Rejected

- Raising `PERF_BUDGET_*` to keep 14 — see Decisions.
- Deleting the two historical citations of 14 (`perf_shape` note,
  the env-pinning comment) — they record measurements of their day and
  say so now; deleting measurements is how folklore starts.

## Review

- r1: (code-review) the doctrine paragraph blamed the batch for the drop from 14 to 11, but the batch table below it takes 49/49 and 24/24 off both sides — the drop is drift before the batch (session-start 322 to 325 against an unchanged 336). (fixed — cause restated as drift, batch credited with carrying headroom across)
- r2: (code-review) the `perf_shape` inventory said one `for-each-ref --merged` covers merged refs, but `cmd_graph` still runs `merge-base --is-ancestor` per ref inside the `graph` row's budget. (fixed — sentence scoped to the two session-start hooks, `graph` named)
- r3: (code-review) consumer-repos.md said the key stage writes "never in the file" and named `conf-keys.sh` as the stage; `sync-to-consumer.sh:report_conf_keys` appends `KEY=default` on a `y` from a terminal. (fixed — stage named correctly, terminal and headless cases both stated; the claim that survives is that canonical's comment block never reaches)
- r4: (code-review) the paragraph forbidding pointers at records a copy may not carry ended with a recovery command for a path that never existed in a consumer, in a file that ships. (fixed — command qualified as canonical-history only)
- r5: (code-review) "the one deliberate exception" and "the rest sit at 11 to 16" both skipped `bash-guard` 0/0. (fixed — named as the second deliberate row)
- r6: (verifier) the dropped step 7 clause was the only pointer to a fact with no other landing site in what ships: `JOHARNESS_CHECKS` saves the wait, never Actions minutes, and the repo variable set alone with the conf at `github` leaves no machine checking — `finish`'s own output never says so (`checks_gate`). The research node's "the repair is a deletion" did not hold against the code. (fixed — the clause now points at the one copy, `ci.yml`'s `lint` job, which the seed ships together with the `if:` that creates the trap; consumer-repos.md says the same instead of "already the sentence before it")
- r7: (verifier) the key stage was attributed to `conf-keys.sh`, which is sourced and prints nothing; the report is `sync-to-consumer.sh:report_conf_keys`. Same defect r3 found from the other side. (fixed in round 1 with r3)
- r8: (verifier, clean) re-counted every number in the diff: `perf` and the `CURATE_PLANS=1` drain row match, and run 567's `lint` log on GitHub prints the same nine rows — the runner claim is GROUNDED. No change needed.
## Blockers

None.

## Where to look

- `joharness.sh:perf_rows` — the budget doctrine and the batch note above it.
- `.agents/docs/consumer-repos.md` "Settings a child wants to CHANGE" — the
  conf-comment rule finding 1 widens.
