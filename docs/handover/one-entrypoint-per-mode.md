---
workstream: one-entrypoint-per-mode
status: in-progress
updated: 2026-09-06
agent: sonnet
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
next: retire plan and workstream file, pull request, merge when green
---

## Goal

One command that starts the role the repo's configured mode calls for,
instead of a human choosing between `/drain`, `/orchestrate` and
`/manage`.

## Decisions

- The mapping lives in SHELL, not in the command file: `joharness.sh
  start` prints the file to follow, `/start` reads it. One place, and
  the selftest can pin it.
- No arguments in v1. Under orchestrated the role is assigned by the
  prompt an orchestrator spawns with, and `start <item>` would quietly
  compete with that.
- No queue read and no git: this is the step BEFORE `drain` or
  `dispatch`, and both of those cost git.

## Rejected

- Putting the mapping in `.claude/commands/start.md` as prose. Three
  modes and three files in a markdown table is a mapping no test can
  read, in the one repo whose doctrine is that counted beats written.

## Blockers

None.

## Review

Sonnet depth: `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at sonnet. Findings recorded before their
fix, in the same commit.

- r1: (verifier, correctness) the command routes by MODE, and under
  orchestrated the mode is not the whole answer — the role is the
  spawning prompt's. The caveat was printed AFTER the routing line, so a
  manager who typed `/start` met "read orchestrate.md" first and the
  correction second, and a literal reader takes the first imperative it
  meets. The AGENTS.md line was worse: "which of the three is yours"
  claimed an answer this command structurally cannot give for one of the
  three. (fixed — under orchestrated the manager check prints BEFORE the
  routing line and says STOP; supervised, which has no managers, still
  pays nothing for it. The AGENTS.md line now answers the manager case
  first, from the prompt, and sends only the rest to `/start`. A case
  pins the ORDER by line number, not by wording)
- r2: (verifier, correctness) the same fact was spelled in three places
  after the diff — the session-start banner, this command, and the
  command file — and two of them could disagree. (fixed by subtraction:
  `.claude/commands/start.md` no longer restates the rule, it points at
  the output that carries it. Two copies left, and the second is the
  banner, which reads the prompt this one cannot see: they say different
  things because they know different things)
- r3: (verifier, docs) the `mode)` arm's comment — "the guard captures
  stdout and must keep getting one clean word" — ended up directly above
  the new `start)` arm, whose output is multi-line prose. The rationale
  attached to the wrong arm and `mode)` lost its own. (fixed — the new
  arm sits above the comment, where it takes nothing that is not its
  own)
- r4: (verifier, docs) the plan's Acceptance claimed `.agents/harness/`
  reaches consumers, and two files in its own `scope:` do not:
  `sync-to-consumer.sh` holds `.agents/harness/selftest.sh` in
  `CANONICAL_ONLY` and `.agents/harness/selftest` in
  `CANONICAL_ONLY_DIRS`. `ci`'s own ship-scope line prints the three
  files that really ship and had been disagreeing with the plan all
  along. (fixed — the line now names those three and says why the
  selftest stays here)
- r5: (verifier, clean) it ran both routing mutations itself:
  `mutate joharness.sh 4058` (the orchestrated arm) reds 2 cases,
  `mutate joharness.sh 4059` (the default arm) reds 4. It also probed an
  empty conf, an unset mode, a nonexistent conf path, a
  `CLAUDE_PROJECT_DIR` pointed at an empty directory and a checkout with
  no `.claude/commands/`, and found each failing closed as designed. No
  change needed; recorded because a clean pass is a finding too.
