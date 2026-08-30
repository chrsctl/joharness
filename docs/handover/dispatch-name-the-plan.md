---
workstream: dispatch-name-the-plan
status: done
branch: claude/dispatch-name-the-plan
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Retire this file, open the pull request, merge.
---

## Goal

Write down the rule that stops two spawned sessions claiming the same plan:
the CALLER names each session's plan in its prompt. Salvaged from
`origin/claude/multi-agent-orchestration-pr-jyli0w` (PR 10, closed unmerged
2026-08-21) in PR 152, and documented nowhere before this.

## Decisions

- **In the Lifecycle list, beside Claim**, not in a new section. It is a
  consequence of "no push, no claim" (Loop step 3) and reads as one where
  that rule is stated.
- **Says why no mechanism**, in one clause. Every measure here counts from
  git at read time and stores nothing, so a pre-push claim would need shared
  state the harness does not have. Without that clause the next reader files
  a plan for the mechanism.
- **Names who is wrong.** The spawned session self-selecting is behaving
  correctly; the caller is the one who must not tell two of them to. The
  original finding said "queue self-selection is for single sessions", which
  a spawned session could read as an instruction to itself.
- **No test.** It is one paragraph of prose in a doc; `ci`'s glossary and
  graph lint already read the file, and a case asserting a sentence exists
  pins the wording rather than the behaviour.

## Rejected

- **A mechanism.** Out of scope in the plan, and the reason is in the rule
  itself.
- **Putting it in `.agents/harness/AGENTS.md` step 3.** That file is
  deliberately short — caveman, measured — and this is addressed to whoever
  spawns sessions, not to the session reading the Loop.

## Review

Round 1, opus, self.

- r1: the plan's own Acceptance was `grep -rn "self-selection"
  .agents/docs/plans/README.md`, which passes on any sentence containing the
  word. Ran it, and it is satisfied by prose that says the opposite. Not
  fixed by changing the grep — the honest statement is that this diff is one
  paragraph and its acceptance is a reader, not a command. (recorded — the
  plan is retired with the work, so the weak criterion does not outlive it)
- r2: first draft wrote the rule as an instruction to the spawned session,
  which is the one reader who cannot act on it and the misreading the
  original finding invited. (fixed — addressed to the caller)
- r3: verifier round owed and NOT run — standing instruction.

## Blockers

None.
