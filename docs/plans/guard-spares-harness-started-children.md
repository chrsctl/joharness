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
  running`. The rule: a session's own background work reaches the agent
  through a SHELL, so count only the subtrees of the agent's direct children
  whose `comm` is a shell (`bash`, `sh`, `dash`, `zsh`). Any other direct
  child — `node`, `python`, `uvx`, … — was started by the harness, not by a
  tool call, and is not the session's.
  1. In the awk program's `counted` pass, seed the queue only with direct
     children of `agent` whose `comm`, reduced to a basename, matches
     `/^(bash|sh|dash|zsh)$/`. Reduce it first: `n = comm[c]; sub(/.*\//,
     "", n); sub(/^-/, "", n)`. macOS `ps` prints `comm` as a full path
     (`/bin/zsh`), and a login shell carries a leading `-`; an unreduced
     match would count 0 there for ever. Everything below a seeded child is counted as
     today, whatever its `comm` (`bash` → `timeout` → `sleep` is one tree).
     The invocation-root exclusion (`skip`) is unchanged.
  2. No new `ps` column, no second `ps`. `comm` is already read. The perf
     comment stays true.
  3. Fact text: keep the substrings the suite pins (`background
     process(es)`, `a wait loop whose own line matches its own pattern`) and
     stop asserting that loop is THE cause. New text, exact:
     `${bg_running} background process(es) this session started are still
     running — check whether each is yours and kill what is stuck, for
     example a wait loop whose own line matches its own pattern`. No `;` in
     it (`add_fact` joins facts with `; `). Digits are still the only
     runtime data in it.
  4. Header comment of the section: why the rule is the shell (issue #338's
     measurement, and the one below), and the costs it accepts, each named:
     - counted though not the session's: an MCP server declared as
       `bash …` / `sh -c …` in `.mcp.json`; a hook or `statusLine` command
       running beside the guard (already counted before this change);
     - missed though the session's: a background tool command that `exec`s
       (`exec node server.js` replaces the tool's `bash`, measured in
       review round 2); a shell outside the list (`ksh`, `fish`, …).
- `.agents/harness/selftest/handover-guard.sh`:
  1. Real-tree case "a process the session leaves running is reported":
     its leftover becomes `bash -c 'sleep 300; :' &` instead of
     `sleep 300 &`. This is the shape a real background tool command has
     (measured below), not a weaker test. The trailing `; :` is
     load-bearing: a one-command `-c` exec-optimises into `sleep`, which is
     no longer a shell. Kill as `pkill -P "$bg"; kill "$bg"`, in that
     order — `kill` first orphans the `sleep` before `pkill -P` can find
     it. Not a process-group kill: a non-interactive job has no group of
     its own, and the group it shares is the suite's.
     Its subtree is now `bash` + `sleep`, so the count is 2 — or 1 if the
     guard's `ps` runs before `bash` forks `sleep`. Replace its `expect`
     substring with an anchored match taking both:
     `grep -E '(^|[^0-9])[12] background process\(es\) this session started'`.
     A bare substring also matches 11 and 21.
  2. New real-tree case: the fixture starts `sleep 300 &` directly (a
     non-shell child, standing for `node mcp.mjs`) and nothing else; refute
     `background process(es)` in the output. Kill it after.
  3. New shim shape `harness-child`: `900000 1 claude-fake`, the guard
     under it, `900030 900000 node`, `900031 900030 node` (server and its
     worker), `900040 900000 bash`, `900041 900040 sleep`. Expect the count
     2 exactly, matched as `grep -E '(^|[^0-9])2 background process'` (a bare
     substring also matches 12).
  4. Every other existing case stays as it is and must still pass. `dupes`
     leftovers are already `sh`, so its count stays 2.

## Out of scope

- A start-time (`etimes`) window. Rejected in review: a pre-warmed agent
  (this container's agent runs as `claude --preload …spare.sock`) is
  minutes older than the servers it later starts, so a window never
  fires where #338 was measured. And it would hide a real wait loop started
  in the first seconds of an unattended session.
- Parsing `.mcp.json` or `.claude/settings.json`. `comm` is the binary, so a
  match needs full command lines — input this session does not control —
  and JSON parsing in shell.
- Detecting a server whose CONNECTION closed while its process lives (#338's
  `CONNECTION_CLOSED` note). The guard reads processes, not connections.
- Killing anything. Every fact in this file reports, never acts.
- The `no upstream` fact — plan `guard-quiet-on-empty-branch`.

## Acceptance

- `bash .agents/harness/selftest.sh` → `0 failed`; its `handover-guard`
  lines all pass, the new ones included. The topic file is not runnable
  alone.
- Revert step 1 of the guard change only. `harness-child` must FAIL (counts
  4) and the direct-`sleep` refute must FAIL. Restore it.
- `./joharness.sh perf` — the `handover-guard` row stays within budget.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `.agents/harness/` reaches every consumer at its next sync. The
  consumer check, in a repo with a stdio server in `.mcp.json` and no
  background job running: the Stop hook's output carries no
  `background process(es)`.

## Where to look

- `.agents/harness/handover-guard.sh` — `bg_running=` and the awk program
  under it: the `climbed` walk (finds `agent`), the `walked`/`root` walk,
  the `skip` breadth-first pass, the `counted` pass (the one to change).
- `.agents/harness/selftest/handover-guard.sh` — `sgps` shim and its
  `SG_PS_SHAPE` cases; `sgbg` real-tree fixture and its `expect` strings.
- Measured here, 2026-10-10, in a cloud session: with one
  `run_in_background` command (`timeout 60 sleep 45`) live,
  `ps -eo pid=,ppid=,etimes=,comm=` showed the agent's direct children as
  `bash` only, the job as `bash` → `timeout` → `sleep`. #338's server showed
  as `node` directly under the agent (its `ps` output, in the issue).

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
- A fixture that starts a real `sleep 300` must kill it, whole tree. A
  leftover from the suite is the thing this fact reports.
