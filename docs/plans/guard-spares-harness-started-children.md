---
plan: guard-spares-harness-started-children
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:.agents/harness/handover-guard.sh, shared:.agents/harness/selftest/handover-guard.sh
---

## Goal

Issue #338. `handover-guard.sh` counts every descendant of the agent process
as background work the session left running. An MCP server declared in a
repo's `.mcp.json` is a long-lived child of the agent by construction, so in
any repo that declares one the count is always 1 or more and the guard fires
on every stop, whatever the session did. Measured in consumer `chrsctl/gx`,
2026-10-10: the only counted child was `node platform/web/storyboard/mcp.mjs`,
started at session start, ~15 minutes before the session's first background
command. The fact then names a cause it cannot see ("a wait loop whose own
line matches its own pattern"), sending the reader to working code — and the
easy way to silence it is to kill the repo's own MCP server. A guard that
fires on every stop teaches sessions to stop past it, which also passes the
real case it exists for.

## Scope

- `.agents/harness/handover-guard.sh`, section `background work still
  running`:
  1. Read one more column in the SAME single `ps` call:
     `ps -eo pid=,ppid=,etimes=,comm=` (etimes = seconds since the process
     started). Still one `ps`, one `awk` — the perf budget comment there
     stays true.
  2. In the awk, after the agent is found: a DIRECT child of the agent
     whose `etimes` is within `spawn_window` seconds of the agent's own
     `etimes` (`agent_etimes - child_etimes <= spawn_window`) was started
     WITH the agent — by the harness, not by a session command. Exclude
     that child's whole subtree from the count, the same way the invocation
     root's subtree is excluded today (reuse the `skip` map). Set
     `spawn_window=30`, one named awk variable, with a comment carrying the
     measurement it rests on.
  3. If the agent's `etimes`, or a child's, is not all digits (a `ps`
     without the field, a short row), exclude nothing for it. Today's count
     is the fallback; the guard never goes quieter on a read it cannot make.
  4. Rewrite the fact text so it states only what the count measures. New
     text, exact: `${bg_running} process(es) this session started are still
     attached to it — check whether each is yours and meant to outlive the
     turn; a wait loop that matches its own command line never exits`.
     Still digits only from runtime data; nothing else interpolated.
  5. Update the section's header comment: why a process started with the
     agent is not the session's (issue #338, the measurement above), and
     the bound it leaves: a server restarted mid-session (`/mcp` reconnect)
     is counted again. Say so; it is the accepted cost.
- `.agents/harness/selftest/handover-guard.sh`:
  1. The `ps` shim emits four columns for every existing shape (`cycle`,
     `rooted`, `dupes`); give each row an `etimes` that keeps today's
     expected outcome (leftovers well after the agent: e.g. agent 1000,
     leftover 10).
  2. New shape `harness-child`: fake agent `etimes` 1000; one child of the
     agent with `etimes` 995 and a grandchild under it (the MCP server and
     its worker); one leftover child with `etimes` 10. Expect exactly
     `1 process(es)`.
  3. New shape `no-etimes`: same tree, `etimes` column `-`. Expect
     `3 process(es)` — no exclusion when the field is unreadable.
  4. The real-tree case's assertions follow the new wording: the
     `expect "... is reported"` string and the `expect "and the fact says
     what makes one unable to finish"` string change to substrings of the
     new text. Same intent, new words — not a weakened test.

## Out of scope

- Parsing `.mcp.json` or `.claude/settings.json` to match server commands.
  `comm` is the binary (`node`), so a match means reading full command
  lines from the table — input this session does not control — and parsing
  JSON in shell. The start-time test needs neither. Named in #338 as an
  option; rejected for that reason.
- Detecting a server whose CONNECTION closed while its process lives (#338's
  `CONNECTION_CLOSED` note). The guard reads processes, not connections.
- Killing anything. Every fact in this file reports, never acts.
- The `no upstream` fact — plan `guard-quiet-on-empty-branch`.

## Acceptance

- `bash .agents/harness/selftest.sh` → `0 failed`; its `handover-guard`
  lines all pass, including the two new shapes. The topic file is not
  runnable alone.
- Revert step 2 of the guard change (the exclusion) only. The
  `harness-child` case must FAIL (counts 3). Restore it.
- `./joharness.sh perf` — the `handover-guard` row stays within its budget.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `.agents/harness/` reaches every consumer at its next sync. The
  consumer check: a session in a repo with a stdio server in `.mcp.json`
  that started no background work stops with no `process(es)` fact.

## Where to look

- `.agents/harness/handover-guard.sh` — `bg_running=` and the awk program
  under it: the `climbed` walk (finds `agent`), the `walked`/`root` walk,
  the `skip` breadth-first pass (the exclusion to copy), the `counted` pass.
- `.agents/harness/selftest/handover-guard.sh` — `sgps` shim and its
  `SG_PS_SHAPE` cases; `sgbg` real-tree fixture and its `expect` strings.
- Measured here, 2026-10-10, `ps -eo pid=,ppid=,etimes=,comm=` in a cloud
  session: the field exists in this container's procps; the agent (`claude`)
  showed `etimes` 71 while the session was far older — the agent process can
  be newer than the session. Its MCP children restart with it, so the window
  compares against the AGENT, never against session start.

## Traps

- `guard-quiet-on-empty-branch` and `orchestrated-only` also edit both
  files; all mark them `shared:`. Reconcile at step 7.
- Test written for a fix must FAIL without it (Loop step 5) — the revert
  step in Acceptance is that check, not optional.
- Never skip, disable or quarantine a guard case to get green. Rewording an
  assertion to the new text is allowed; deleting one is not.
- The reason string embeds in JSON unescaped: no command line, no path, no
  `comm` in the fact. Digits only.
- Every awk walk keeps its visited map; a new walk without one is the
  unbounded loop the `cycle` shape exists to catch.
