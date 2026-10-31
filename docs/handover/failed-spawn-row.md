---
workstream: failed-spawn-row
status: in-progress
branch: claude/failed-spawn-row
pr: none
plan: failed-spawn-row
issue: none
session: https://claude.ai/code/session_01J1YMK5ar6zySs8TZR5L7EP
agent: opus
updated: 2026-10-31
next: Second verifier look at the fix commit, verify, then finish
---

## Goal

Human's order: an `@new` entry whose session ended unclaimed (no checkout,
gx 2026-10-31) held a slot for ~2 h. Free it, catch the missing source at
spawn, and pin that every slot-holding ledger entry has an exit.

## Decisions

- Past the limit the entry drops and the stem goes on a run-scoped
  `failed=<stem>` key: dropping alone would let §3 spawn it again next pass.

## Rejected

- None yet.

## Review

- r1: edge review, own read: the main table's crash and dead rows sent an `@new` past the limit to § Respawn limit, which needs a branch (fixed: RESPAWN of a `new` entry past the limit = FAILED SPAWN AT LIMIT, never § Respawn limit)
- r2: (verifier) spawn prompt carried the cause and the asks beyond tier, branch, base (no change: the human's order is the spec here, no plan stem existed for it to read; the verifier judged the diff alone)
- r3: (verifier) a FAILED-bucket `@new` met the crash/dead rows above the pointer row and reached § Respawn limit with no branch (fixed: pointer row moved third, above every push-age and record row; RESPAWN text as r1)
- r4: (verifier) FAILED SPAWN AT LIMIT left the session alive and the `@new` rebuild re-added it; "once" had no key (fixed: at the limit the session is archived, rebuild skips `failed=` stems, the push fires only for a stem not yet on `failed=`)
- r5: (verifier) a RUNNING unclaimed `@new` matched "working" forever (fixed: RUNNING rows in the unclaimed table: starting under `JOHARNESS_STALL_MINUTES` since `created_at`, then a nudge, then FAILED SPAWN)
- r6: (verifier) a throttled IDLE `@new` was killed as a failed spawn (fixed: throttled row first, next pass decides)
- r7: (verifier) `interrupt_session`-absent row both respawned and dropped an ARCHIVED unclaimed entry (fixed: only an unclaimed session a row would interrupt goes to the limit exit)
- r8: (verifier) Source check's second failure left the old `@new` respawning each pass (fixed: a manager's second failure = FAILED SPAWN AT LIMIT, dropping the entry; a role ledgers only its stamp key)
- r9: (verifier) COMPLETED handled in one table only, not archived, BLOCKED row caught it first (fixed: COMPLETED in GONE, the claimed gone row, the interrupt row; archived on the FAILED SPAWN row, which now precedes the BLOCKED rows)
- r10: (verifier) "working: drop that record" dropped `seen=` on an IDLE `@new` each pass (fixed: pointer row above it; the unclaimed table re-records a moved look itself)
- r11: (verifier) selftest check was a substring match, passed an at-limit report (fixed: a spawning row must name FAILED SPAWN AT LIMIT, bans `report only`, `keep the entry`, `never respawn`; the checker is run on the three bad rows; pointer-row order pinned)
- r12: (verifier) `slot held with no exit` push had no once key (fixed: `noexit=<stem>` run-scoped)
- r13: (verifier) "re-spawn" spelling; at-limit BLOCKED session could later claim past the cap; surveyor failing the Source check twice ledgered `rescope-<key>@new` (fixed: respawn; the limit exit archives; a role ledgers only its stamp key)
- r14: (verifier) whether `sources` is set at once on create could not be checked here (no change: the reference's field table already reads it as checkout attached at spawn; the gx records that lacked it were the failed spawns)
- r15: verify on head 6c4f89fa 08:43Z red twice in docker networking and compose; paired run on origin/main c8e797c7 green, re-run on the head green 6/0 (no change: flake in the environment layer, diff touches none of it)
- r16: (verifier) spawn prompt carried "do not modify the tree" and a plan path hint (no change: neither steered the verdict)
- r17: (verifier) an `@new` claimed between passes still read `new` and the raised pointer row respawned it as unclaimed (fixed: §1 turns every claimed `@new` into `<stem>@<head>`, respawns kept; the pointer row's ledger cell tests "no claimed in-flight row")
- r18: (verifier) the throttle row waited forever on an ended session (fixed: row removed; an unclaimed throttle gets the IDLE look, then FAILED SPAWN with the detail in the push; field table notes it)
- r19: (verifier) the Source check could fail healthy spawns if `sources` fills late (fixed: the call must carry `source_url`; after it, only tag `config:no-git-repo` or a wrong repository decides, a missing `sources` waits for the unclaimed rows)
- r20: (verifier) a RESPAWN on a branch failing the Source check twice went to the unclaimed exit (fixed: § Respawn limit for a branch)
- r21: (verifier) the RUNNING nudged row killed a session that moved (fixed: kill only unchanged since the nudge, or `created_at` twice `JOHARNESS_STALL_MINUTES` old; moved and younger = next pass decides)
- r22: (verifier) consumer-side Acceptance cannot run, the selftest is canonical-only (fixed: plan says so)
- r23: (verifier) `noexit=` not declared run-scoped, read before §2 ran (fixed: run-scoped, read at §2's end); `PushNotification`-absent row missed two pushes (fixed)
- r24: (verifier) no plan-checker ran on an opus plan; COMPLETED in the claimed rows is beyond the plan's Goal (no change: same-session plan on the human's order, two verifier passes stand in; COMPLETED kept because a claimed manager whose session completed otherwise matched no row)

## Blockers

None.

## Where to look

- `.agents/docs/orchestrator-reference.md:## Unclaimed spawn rows`.
