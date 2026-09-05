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
- Descendants of the agent process is the signal, and it is clean without
  special-casing: measured here, `dockerd` from `./joharness.sh setup`
  reparents to PID 1, and the agent process has no other standing children,
  so a session that left nothing running counts 0.
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

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the boundary fact's "count only"
  rule, followed here.
- `docs/plans/unfinished-background-work.md` — the measured incident.
