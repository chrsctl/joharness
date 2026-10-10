---
plan: retire-survives-lost-github
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:.claude/commands/manage.md
---

## Goal

Issue #347, secondary. On 2026-10-10 manager `janitor-rules-agree` lost its
GitHub MCP ("invalid session" on `create_pull_request`, `get_me`,
`pull_request_read`) AFTER its step-7 retire commit had deleted its
workstream file. A human reconnect did not fix that session. The manager
could not open or merge its PR. With the file gone it had nowhere to write
`status: blocked`, so `dispatch` read it as a plain IDLE manager, which
leads to a nudge and a respawn. A human opened and merged the PR (#346).
The manager needs a route that leaves a readable block whenever GitHub is
lost at its edge, before or after the retire commit.

## Scope

`.claude/commands/manage.md`, `## 4. Finish`. Add two rules, in caveman
style, after the step-7 sentence:

1. **Before the retire commit:** make one GitHub MCP read on this repo
   (`get_me`, or `list_pull_requests` filtered to your head branch). If it
   fails, do not retire. Set `status: blocked`. Set `next:` to
   `GitHub MCP lost before PR: <error, 40 chars>`. Commit, push, exit.
2. **After the retire commit, if a GitHub call fails** (open, read or merge
   the PR): run `git revert --no-edit <retire sha>`. That brings the
   workstream file and plan file back. Set the file's `status: blocked` and
   `next:` as in rule 1, naming the step that failed. Commit, push, exit.
   Do not retry the GitHub call more than once.

Also add one bullet to `## Never`: "Exit after a retire commit with no PR
open and no workstream file on the branch."

## Out of scope

- A new orchestrator health row for `need_input` at the edge (the issue's
  other option). It needs a control-plane field the git view cannot check.
  If the revert rule is not enough, raise it as its own plan.
- Any `joharness.sh` change. A `blocked` row is already "the human's" in
  `dispatch` and `orchestrate.md`.
- Reconnecting GitHub. That is the human's job.
- The messaging route. That is plan `messaging-names-both-routes`.

## Acceptance

- `grep -n 'git revert --no-edit' .claude/commands/manage.md` → one hit
  inside `## 4. Finish`.
- `grep -n 'GitHub MCP lost' .claude/commands/manage.md` → at least one
  hit.
- `bash .agents/harness/selftest.sh` → `0 failed`.
- `./joharness.sh ci` → `ci: pass`.
- SHIPS: `manage.md` reaches every consumer. The consumer check is its own
  `./joharness.sh ci` after sync, which lints the glossary over this text.

## Where to look

- `.claude/commands/manage.md:4. Finish` — step-7 sentence and retire
  ("KEEP THE DELETE").
- `.claude/commands/manage.md:Never` — where the new bullet goes.
- `.claude/commands/orchestrate.md` — health table row
  `not RUNNING | any | status blocked` ("human's. Report. Never respawn.").
  This plan relies on that row and does not change it.
- Issue #347, "Secondary, same run".

## Traps

- Never rewrite history: revert, not reset or amend. The retire commit may
  already be pushed.
- `handover-guard.sh` blocks a stop with unpushed work. Push the blocked
  file before exiting.
- Shared file: `messaging-names-both-routes`, `role-files-say-it-first`,
  `role-command-trim`, `plan-on-a-branch-visible`, `issue-triager-role`,
  `lineup-cache-read-pricing` all edit `manage.md`. Reconcile at step 7.
