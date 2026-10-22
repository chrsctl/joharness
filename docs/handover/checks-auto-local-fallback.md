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
- Human remainder #530 (ci.yml `lint` comment) stands; its wording names
  `checks_lint_skipped`, which no longer exists: commented on the issue.

## Rejected

- `finish` reading `lint` via `gh api` / unauthenticated `curl`: unreadable
  for private child repos in MCP-only cloud sessions (owner measurement).

## Review

- r1: the code-path findings r1-r22 of the first build died with the code (owner direction); record: `git show 771424c7:docs/handover/checks-auto-local-fallback.md` (no change)
- r2: new `orchestrated` cases red without the AGENTS.md change: scratch worktree of origin/main, topic `orchestrated` only, 2026-10-22: 217 passed, 2 failed; with the change 219 passed, 0 failed (fixed)

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` step 7, first bullet.
