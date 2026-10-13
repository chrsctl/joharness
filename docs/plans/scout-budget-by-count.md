---
plan: scout-budget-by-count
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 461
scope: shared:.claude/commands/scout.md, shared:joharness.sh, shared:.agents/docs/orchestrated.md, shared:.agents/scripts/conf-keys.sh, shared:.agents/harness/selftest/scout.sh
---

## Goal

The scout stops outside reads when `get_session` `usage.cost_usd` reaches
`JOHARNESS_SCOUT_BUDGET_USD`, but that reader is the session total and did
not move inside a turn (#453: four reads at $2.09, $4.06 at exit), and
`orchestrated.md` already records it as frozen on live sessions ("Nor
frozen cost"). The digest (§7) repeats the report's list in the reviewer's
inbox. #461 items 3 and 5: budget by a count the scout can see, cost read
once at exit and stated as the session's figure, no digest. The pull
request closes #453 (`Closes #453`) and, as the last #461 plan, #461
(`Closes #461` if no other queued plan names it, else `Refs`).

## Scope

- `.claude/commands/scout.md` §3 — at most R outside reads a pass (R from `./joharness.sh scout`'s `research  :` line), counted by the scout in `## Decisions`; reaching R = stop reading, report `BUDGET: <R> reads`. No `get_session` before each read.
- `.claude/commands/scout.md` §6 and §8 — `cost:` = `usage.cost_usd` read once at exit, written `cost: <usd> USD (get_session usage.cost_usd at exit, session total, <UTC date>)`.
- `.claude/commands/scout.md` §7 Digest — removed; §8's report lists the proposals ranked instead.
- `joharness.sh:cmd_scout` — the `research  :` line prints `budget <R> outside reads a pass (JOHARNESS_SCOUT_READS)`, default 12 via `num_knob`; `JOHARNESS_SCOUT_BUDGET_USD` is no longer read.
- `.agents/docs/orchestrated.md`, `.agents/scripts/conf-keys.sh` — replace the `JOHARNESS_SCOUT_BUDGET_USD` row with `JOHARNESS_SCOUT_READS|12|…`.
- `.agents/harness/selftest/scout.sh` — assert the new `research  :` wording.

## Out of scope

- Approval and trigger: plans `scout-approval-by-comment`, `scout-reviewer-trigger`.
- `joharness.conf` (core path): a stale `JOHARNESS_SCOUT_BUDGET_USD` line there, if any, is listed in the pull request body for the human.

## Acceptance

- `grep -c 'BUDGET_USD' joharness.sh .claude/commands/scout.md .agents/docs/orchestrated.md .agents/scripts/conf-keys.sh` — all `0`.
- `./joharness.sh scout | grep 'research  :'` — names `outside reads` and `JOHARNESS_SCOUT_READS`.
- `grep -c '^## 7. Digest' .claude/commands/scout.md` — `0`; `grep -c 'get_session' .claude/commands/scout.md` — only the exit read and §2's cost reader.
- `bash .agents/harness/selftest.sh` (the runner only) — the new assertion PASSes; reverted, it FAILs.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- `wc -l .claude/commands/scout.md` recorded in the workstream file with the date (#461's target: near 144).
- Plan ships: consumer check = on `chrsctl/gx` after sync, `./joharness.sh scout` prints the reads budget.

## Where to look

- `.claude/commands/scout.md` — "## 3. Read, outside", "## 6. Propose", "## 7. Digest", "## 8. Report and retire".
- `joharness.sh:cmd_scout` — the `research  :` printf; `joharness.sh:num_knob`.
- `.agents/docs/orchestrated.md` — "Nor frozen cost", knob table.
- `.agents/scripts/conf-keys.sh` — the `JOHARNESS_SCOUT_BUDGET_USD` line.

## Traps

- Never end a turn to refresh a reader: an unattended scout stays IDLE.
- Never edit `joharness.conf` (core path).
- Shared files with the other scout plans: merge `origin/main` in before the pull request.
- Test for a fix must FAIL without it.
