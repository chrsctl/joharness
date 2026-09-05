---
workstream: unfinished-background-work
status: in-progress
branch: claude/unsupervised-orchestrated-mode-tzdvw2
pr: none
plan: unfinished-background-work
issue: none
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
agent: sonnet
updated: 2026-09-05
next: verifier findings, then retire this file and the plan, pull request, merge when green
---

## Goal

Nothing in the harness notices a background script that cannot finish. One
ran 1h 17m in this session — a `pgrep -f` wait loop whose pattern matched
its own command line — and the human found it in the background-tasks
panel, not the harness.

## Decisions

- The Stop guard carries the mechanism, because it is the only reader that
  can see this class. The loop was typed into a tool call, never
  committed: `ci` lints files, the hooks read git, and neither can see a
  process. The guard already runs at the moment a session ends and already
  reports facts about state the session is about to abandon.
- Descendants of the agent process is the signal, and it is a BOUND rather
  than a census (r5). It needs no special-casing because reparenting does
  the work in both directions: `dockerd` from `./joharness.sh setup`
  reparents to PID 1 and is not counted, and a job detached with `&` from a
  shell that exits reparents the same way and cannot be counted either. It
  catches the shape that bit us — a background tool call, which stays a
  child of the agent — and the Loop rule covers the rest.
- Count only, never the command line. The reason string embeds in JSON
  unescaped and a process command line is input the session does not
  control — the same rule, for the same reason, as the protocol-boundary
  fact one function up.
- Reports, never kills. Every other fact in that file reports.
- Branch re-cut from `main` after PR 214 merged.

## Rejected

- A `ci` lint for self-matching `pgrep`. The failing command was never in
  a file, so the lint would gate a shape nobody commits and miss this one.
- Killing the process, or a timeout wrapper around background commands.
  The guard acts on nothing; a wrapper is a new entrypoint surface for a
  problem one rule and one fact already cover.

## Review

