---
description: Show which sessions work on this repo now, and on which branches
---

Report real state of concurrent work. Inline — no subagent.

1. Call Claude Code Remote `list_sessions` with `mine: true`.
   Do NOT assume full tool name — MCP prefix unstable across sessions
   (`mcp__Claude_Code_Remote__list_sessions` one day, hashed
   `mcp__<uuid>__list_sessions` next; wrong name = "No such tool available").
   Find first: `ToolSearch("+list_sessions")`, call what it returns.
   Tool genuinely absent (local session, no control plane)? Say so plainly,
   use step 4 only — never guess liveness from git.
2. Per session read:
   - `session_status` — `RUNNING` = working now. ONLY that value. `IDLE` =
     container up, nobody on it. Not evidence of work.
   - `status_bucket`, `post_turn_summary.status_detail` — one-line where it
     got to. Fresher than any committed file.
   - `outcomes[].git_repository.git_info.branches`,
     `external_metadata.current_branches` — branch it owns.
   - `updated_at`, `title`.
3. Keep only sessions on this repo.
4. Cross-reference git (sees what control plane cannot — other people, local
   terminals, CI):
   `git fetch --prune origin` then
   `git for-each-ref --sort=-committerdate --format='%(refname:short) %(committerdate:relative)' refs/remotes`
5. Report short table: branch, session status, doing what, last update.
   Call out:
   - branches with `RUNNING` session — only ones genuinely taken
   - branches pushed recently, NO matching session — outsider or finished;
     investigate, not assume
   - sessions whose branch overlaps this branch's changed files

Say which branches safe. Control plane and git disagree? Control plane wins on
liveness, git wins on what changed. Say they disagree.

$ARGUMENTS
