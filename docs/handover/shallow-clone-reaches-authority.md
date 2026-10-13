---
workstream: shallow-clone-reaches-authority
status: review
branch: claude/shallow-clone-reaches-authority
pr: none
plan: shallow-clone-reaches-authority
issue: 439
session: https://claude.ai/code/session_01RXca2ZFK5BrCwuBp3oKkUV
agent: opus
updated: 2026-10-13
next: open the pull request and merge it
---

## Goal

A fresh shallow cloud session must not exit UNVERIFIED over a fetch it can
run itself, and an orchestrator must not spawn into that race (issue #439).

## Decisions

- Hook unshallow bound 40 s: Claude Code's documented default command-hook
  timeout is 600 s and SessionStart is not among the events it lowers
  (code.claude.com/docs/en/hooks, Common fields, read 2026-10-13);
  `.claude/settings.json` sets no `timeout`. Worst case of the block is now
  55 s: a non-timeout failure at second 39 plus the 15 s plain fetch.
- Role-command unshallow bound: `timeout 300`, a Bash command, not a hook.
- Plan acceptance's "one `fetch --unshallow` hit in orchestrate.md" reads two:
  line 106 predates this branch (dispatch DEGRADED note). Left as is.
- Shallow verdict prints `run:` at column 0 so a role can match it as a line.

## Rejected

- None yet.

## Review

- r1: (verifier) the hook's no-fallback-after-timeout rule had no test: restoring `|| timeout 15 git fetch` after a 124 stayed green. (fixed — selftest/authority.sh hook case: a PATH `timeout` answers the unshallow 124/128; origin/main's hook runs the plain fetch after 124, the case refutes it)
- r2: (verifier) worst case written as 40 s; a non-124 failure at second 39 then runs the 15 s plain fetch. (fixed — hook comment and Decisions say 55 s)
- r3: (verifier) the shallow selftest skipped, not failed, when the clone was not shallow or kept a merge base. (fixed — both are `expect` fixture lines; only the clone failing skips)
- r4: (verifier) plan acceptance wants one `fetch --unshallow` hit in orchestrate.md; line 106 already carried one. (no change — pre-existing dispatch-verdict line, out of scope; the new step-2 hit is the one the plan asks for)
- r5: (verifier) dispatch still falls back to an unbounded plain fetch after its 60 s unshallow, as does its non-shallow fetch. (wontfix: pre-existing lines; the plan scopes dispatch to the 60 s bound only, and dispatch is a command, not a hook a timeout kills)
- r6: (verifier) the hook NOTE said "did not finish in 40s" after a fast failure too. (fixed — "failed or did not finish in 40s")
- r7: (verifier) the `run:` line carries no bound. (no change — the plan dictates its exact text; the three role texts bound it with `timeout 300`)
- r8: (verifier) the 600 s hook default could not be fetched from the verifier's sandbox. (no change — read by the author via WebFetch on code.claude.com/docs/en/hooks, 2026-10-13: "Defaults: 600 for `command`"; SessionStart is not among the events it lowers)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_authority` — the UNVERIFIED branches.
- `.agents/harness/handover-context.sh` — shallow fetch block.
