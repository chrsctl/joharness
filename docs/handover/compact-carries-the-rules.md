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
next: Retire the plan and this file, open the PR, merge it.
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
  reading**, which is what the plan's Acceptance asks for — against
  `origin/main`'s own copy of the hook, on one fixture, for unset, `startup`
  and `resume`. Only `compact` differs.
  The reproducible figure is the DELTA, not a size. Counted with
  `git show ae8720f:.agents/harness/handover-context.sh` against this tree,
  same fixture, 2026-08-29: **compact +13 lines, startup +0**. A byte count
  cannot reproduce — six lines of this output move with the clock
  (`pushed 24 hours ago`) or with other sessions' pushes, so any size written
  here is stale the next hour (r206).
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
- **Both compact branches, one block.** The plan's Scope names "the two
  `JOHARNESS_SESSION_SOURCE` = `compact` branches". The rules half goes in
  the FIRST only — printed once, and reaching a branch with no workstream
  file too, which is why that branch exists. Printing it in both duplicates
  the output. What the second branch owed was a test, and it had none: the
  lead-line switch could be mutated to `if true` with the whole suite green
  (r203). Both branches are now covered; only one prints the block.
- **The compact source is real on this client, first-hand.** An open finding
  on this file (PR97 r1, `./joharness.sh feedback
  .agents/harness/handover-context.sh`) says the SessionStart `source` key is
  documented, never observed here, and synthesised by the tests — so this
  block could be dead and `ci` green either way. It is not dead: this session
  began with a `SessionStart:compact` hook block that printed the compact
  lead line, and `joharness.sh:3973` parses `JOHARNESS_SESSION_SOURCE` from
  the payload's `"source"` field. The payload carried `"source": "compact"`.
  Recorded here rather than in that branch's record, which is retired.

## Rejected

- **Naming a verbatim-retention size.** Out of scope by the plan, and the
  graduated page names no number on purpose: LangChain retains 10%, Inspect
  AI defaults to `preserve=0.8`, nobody publishes a measured optimum.
- **Restating the Loop's steps in the hook.** The hook points at
  `.agents/harness/AGENTS.md` and stops. A second copy of the Loop is the
  drift this repo keeps paying for, and the file is one read away.

## Review

Round 1, opus, `.claude/agents/verifier.md` (verifier) — 7 findings. Recorded
before their fixes and in the same commit. Two are corrections to claims I
made; one is the same failure mode that cost a full revert two plans ago.

- r201: (verifier) **The hook shipped the wrong boundary.** The graduated page
  is specific — "a session that keeps its task and loses its boundary is
  precisely what unsupervised mode exists to prevent" — which is step 2's
  `no commit under .agents/harness/`. I shipped Part 2's layer-coupling rule
  ("names no environment") instead. Same failure as the `cleanup-audit`
  revert: read the anchor for the section I wanted, not the sentence that
  named the thing. (fixed — verified both rules' locations by grep before
  changing anything; refuted by restoring the layer text, which reds two
  cases)
- r202: (verifier) And it pointed at a file that does not carry that rule. The
  layer text lives in the ROOT `AGENTS.md` Part 2, and
  `.agents/scripts/sync-to-consumer.sh` splices only ABOVE
  `# Part 2 — project`, keeping the consumer's own — so in every consumer the
  line pointed at a rule that does not exist there. (fixed — both facts now
  live in `.agents/harness/AGENTS.md`, which ships whole, and a case greps
  that file for the rule so the pointer cannot go stale silently)
- r203: (verifier) **The Acceptance's byte-identity was not proved by the
  suite, and a real regression passed it.** Mutating the SECOND compact gate
  to `if true` changes the non-compact lead line; the whole suite stayed green
  at 977. My Decisions claimed the three-way self-comparison would catch a
  change that moved all three together — that mutation moves all three
  together, so it is exactly what the comparison allows. (fixed — both lead
  lines pinned by their own text, each refuted by the other; refuted by
  re-running that mutation, which now reds two cases)
- r204: (verifier) The plan's Scope names both compact branches and only one
  was touched. (fixed for coverage, and the reading is recorded in Decisions:
  the block belongs in one branch, the test was what the other owed)
- r205: (verifier) "15 cases … each refuted" is false for 4 of them. Two can
  only be redded by deleting pre-existing lines, and one needed a mutation
  that adds behaviour rather than reverting any. (corrected — the commit
  states coverage per mutation and names what is not covered, instead of
  claiming "each")
- r206: (verifier) "2887 bytes each" and "3007 → 3684" do not reproduce and
  cannot: six lines of this output move with the clock and with other
  sessions' pushes. Only the delta reproduces. (fixed — Decisions carries the
  delta and the command, and says why a size cannot be written here)
- r207: (verifier) Caveman: "the task state" twice in one sentence
  (`.agents/docs/caveman.md`, State each fact once — this file has already
  paid a finding for that exact thing, PR97 r5), and a supervised session was
  handed `.agents/docs/unsupervised.md`, which is context for the mode it is
  not in. (fixed — one mention, and the mode's page is gated on the mode; a
  case refutes each half)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — the two compact branches.
- `joharness.sh:cmd_session_start` — where the mode is resolved. Read it,
  never re-derive it (plan Trap).
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style.
