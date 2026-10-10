---
plan: retire-survives-lost-github
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: shared:.claude/commands/manage.md
---

## Goal

Issue #347, secondary. On 2026-10-10 manager `janitor-rules-agree` lost its
GitHub MCP ("invalid session" on `create_pull_request`, `get_me`,
`pull_request_read`) AFTER its step-7 retire commit had deleted its
workstream file. A human reconnect did not fix that session. The manager
could neither open nor merge its PR, and it waited in the session for help.
A human opened and merged the PR (#346).

Two paths already exist. Before the retire, the workstream file is there to
take `status: blocked`. After it, `joharness.sh:dispatch_retired_edges`
prints the branch as an edge with no claim file, and `orchestrate.md`
respawns a gone manager there "to FINISH the merge". A live manager that
sits waiting is not gone, though, so it holds its slot until the IDLE row's
nudge-then-respawn runs. The issue calls that fixing it "by accident". This
plan makes `manage.md` say what to do on each side of the retire, so that
both paths are taken on purpose.

## Scope

`.claude/commands/manage.md`, `## 4. Finish`. Add two rules, in caveman
style, after the step-7 sentence:

1. **Before the retire commit:** make one GitHub MCP read on this repo
   (`get_me`, or `list_pull_requests` filtered to your head branch). If it
   fails, do not retire. Set `status: blocked`. Set `next:` to
   `GitHub MCP lost before PR: <error, 40 chars>`. Commit, push, exit. One
   failure is the answer: no retry, same as the message rule below it.
2. **After the retire commit, if a GitHub call fails** (open, read or
   merge the PR): do not revert the retire and do not wait in the session.
   Make sure the retire commit is pushed, end the turn with one line naming
   the failed call, and exit. The branch then reads as a retired edge, and
   a successor finishes it (`orchestrate.md`, "gone at the edge"). Say
   why no revert in one clause: once a PR is open, a revert puts the
   workstream file and the done plan back on a head a human may merge.

Also add one bullet to `## Never`: "Wait in the session for GitHub to come
back at step 7." If `role-files-say-it-first` has merged by then, put this
bullet next to its "Wait in the session for a human's answer" bullet. One
bullet covering both is fine.

## Out of scope

- Reverting the retire commit, for the reason in rule 2.
- A new orchestrator health row for `need_input` at the edge (the issue's
  other option). It reads a control-plane field the git view cannot check.
- Any `joharness.sh` change. `dispatch_retired_edges` already prints this
  branch.
- Reconnecting GitHub. That is the human's job.
- The messaging route. That is plan `messaging-names-both-routes`.

## Acceptance

- `grep -n 'GitHub MCP lost before PR' .claude/commands/manage.md` → one
  hit inside `## 4. Finish`. It reads `0` before the work.
- `grep -c 'git revert' .claude/commands/manage.md` → `0`.
- `bash .agents/harness/selftest.sh` → `0 failed`.
- `./joharness.sh ci` → `ci: pass`.
- SHIPS: `manage.md` reaches every consumer, and the consumer's own
  `./joharness.sh ci` lints its glossary after sync. Selftests are
  canonical-only (`.agents/scripts/sync-to-consumer.sh`, `CANONICAL_ONLY`).

## Where to look

- `.claude/commands/manage.md:4. Finish` — the step-7 sentence and the
  retire ("KEEP THE DELETE").
- `.claude/commands/manage.md:Never` — where the new bullet goes.
- `joharness.sh:dispatch_retired_edges` — the git view of a branch past its
  retire commit, which rule 2 relies on.
- `.claude/commands/orchestrate.md` — the health row ending "gone at the
  edge. RESPAWN on that branch to FINISH the merge", and the `not RUNNING`
  row for status `` `blocked` `` ("human's. Report. Never respawn."), which
  rule 1 relies on.
- Issue #347, "Secondary, same run".

## Traps

- Never rewrite history. This plan adds no history operation at all.
- Push before exiting. `.agents/harness/handover-guard.sh` reminds about
  unpushed work at the stop.
- Shared file, reconcile at step 7: `manage.md` is also in the scope of
  `messaging-names-both-routes`, `role-files-say-it-first`,
  `role-command-trim`, `plan-on-a-branch-visible`, `issue-triager-role`,
  `lineup-cache-read-pricing` and `orchestrated-only`.
