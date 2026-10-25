---
workstream: simplify-code-plans
status: in-progress
branch: claude/simplify-code-plans
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-25
next: Write plans one-release-command and drop-curator-session, research knobs-to-constants and selftest-runtime
---

## Goal

User asked what else can be simplified, then chose: plan (1) one command to
release abandoned branches instead of janitor/halt/release/free and the
freer role, (2) remove the curator session, keeping `curate --apply`;
research (3) which knobs can become constants, (4) why the selftest suite
takes 493 s and what to cut or parallelise.

## Decisions

- Plans-only pull request; managers build.

## Rejected

- None yet.

## Review

- r1: RELEASE: row flag cannot attach to plan: none, fast-lane or branch-only claims (verifier) (fixed: release report lines from janitor's test, not dispatch rows)
- r2: free's done kind and no-claim doc-only branches lost unnamed (verifier) (fixed: done gets a release reason; no-claim branches reported, nothing written)
- r3: nothing wires the clerk to re-file plans (verifier) (fixed: a human re-files)
- r4: README.md Freer row outside scope (verifier) (fixed: in scope, shared across three plans)
- r5: janitor report detail lost (verifier) (fixed: moves to release with no argument)
- r6: release --human acceptance did not discriminate (verifier) (fixed: no such branch on origin, 1)
- r7: drop-curator fixture key pointed at the wrong file (verifier) (fixed: selftest/sync-to-consumer.sh)
- r8: guard interface and --human subjects unspecified (verifier) (fixed)
- r9: consumers keep a stale curate.md calling role curate (verifier) (fixed: role curate prints a STOP line, exit 0)
- r10: cmd_curate keeps a stale instruction (verifier) (fixed: the whole instruction goes)
- r11: role curate acceptance text did not exist (verifier) (fixed: the STOP line)
- r12: curator runs miscounted; "none followed" overstated (verifier) (fixed: seven runs incl. #313; sample wording)
- r13: knob counts did not reproduce (verifier) (fixed: 50 knobs; 14 and 30 with the command)
- r14: knobs research names no second context; hand-written dates (verifier) (fixed: Method names gx conf read; dates removed)
- r15: selftest research misstated the git-exec knob and who pays (verifier) (fixed)
- r16: drop-curator Traps named the wrong plan for the suppression lines (verifier) (fixed)
- r17: AGENTS.md quote stale (verifier) (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:main`: the subcommand list.
