---
workstream: a-manager-blocked-before-its-first-push
status: in-progress
branch: claude/a-manager-blocked-before-its-first-push
pr: none
plan: a-manager-blocked-before-its-first-push
issue: none
session: https://claude.ai/code/session_01L9goduLrAbA63NFBxH6xWH
agent: opus
updated: 2026-10-10
next: Retire this file, open PR, finish, merge
---

## Goal

Settle `docs/research/a-manager-blocked-before-its-first-push.md`: which
health-table row a manager blocked before its first push reaches. Graduate
the answer to `.agents/docs/orchestrated.md`, delete the node.

## Decisions

- Settled: two wrong verdicts, one per `session_status` reading — merged row
  ("done. Nothing.") on RUNNING/unnamed, "RAN, never respawn" on IDLE. The
  node's "merged row first either way" is wrong on IDLE (unclaimed rows sit
  above it, at 832f5fdd too).
- Measured: BLOCKED bucket also marks an ended turn asking a question (IDLE,
  need_input) — so the new row keys on BLOCKED AND not IDLE/PENDING/ARCHIVED.
- Row edits to orchestrate.md are a plan (`blocked-before-claim-row`), not
  this PR: a research diff touches only itself and its graduation target.

## Rejected

- Spawning a test session with permission_mode default to measure a
  prompt-blocked record: manage.md Never forbids a session of one's own.

## Review

- r1: plan acceptance awk printed `above` with the row ABSENT (unset b=0 < u); measured `awk ... orchestrate.md` on this branch -> `above` (fixed: require b, prints `BELOW or absent` today)
- r2: (verifier) awk ordering check passed on an absent row and on rows placed below the merged row (`!b` latched a tools-row mention at orchestrate.md:49); measured on scratch copies (fixed: health-table rows only, require b<u AND b<m; today `misplaced or absent`, correct placement `above`, below-merged `misplaced or absent`)
- r3: (verifier) graduation called the IDLE verdict wrong, then kept it; IDLE+BLOCKED sample read as "no prompt pending" without evidence (fixed: list_events on that session shows last result end_turn/completed; IDLE kept report-only as the safe direction, stated as unmeasured for a prompt)
- r4: (verifier) unclear which field carried REQUIRES_ACTION (fixed: graduation says the report does not name the field)
- r5: (verifier) "no RUNNING row matches because each needs a push age" — the `retired, no claim file` row has push age any (fixed: four need push age, the fifth a dispatch row)
- r6: (verifier) permission_mode lever dropped from the graduation (fixed: named as the human's prevention lever)
- r7: (verifier) plan's "Measured:" carried no command/time (fixed)
- r8: (verifier) research diff adds a plan file, outside README "What a research file is not" (no change: precedent 74bcbf38, ac3e3a20, 47375385; named in PR body)
- r9: (verifier) new first-look rows would share `seen=` with the unclaimed rows (fixed: plan uses its own `held=` key)
- r10: (verifier) third acceptance bullet had no exact output (fixed: grep -c, `1` or more, `0` today)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` health table — rows the node cites.
