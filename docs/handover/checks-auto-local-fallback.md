---
workstream: checks-auto-local-fallback
status: in-progress
branch: claude/checks-auto-local-fallback
pr: 532
plan: checks-auto-local-fallback
issue: none
session: https://claude.ai/code/session_014wCvWi56XbqMaLKk8xdBds
agent: opus
updated: 2026-10-22
next: Run ci + verify, verifier pass, retire both plan files, push, merge PR 532
---

## Goal

Repository variable `JOHARNESS_CHECKS=local` alone switches a child repo to
the local gate when Actions credits run out. Built as protocol, not code:
the session reads the head's `lint` check through the GitHub MCP server at
step 7; skipped = run `JOHARNESS_CHECKS=local ./joharness.sh finish`.

## Decisions

- Dropped the `gh`/`curl` reader in `joharness.sh` (`checks_lint_skipped`)
  on owner direction, relayed by session_01UC4LM38wApQExPSuW5YnmM and
  confirmed by the human in this session: `gh auth` fails in their cloud
  sessions and child repos are private, so it could never read a child.
  Harness commands never call GitHub; sessions use the MCP server.
- Absorbed plan `checks-skipped-mcp` (same goal by protocol) on owner
  direction; the retire commit deletes both plan files.
- Kept from the first plan: AGENTS.md step 7 and consumer-repos.md say the
  repository variable alone is the out-of-credits switch.
- Pin lives in `selftest/orchestrated.sh` (the plan's shared scope), the
  `grep -q` on `${ROOT}/.agents/harness/AGENTS.md` pattern of
  handover-context-compact.sh.
- Step 7 says "A skipped `lint` check is never green", not the plan's
  "A skipped check is never green": the `windows` job is `if: false` and
  skips on every head, so the unqualified rule blocks every merge (r3).
  The plan's acceptance grep changes to match.
- Human remainder #530 (ci.yml `lint` comment) stands; its body is
  reworded to the MCP route (it named the dropped reader).

## Rejected

- `finish` reading `lint` via `gh api` / unauthenticated `curl`: unreadable
  for private child repos in MCP-only cloud sessions (owner measurement).

## Review

- r1: the code-path findings r1-r22 of the first build died with the code (owner direction); record: `git show 771424c7:docs/handover/checks-auto-local-fallback.md` (no change)
- r2: new `orchestrated` cases red without the AGENTS.md change: scratch worktree of origin/main, topic `orchestrated` only, 2026-10-22: 217 passed, 2 failed; with the change 219 passed, 0 failed (no change)
- r3: (verifier) unqualified "A skipped check is never green" blocks every merge: `windows` (`if: false`) skips on every head (fixed: names `lint`; pin follows)
- r4: (verifier) "Harness commands never call GitHub" false: janitor pushes, session-start fetches origin over git (fixed: "the GitHub API"; git fetch and push stay git)
- r5: (verifier) ci.yml `lint` comment (core path) contradicts the new rule until #530 lands (no change: #530 carries the reword; PR body names the contradiction)
- r6: (verifier) arrow in step 7 breaks caveman.md (fixed: `=`)
- r7: (verifier) consumer-repos.md paragraph named both variables "the switch" (fixed: both work, what each needs)
- r8: (verifier) pins check presence, not placement in step 7 (wontfix: the phrase is unique to that bullet; the pattern matches handover-context-compact.sh)
- r9: (verifier) both plan files still present, retire pending (no change: retire is the last commit before merge)
- r10: pins re-measured after r3/r4, same method as r2, 2026-10-22: main's AGENTS.md 217 passed, 2 failed; this branch 219 passed, 0 failed (no change)

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` step 7, first bullet.
