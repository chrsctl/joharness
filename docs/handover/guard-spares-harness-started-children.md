---
workstream: guard-spares-harness-started-children
status: in-progress
branch: guard-spares-harness-started-children
pr: none
plan: guard-spares-harness-started-children
issue: 338
session: https://claude.ai/code/session_018JNyVFgb7drBGd8kEKiDNj
agent: opus
updated: 2026-10-10
next: Re-run ci and verify on merged head, retire, open PR, merge
---

## Goal

Issue #338: the Stop guard counts a repo's own MCP server (a non-shell child
of the agent) as background work the session left running, so it fires on
every stop. Count only subtrees under the agent's shell children.

## Decisions

- Follow the plan as written (shell-seeded counted pass).

## Rejected

- None yet beyond the plan's own Out of scope.

## Review

- r1: (verifier) leftover case needs `pkill -P`, unchecked; without it `kill` reaps only `bash` and orphans `sleep 300` (fixed: case skips when `pkill` is absent, the suite's existing skip-for-missing-tool shape)
- r2: (verifier) `sleep` forked between `pkill -P` and `kill` would orphan it (wontfix: gap is microseconds after the whole guard ran; verifier ran the fixture 5 times, 2 counted, 0 `sleep 300` left by `ps -eo args= | grep -c '^sleep 300'`)
- r3: (verifier) branch 9 behind origin/main (fixed: merged origin/main, `git merge-tree` clean)
- r4: (verifier) plan step 1 code reuses `n`, the loop bound; implementation uses `sh` instead (no change: plan file retires in this PR)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — `bg_running=` awk program, `counted` pass.