Sonnet depth: `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at sonnet. Findings written before their fix.

- r1: (session, testing) the first exclusion covered only the guard's own
  pid, so a guard reached through a shell chain counted the chain that was
  running it — the invoking pipeline read as abandoned background work. On
  a tree with nothing left running it reported 2. (fixed — the exclusion is
  the subtree of the invocation ROOT, the ancestor that is the agent's own
  child; at a real stop that is the guard itself, under a test harness the
  shell driving it. `mutate` on that line reds 5 cases)
- r2: (session, testing) the first test piped the guard into `grep`, and
  the `grep` is another child of the fake agent — so the case measured the
  test harness, counting 1 where the code was right to count 0. (fixed —
  the fixture redirects to a file and asserts on that; the comment says why,
  because the next person to add a case will reach for a pipe)
- r3: (session, perf) the first shape forked `ps` twice per ancestor level,
  which is the per-item fork the perf budget exists to catch, and it caught
  it: 35 against 33. Raising the budget would have been the wrong fix — the
  doctrine at `perf_rows` says find the loop. (fixed — one `ps` snapshot
  feeding one awk that climbs, finds the invocation root and walks both
  subtrees; 21 against 33, and a single snapshot is the more correct read
  anyway, since a table sampled per level races with a tree exiting
  underneath it)

- r4: (verifier, correctness) neither climb loop had a visited map, so a
  process table that is not a tree — a self-parented pid, a cycle from a
  forged or racing read — walked forever. Reproduced by the verifier against
  a hand-built table, killed by `timeout 3` (exit 124). The fix for a script
  that cannot finish must not be one. (fixed — every walk in that awk carries
  a visited map now, the two climbs and both breadth-first passes; two new
  cases feed synthetic tables through a `ps` shim under `timeout 10` and
  fail on exit 124. Pinned, `./joharness.sh mutate`, 2026-09-05: the climb's
  map reds 1 case, the excluding pass 2, the counting pass 2. The root
  climb's map reds none and is kept anyway — a cycle cannot strand it, since
  the first climb walks the same nodes and cannot reach an agent through
  one, so the case that would pin it does not exist. Said here rather than
  left for the next reader to mutate and wonder)
- r5: (verifier, scope) the count sees only what stays ATTACHED. A job
  detached with `&` from a tool call whose shell then exits reparents to
  PID 1 — the same mechanism the comment cited as proof the count is clean
  is what hides that shape. The signal is detached-versus-attached, not
  leftover-versus-legitimate. (fixed as documentation, not as code: the
  comment and the Loop rule now say it is a bound and a backstop, and that
  the rule is the defence. A count that cannot attribute a PID-1 orphan to a
  session must not pretend to; the incident's own shape — a background tool
  call — stays attached and is caught)
- r6: (verifier, testing) the topic failed under load and passed alone.
  Reproduced here — a suite run with four background jobs alive in the
  session: `1537 passed, 4 failed`. TWO mechanisms, and the second is the
  one that matters. (a) two cases were exec-optimised away: a `bash -c`
  string holding ONE command replaces the shell, so the fake agent stopped
  existing and the climb walked past it to the REAL one (probe:
  `claude-probe -c "bash -c '...ps...'"` prints a tree with no
  `claude-probe` in it). (b) far worse, THREE of the failures were plain
  git-fact cases — "clean pushed tree stays silent" and friends — which now
  ran a guard that counts live processes inside a session that had four.
  Every case in the topic had been made a function of the container's
  process tree. (fixed — (a) a trailing `:` keeps the fork; (b) the topic
  runs with a `ps` shim that hands back an empty table, so the git-fact
  cases measure git again, and the cases that are about processes put the
  real `ps` back explicitly. A hook that reads the world needs its world
  fixed in the tests, and only there — the shim is PATH, not a knob in the
  guard)
- r12: (session, testing) writing r4's cases cost three wrong shims, and the
  reason is worth keeping: a `ps` shim has to identify the guard process
  itself, and every cheap test finds something else. `grep handover-guard`
  over `/proc/<pid>/cmdline` matches any shell whose command line MENTIONS
  the file — this suite's, the tool call's — and returned the same stable
  pid on two different runs, which is what gave it away. Breaking at the
  first match finds the command-substitution SUBSHELL, whose command line is
  a copy of the guard's, so `self` was never in the table and the walk
  ended in one step, green for the wrong reason. (fixed — the shim takes the
  TOPMOST ancestor whose argv is `bash <...>handover-guard.sh`, which
  excludes `timeout ... bash ...guard.sh` on argv[0] and the mentioning
  shells on argv[1]; proved by copying the guard with its map removed and
  watching it hang to exit 124 under the same shim)
- r11: (verifier, testing) the "no agent process in the chain" case asserted
  a premise its own environment contradicts: the suite runs UNDER the agent,
  so the chain always has one, and the case passed for the wrong reason.
  (fixed — the shim gives it a chain that reaches init through nothing named
  for the agent, which is the shape the case names)
- r7: (verifier, testing) `mutate` on the digit sanitizer said NOTHING
  REDDED — the one line between a malformed read and unescaped text in the
  JSON reason string was pinned by nothing. The same tool reds 7 cases on
  the exclusion seed and 2 on the `ps` gate, so the suite was not weak
  everywhere, only there. (fixed — a case shims `awk` to hand back
  `x"; injected` and refutes both that string and any count in the output)
- r8: (verifier, docs) the new Loop sentence gave a measured number with a
  date and no producer, six lines above the rule in the same file demanding
  both. (fixed — it names the background-tasks panel, which is what produced
  it, and says so plainly rather than implying a command counted it)
- r9: (verifier, docs) "35 against 33" in the code comment described an
  implementation that no longer exists, so nobody can re-count it — a
  written number by this repo's own definition. (fixed — the comment carries
  the number that IS re-countable, 21 against 33 from `./joharness.sh perf`,
  and keeps the discarded shape as a story without a figure)
- r10: (verifier, process) `## Review` held three findings and none tagged
  `(verifier)`, which is what `JOHARNESS_REVIEW=on` checks for and what
  agent-selection asks of every depth. (fixed — r4 through r10 are the
  verifier's, tagged; r1 to r3 were the session's own and stay marked so)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the boundary fact's "count only"
  rule, followed here.
- `docs/plans/unfinished-background-work.md` — the measured incident.
