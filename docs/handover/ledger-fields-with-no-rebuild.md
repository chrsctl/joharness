---
workstream: ledger-fields-with-no-rebuild
status: in-progress
branch: claude/ledger-fields-with-no-rebuild
pr: none
plan: ledger-fields-with-no-rebuild
issue: 307
session: https://claude.ai/code/session_01EBbfrQriYghvs7sdAuqiio
agent: opus
updated: 2026-10-10
next: Retire node + this file, PR, merge
---

## Goal

Research node `docs/research/ledger-fields-with-no-rebuild.md` (issue #307):
which orchestrator ledger fields can be rebuilt from a read the role already
makes, and what each of the rest costs when a pass drops it. Findings are
written and verified in the node; the work is graduating them into
`.claude/commands/orchestrate.md` and deleting the node.

## Decisions

- `.claude/commands/` is NOT a protocol path today (`./joharness.sh
  protocol-paths` prints joharness.conf, .claude/settings.json, .github), so
  the node's "branch is a human's" note is stale; graduating here.
- Most of the answer already landed on main before this claim (step 0.2
  title rebuild of `@new`, per-field loss lines in §4). Residue graduated
  here: the `:637`/`:700` pair that described entry age two incompatible
  ways (rewritten to match the rows: age gates entry to the ladder, `seen=`
  the verdicts), the rebuild's partiality (existence and count, never age),
  and `respawns=`'s missing cross-check written down as "nowhere".

## Rejected

## Review

- r1: (verifier) `orchestrate.md:326` "IDLE, and never born" paragraph still named PREVIOUS-pass age as a stillborn-row condition — the same contradiction this diff removes at `:637`. (fixed — says no row there keys on age; the first-look row gates them through `seen=`)
- r2: (verifier) `.agents/docs/orchestrated.md:122` stillborn row's git column says entry `new` from a previous pass. (no change — that row summarises the whole ladder, pass 1 recording `seen=` included, so the condition is true of its first step)
- r3: (verifier) "a rebuilt entry reaches the ladder one pass late" is a minimum: a lost entry that had `seen=` loses it too, verdict two passes late. (fixed — "at least one pass late, two when it had `seen=`")
- r4: (verifier) "the one honest reading — successor commits in git" misses stillborn re-spawns, which count against the limit and commit nothing. (fixed — says nearest reading, and blind to them)
- r5: (verifier) "a measurement no command makes" — checked TRUE: `grep -n -i "respawn\|successor" joharness.sh` finds only the knob print and prose. (no change)
- r6: (verifier) the node's "research node has no `scope:`" note is not carried; it repeats in 6 nodes. (wontfix — not orchestrate.md material, and the 5 other copies survive this delete; a graduation for whoever owns that rule)
- r7: (verifier) step 0.2 could rebuild `@new` for a claimed manager whose whole entry was dropped. (no change — step 1 already drops every rebuilt entry whose stem has a claimed in-flight row, `orchestrate.md:132`)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — §4 ledger grammar; step 0.2 list_sessions.
