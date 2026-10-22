---
plan: queue-fail-closed
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/dispatch.sh, .agents/harness/selftest/janitor.sh, shared:.agents/harness/selftest/curate-apply.sh
---

## Goal

A harness review (session 2026-10-22) found three places where the queue's
readers and writers act on a wrong picture of the queue: a missing or broken
queue hook reads as an empty queue, and the janitor both releases claims it
must keep and fails to release claims it should. Each one makes the
orchestrator spawn wrongly or lose a human's question. Fix all three,
failing closed.

## Scope

- `joharness.sh:drain_hook` — today `[ -x "$h" ] || return 0` and the hook's
  stderr and exit status are discarded. Change: hook absent or not
  executable, or exits non-zero → return non-zero and print one line naming
  the hook and the exit code to stderr. Every caller (`cmd_dispatch`,
  `cmd_curate`, and any other `drain_hook` caller found by `grep -n
  drain_hook joharness.sh`) treats non-zero as UNREADABLE: `dispatch`
  prints `verdict : UNREADABLE — queue hook <name>: <reason>` and spawns
  nothing; `curate --apply` writes nothing and exits non-zero.
- `joharness.sh:janitor_candidates` — skip a claim whose `status:` is
  `blocked` or `done` (same states `free_owner_held` refuses). Only
  `in-progress`, `review` or empty status with no `pr:` remain candidates.
- `joharness.sh:janitor_apply` awk (the block with
  `fm && /^status:/ { print "status: abandoned"; next }`) — when the
  frontmatter has no `status:` line, insert `status: abandoned` before the
  closing `---`, the same way the missing `next:` line is inserted.
- Selftests:
  - `selftest/dispatch.sh`: a fixture with `queue-context.sh` made
    non-executable → output contains `UNREADABLE`, not `DRAINED`.
  - `selftest/curate-apply.sh`: same fixture → `curate --apply` exits
    non-zero and no plan file changes (compare `git status --porcelain`).
  - `selftest/janitor.sh`: a stale `status: blocked`, `pr: none` claim is
    NOT listed; a stale claim with no `status:` line is released and then
    reads `status: abandoned`.
  Each new case must FAIL on `main` before the change.

## Out of scope

- Any other fail-open audit beyond these three functions.
- Changing `HANDOVER_STALE_SECONDS` or the janitor's proof-of-gone rule.
- `.claude/commands/*.md` wording; the commands already treat UNREADABLE as
  a stop.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `chmod -x .agents/harness/queue-context.sh && ./joharness.sh dispatch;
  echo $?; chmod +x .agents/harness/queue-context.sh` — prints
  `UNREADABLE`, exit non-zero. Restore the mode before committing.
- New selftest cases red without the change; record the red lines in the
  workstream file's `## Review`.
- Plan `ci` calls SHIPS: the selftests run in every consumer's `ci`.

## Where to look

- `joharness.sh:drain_hook`, `drain_requirement`, `cmd_dispatch`,
  `cmd_curate` (search `drain_hook`).
- `joharness.sh:janitor_candidates`, `janitor_apply`, `free_owner_held`.
- `.agents/harness/selftest/janitor.sh`, `dispatch.sh`, `curate-apply.sh` —
  existing fixtures to copy.

## Traps

- Fail closed: an unreadable hook must never print `DRAINED`.
- NEVER skip, disable or quarantine a test.
- Other queued plans also edit `joharness.sh` (all marked `shared:`); merge
  `origin/main` in before step 7.
- No core paths (`./joharness.sh protocol-paths`).
