---
plan: clerk-fetch-before-inflight
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 467
scope: shared:.claude/commands/clerk.md
---

## Goal

`.claude/commands/clerk.md` §0.2 reads `./joharness.sh clerk` for `IN
FLIGHT` without fetching first. The remote-tracking refs can be stale, so a
clerk exits on a twin that has already merged. Issue #467 measured this on
gx (2026-10-13): `IN FLIGHT … clerk-2026-10-13-b`, the clerk exited, a human
restarted it, and after the §1 fetch the same command read `not due` (#652
had merged). Checked by the clerk 2026-10-13: §0 has no fetch; only §1's
twin check runs `git fetch --prune origin '+refs/heads/*:refs/remotes/origin/*'`.
The failure is safe (no twin ran) but costs a pass and a human.

## Scope

- `.claude/commands/clerk.md` §0 item 2 — before `./joharness.sh clerk`, run `git fetch --prune origin '+refs/heads/*:refs/remotes/origin/*'`, written on one line followed by `FAILED = stop, report` (the same words as §1). Run it bounded: Bash `timeout` 120 s. Reword "That is the only exit here" to "That is the only exit on a clean read"; the rest of item 2 is unchanged.

## Out of scope

- Printing the refs' age in `./joharness.sh clerk` (#467's optional ask): the fetch removes the stale read that the age would only report.
- The same pattern in other role commands: no measured failure there.
- `joharness.sh`.

## Acceptance

- `sed -n '/^## 0/,/^## 1/p' .claude/commands/clerk.md | grep -c "git fetch --prune origin"` — `1` (`0` on main today).
- `sed -n '/^## 0/,/^## 1/p' .claude/commands/clerk.md | grep -A1 'git fetch --prune origin' | grep -c 'FAILED = stop'` — `1`.
- `grep -c 'the only exit here' .claude/commands/clerk.md` — `0` (`1` on main today).
- `./joharness.sh ci` — `ci: pass`.
- Plan ships (`clerk.md` syncs): consumer check = on `chrsctl/gx` after sync, the same `sed | grep` prints `1`.

## Where to look

- `.claude/commands/clerk.md` — "## 0. Preconditions" item 2; "## 1. Branch", the twin-check fetch line to copy.

## Traps

- Copy §1's fetch refspec exactly: a single-branch fetch does not see clerk branches.
- `clerk.md` is also edited by `scout-approval-by-comment`: merge `origin/main` in before the pull request.
