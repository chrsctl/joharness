---
workstream: compact-carries-the-rules
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: compact-carries-the-rules
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Spawn the verifier, fold the round into ## Review, then retire and open the PR.
---

## Goal

At compaction the task state survives and the rules decay. The compact branch
of `handover-context.sh` restores the workstream file — the half that already
survives — and says nothing about the Loop, the boundary or the mode. The hook
is the channel re-injected fresh, so the hook carries them.

## Decisions

- This session was itself compacted, and the hook's compact output is in its
  own transcript: it named the branch, the workstream file and "the
  orientation is gone", and named no rule. First-hand confirmation of the
  gap, not a substitute for the measurement the plan cites.
- **The non-compact paths are byte-identical, proved by `cmp` and not by
  reading**, which is what the plan's Acceptance asks for. Three sources
  against one fixture, before and after the change: unset, `startup` and
  `resume` all 2887 bytes and identical; `compact` 3007 → 3684, +15 lines.
  The suite pins it too, and independently: the three non-compact runs are
  compared to each other as well as to the compact one, so a change that
  moved all three together would still be caught.
- **The mode is read, never re-resolved.** `cmd_session_start` exports
  `JOHARNESS_RUN_MODE` after resolving it once, and `queue-context.sh`
  already reads it as `${JOHARNESS_RUN_MODE:-supervised}`. This uses the same
  spelling. The plan names re-resolution as a Trap, and the case that pins it
  passes `unsupervised` in and refutes `supervised` out — so a hook that
  ignored the environment and printed the default fails on both halves.
- **The gate carries more than this diff.** Removing `= "compact"` fails the
  three new "pays nothing" cases AND four pre-existing ones — including
  `supervised session-start says nothing about mode`. The context tax the
  plan warns about was already fenced; this only adds behind the same fence.

## Rejected

- **Naming a verbatim-retention size.** Out of scope by the plan, and the
  graduated page names no number on purpose: LangChain retains 10%, Inspect
  AI defaults to `preserve=0.8`, nobody publishes a measured optimum.
- **Restating the Loop's steps in the hook.** The hook points at
  `.agents/harness/AGENTS.md` and stops. A second copy of the Loop is the
  drift this repo keeps paying for, and the file is one read away.

## Review

(no round yet)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — the two compact branches.
- `joharness.sh:cmd_session_start` — where the mode is resolved. Read it,
  never re-derive it (plan Trap).
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style.
