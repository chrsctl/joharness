---
plan: scout-reviewer-trigger
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 460
scope: shared:joharness.sh, shared:.claude/commands/scout.md, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:.agents/scripts/conf-keys.sh, shared:.agents/harness/selftest/scout.sh, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

A scout pass runs on a clock (168 h, only at `DRAINED`) or a backlog
trigger (open plans below N, 24 h re-arm). Neither is what the reviewer
wants. A reviewer's question on a proposal never makes a pass due (#460
§1), and a human cannot start one without breaking §0.4 (#460 §2). The
one real gx pass ran with the gate waived by chat. #461 item 1 measures
the weight: 301 lines of scout block in `joharness.sh` and 6 knobs.

Decided by the owner in the clerk session, 2026-10-13 (issue #461 item 1,
answered "Reviewer-only trigger"; AUTOMERGE answered "Remove it"):

- A pass runs when the reviewer orders it: `/scout` typed by a human, or the orchestrator's `+human` extra session.
- Or when an OPEN `scout` issue has a counting comment newer than the scout's last `scout:` comment. The orchestrator reads that with its GitHub tools; `joharness.sh` stays git-only.
- Drop the clock, the `DRAINED` coupling, the backlog trigger and its re-arm, the merged-retire reader, and the ceiling arithmetic.
- Remove the knobs `JOHARNESS_SCOUT_HOURS`, `JOHARNESS_SCOUT_BACKLOG` and `JOHARNESS_SCOUT_AUTOMERGE`.
- "At most 3 proposals a pass" is written in scout.md.

The pull request closes #460 (`Closes #460`; `Refs #461`).

## Scope

- `joharness.sh` scout block (`# --- The scout cycle` to `scout_report_lines`): remove `scout_due`'s clock and backlog branches, `scout_retired_ts`'s merged reader, `scout_n_plans` and the ceiling, `scout_automerge`; keep `scout_refs`/`scout_walk` and the `IN FLIGHT` row, `scout_brief_present`, `scout_reviewer`, `scout_research`. `cmd_scout` prints no `cadence`/`backlog` lines; it says a pass runs on the reviewer's order. Target under 100 lines for the block (#461); count it at merge.
- `joharness.sh:cmd_dispatch` — the scout cycle no longer prints `scout DUE: spawn` from a clock; it prints the in-flight scout row only. Remove `scout_due`/`scout_backlog` gating around the DRAINED verdict.
- `.claude/commands/orchestrate.md` — scout row of the role table: spawn `/scout` when (a) the human orders it (`+human`, existing rule), or (b) `list_issues` label `scout`, state OPEN, shows an issue whose newest counting comment (same definition as `clerk.md` §2) is newer than the newest `scout:` comment on it; at most one scout per run; never while dispatch shows one in flight.
- `.claude/commands/scout.md` §0, §1 — preconditions drop `not due`, the `DUE: spawn` check and the ceiling; the twin check keeps fetch + `./joharness.sh scout` showing your row only. Write "at most 3 proposals a pass". `## Never` keeps only rules with a mechanism behind them (#461 item 6).
- `.agents/docs/orchestrated.md` and `.agents/scripts/conf-keys.sh` — remove the three knobs' rows and the clock/backlog prose.
- `.agents/harness/selftest/scout.sh`, `.agents/harness/selftest/dispatch.sh` — drop cases for removed behaviour; add: `cmd_scout` prints no `cadence`; dispatch prints no `scout DUE: spawn` with the clock long past.

## Out of scope

- Approval (`scout-approval-by-comment`), budget and digest (`scout-budget-by-count`).
- `joharness.conf`: its commented `#JOHARNESS_SCOUT_HOURS` and `#JOHARNESS_SCOUT_AUTOMERGE` lines are a core path. List them in the pull request body for the human to delete.
- Teaching `joharness.sh` to read GitHub.

## Acceptance

- `grep -c 'JOHARNESS_SCOUT_HOURS\|JOHARNESS_SCOUT_BACKLOG\|JOHARNESS_SCOUT_AUTOMERGE' joharness.sh .claude/commands/*.md .agents/docs/orchestrated.md .agents/scripts/conf-keys.sh` — all `0`.
- `./joharness.sh scout | grep -c 'cadence\|backlog'` — `0`.
- `awk '/# --- The scout cycle/,/^scout_report_lines/' joharness.sh | wc -l` — under 100, recorded with the date.
- `grep -n 'newer than' .claude/commands/orchestrate.md` — the comment trigger in the scout row.
- `bash .agents/harness/selftest.sh` (the runner only) — new cases PASS; reverted, they FAIL.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Plan ships: consumer check = on `chrsctl/gx` after sync, `./joharness.sh scout` prints no `cadence` line and the orchestrator's scout row reads the comment trigger.

## Where to look

- `joharness.sh:scout_due`, `scout_retired_ts`, `scout_n_plans`, `scout_automerge`, `cmd_scout`, `cmd_dispatch` (the scout cycle and the DRAINED verdict).
- `.claude/commands/orchestrate.md` — role table scout row; "The human orders an extra role session".
- `.claude/commands/scout.md` — "## 0. Preconditions", "## 1. Claim", "## Never".
- `.claude/commands/clerk.md` §2 — the counting-comment definition to reuse.
- Issue #461 items 1 and 6.

## Traps

- `joharness.sh` stays git-only: the comment trigger lives in the orchestrator.
- Never edit `joharness.conf` (core path): list its stale lines for the human.
- `dispatch_freeable` and the DRAINED verdict are shared with every role: change only the scout terms.
- Many files are `shared:` with other scout plans: merge `origin/main` in before the pull request.
