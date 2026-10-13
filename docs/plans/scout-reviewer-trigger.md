---
plan: scout-reviewer-trigger
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 461
scope: shared:joharness.sh, shared:.claude/commands/scout.md, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:.agents/scripts/conf-keys.sh, shared:.agents/scripts/bootstrap-consumer.sh, shared:.agents/harness/selftest.sh, shared:.agents/harness/selftest/scout.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.agents/harness/selftest/clerk.sh, shared:.agents/harness/selftest/bootstrap-consumer.sh
---

## Goal

A scout pass runs on a clock (168 h, only at `DRAINED`) or a backlog
trigger (open plans below N, 24 h re-arm). Neither is what the reviewer
wants:
- A reviewer's question on a proposal never makes a pass due (#460 §1).
- A human cannot start a pass without breaking §0.4 (#460 §2).
- The one real gx pass ran with the gate waived by chat.

#461 item 1 measures the weight: 302 lines from `# --- The scout cycle` to
`scout_report_lines`, and 6 knobs.

Decided by the owner in the clerk session, 2026-10-13 (#461 item 1:
"Reviewer-only trigger"; AUTOMERGE: "Remove it"; recorded on #461):

- **A pass runs** when:
  - the reviewer orders it — `/scout` typed by a human, or the orchestrator's `+human` extra session; or
  - the orchestrator sees a `scout` issue that needs the scout (below). `joharness.sh` stays git-only.
- **Dropped:** the clock, the `DRAINED` coupling, the backlog trigger and its re-arm, the merged-retire reader, and the ceiling.
- **Knobs removed:** `JOHARNESS_SCOUT_HOURS`, `JOHARNESS_SCOUT_BACKLOG` and `JOHARNESS_SCOUT_AUTOMERGE`.
- **Off switch:** an empty `JOHARNESS_SCOUT_REVIEWER` replaces `HOURS=0`. With no reviewer, nothing can be approved, so no scout is ever spawned.

One of three plans for #461. The pull request body also says `Closes #460`.

## Scope

- `.claude/commands/orchestrate.md` — scout row of the role table. Spawn `/scout` (at most one per run, never while dispatch shows a scout in flight, never with `reviewer : none`) when either:
  - the human orders it — the existing `+human` rule; or
  - `list_issues` label `scout`, state OPEN, shows an issue that needs the scout, AND that issue is NOT approved (`clerk.md` THE SCOUT GATE) AND NOT under `planned` in `./joharness.sh clerk`. An issue needs the scout when either:
    - (i) its newest counting comment (`clerk.md` §2's definition) is newer than its newest `scout:` comment; or
    - (ii) its title does not start `scout:` and it has no `scout:` comment at all: a new research request.
- `.claude/commands/scout.md` §4 — every issue the trigger named gets exactly ONE `scout:` comment this pass: the answer, or `scout: noted — nothing asked`. That quiets the trigger. An approved issue is never answered (the trigger excludes it).
- `.claude/commands/scout.md`, whole file — §0 drops `not due`, the `DUE: spawn` check and the ceiling. §1's twin check is a fetch plus `./joharness.sh scout` showing your row only; its `off` is the empty reviewer. Every reference to removed things is gone or rewritten:
  - the preamble `scout DUE: spawn`;
  - "The ceiling (§0.6)";
  - `backlog   :` among the conf lines;
  - §6 "At most the ceiling … backlog : off" — becomes "at most 3 proposals a pass";
  - `WAITING ON REVIEW`, if it rests on the ceiling.
  `## Never` keeps only rules with a mechanism behind them (#461 item 6).
- `joharness.sh` from `# --- The scout cycle` to `# --- The clerk cycle`, including `scout_report_lines`:
  - Remove `scout_due`'s clock and backlog branches, `scout_retired_ts`'s merged reader, `scout_n_plans` and the ceiling, `scout_automerge`, and the `cadence`/`backlog` lines.
  - Keep `scout_refs`/`scout_walk`, the `IN FLIGHT` row, `scout_brief_present`, `scout_reviewer` and `scout_research`.
  - `cmd_scout` says a pass runs on the reviewer's order or a waiting issue, and prints `off` when the reviewer is empty.
- `joharness.sh:cmd_dispatch` — the scout cycle prints the in-flight scout row only, never `scout DUE: spawn`. Remove the `scout_due`/`scout_backlog` terms around the DRAINED verdict and the suppression lines.
- `.agents/docs/orchestrated.md`, `.agents/scripts/conf-keys.sh`, `.agents/scripts/bootstrap-consumer.sh` (the seeded keys) and `.agents/harness/selftest.sh` (the env scrub list) — remove the three knobs.
- `.agents/harness/selftest/scout.sh`, `dispatch.sh`, `clerk.sh` and `bootstrap-consumer.sh` — drop or rewrite the cases built on removed behaviour (`clerk.sh`'s `expect … "scout DUE: spawn"` with `JOHARNESS_SCOUT_HOURS=1`), and add:
  - `cmd_scout` prints no `cadence`;
  - `dispatch` prints no `scout DUE: spawn`;
  - an empty reviewer prints `off`.

## Out of scope

- Approval (`scout-approval-by-comment`), budget and digest (`scout-budget-by-count`).
- `joharness.conf` (core path). Its commented `#JOHARNESS_SCOUT_HOURS` and `#JOHARNESS_SCOUT_AUTOMERGE` lines are listed in the pull request body for the human to delete.
- Teaching `joharness.sh` to read GitHub.

## Acceptance

- `grep -rc 'JOHARNESS_SCOUT_HOURS\|JOHARNESS_SCOUT_BACKLOG\|JOHARNESS_SCOUT_AUTOMERGE' joharness.sh .claude/commands .agents/docs .agents/scripts .agents/harness | grep -v ':0$'` — no output.
- `./joharness.sh scout | grep -c 'cadence\|backlog'` — `0`; `JOHARNESS_SCOUT_REVIEWER= ./joharness.sh scout | grep -c off` — at least `1`.
- `grep -c 'DUE: spawn\|ceiling' .claude/commands/scout.md` — `0`; `grep -c 'at most 3 proposals' .claude/commands/scout.md` — `1`.
- `awk '/^# --- The scout cycle/,/^# --- The clerk cycle/' joharness.sh | wc -l` — under 130 (344 on main 2026-10-13), recorded with the date.
- Walk the orchestrator's trigger in the workstream file `## Review` on five cases. Expected results:
  - reviewer asks a question → spawn;
  - reviewer comments `approved` → no spawn;
  - planned issue with a new comment → no spawn;
  - new research request with no comments → spawn;
  - the scout answered last → no spawn.
- `bash .agents/harness/selftest.sh` (the runner only) — new and rewritten cases PASS; reverted, they FAIL.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Plan ships: consumer check = on `chrsctl/gx` after sync, `./joharness.sh scout` prints no `cadence` line.

## Where to look

- `joharness.sh:scout_due`, `scout_retired_ts`, `scout_n_plans`, `scout_automerge`, `cmd_scout`, `scout_report_lines`, `cmd_dispatch` (the scout cycle and DRAINED verdict).
- `.claude/commands/orchestrate.md` — role table scout row; "The human orders an extra role session".
- `.claude/commands/scout.md` — "## 0. Preconditions", "## 1. Claim", "## 4. Answer", "## 6. Propose", "## Never".
- `.claude/commands/clerk.md` §2 — the counting-comment definition to reuse.
- `.agents/harness/selftest/bootstrap-consumer.sh` — the seeded-keys equals `conf_keys_names` check.

## Traps

- `joharness.sh` stays git-only: the issue trigger lives in the orchestrator.
- An approved or planned issue never triggers a scout: the next move is the clerk's.
- Never edit `joharness.conf` (core path): list its stale lines for the human.
- `dispatch_freeable` and the DRAINED verdict are shared with every role: change only the scout terms.
- Shared files with the other #461 plans: merge `origin/main` in before the pull request.
