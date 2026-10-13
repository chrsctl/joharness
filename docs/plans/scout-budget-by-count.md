---
plan: scout-budget-by-count
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 461
scope: shared:.claude/commands/scout.md, shared:joharness.sh, shared:.agents/docs/orchestrated.md, shared:.agents/scripts/conf-keys.sh, shared:.agents/scripts/bootstrap-consumer.sh, shared:.agents/harness/selftest.sh, shared:.agents/harness/selftest/scout.sh, shared:.agents/harness/selftest/bootstrap-consumer.sh
---

## Goal

The scout stops outside reads when `get_session` `usage.cost_usd` reaches
`JOHARNESS_SCOUT_BUDGET_USD`, but that reader is the session total and did
not move inside a turn (#453: four reads at $2.09, $4.06 at exit), and
`orchestrated.md` already records it as frozen on live sessions ("Nor
frozen cost"). The digest (§7) repeats the report's list in the reviewer's
inbox. #461 items 3 and 5: budget by a count the scout can see, the cost
stated as the session's figure, no digest. One of three plans for #461
(with `scout-approval-by-comment`, `scout-reviewer-trigger`); the pull
request body also says `Closes #453`.

## Scope

- `.claude/commands/scout.md` §3 — at most R outside reads a pass (R from `./joharness.sh scout`'s `research  :` line), counted by the scout in `## Decisions`; reaching R = stop reading, report `BUDGET: <R> reads`. No `get_session` before each read.
- `.claude/commands/scout.md` §6 — the `cost:` line is read once when the issue is filed, written `cost: <usd> USD (get_session usage.cost_usd when filed, session total, <UTC date>)`: a lower bound on the session, never the pass's own cost. No later body edit for it. §8's report states the figure read at exit the same way.
- `.claude/commands/scout.md` §7 Digest — removed; §8's report lists the proposals ranked instead.
- `joharness.sh:scout_report_lines` — the `research  :` line prints `budget <R> outside reads a pass (JOHARNESS_SCOUT_READS)`, default 12 via `num_knob`; `JOHARNESS_SCOUT_BUDGET_USD` is no longer read.
- `.agents/docs/orchestrated.md`, `.agents/scripts/conf-keys.sh`, `.agents/scripts/bootstrap-consumer.sh` (seeded keys), `.agents/harness/selftest.sh` (env scrub list) — replace `JOHARNESS_SCOUT_BUDGET_USD` with `JOHARNESS_SCOUT_READS` (default 12).
- `.agents/harness/selftest/bootstrap-consumer.sh` — its seeded-keys check stays green with the new key.
- `.agents/harness/selftest/scout.sh` — assert the new `research  :` wording.

## Out of scope

- Approval and trigger: plans `scout-approval-by-comment`, `scout-reviewer-trigger`.
- `joharness.conf` (core path): a stale `JOHARNESS_SCOUT_BUDGET_USD` line there, if any, is listed in the pull request body for the human.

## Acceptance

- `grep -rc 'BUDGET_USD' joharness.sh .claude/commands .agents/docs .agents/scripts .agents/harness | grep -v ':0$'` — no output.
- `./joharness.sh scout | grep 'research  :'` — names `outside reads` and `JOHARNESS_SCOUT_READS`.
- `grep -c '^## 7. Digest' .claude/commands/scout.md` — `0`; `sed -n '/^## 3/,/^## 4/p' .claude/commands/scout.md | grep -c get_session` — `0` (non-zero on main today).
- `bash .agents/harness/selftest.sh` (the runner only) — the new assertion PASSes; reverted, it FAILs.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- `wc -l .claude/commands/scout.md` recorded in the workstream file with the date (#461's target: near 144).
- Plan ships: consumer check = on `chrsctl/gx` after sync, `./joharness.sh scout` prints the reads budget.

## Where to look

- `.claude/commands/scout.md` — "## 3. Read, outside", "## 6. Propose", "## 7. Digest", "## 8. Report and retire".
- `joharness.sh:scout_report_lines` — the `research  :` printf; `joharness.sh:num_knob`.
- `.agents/scripts/bootstrap-consumer.sh` — seeded `JOHARNESS_SCOUT_*` keys.
- `.agents/docs/orchestrated.md` — "Nor frozen cost", knob table.
- `.agents/scripts/conf-keys.sh` — the `JOHARNESS_SCOUT_BUDGET_USD` line.

## Traps

- Never end a turn to refresh a reader: an unattended scout stays IDLE.
- Never edit `joharness.conf` (core path).
- Shared files with the other scout plans: merge `origin/main` in before the pull request.
- Test for a fix must FAIL without it.
