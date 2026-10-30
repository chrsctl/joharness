---
workstream: orchestrator-swap-stall
status: in-progress
branch: orchestrator-swap-stall
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK3QQkaEaufEDXwCr5n
agent: sonnet
updated: 2026-10-30
next: Run ci and verify, open the pull request, merge on finish
---

## Goal

gx stalled 2026-10-30 03:46Z to 07:30Z with no orchestrator running. The
keeper's SWAP started successor `pass=1` while the retiring session's
`pass=7 retire=yes` wake was still pending. The successor read that other
session's wake as superseding it and stood down. Its transcript says so:
"Another session ... has a pending wake ... carrying `pass=7` ... under the
Pass entry rule I stand down". The retired session's wake then did nothing.
Every hourly keeper after that called the successor LIVE on its title alone,
though it was IDLE with no wake pending.

## Decisions

- Superseded check: the old text already limited it to this session's
  wakes, and the successor misread it anyway. The fix spells out that
  another session's wake never supersedes, and that Duplicate stops only on
  a LIVE session, so a retired one stops nothing.
- keeper step 2: a `🎼` title neither RUNNING nor PENDING with no pending
  wake is NOT LIVE, as the reference's "## 0. Start" step 3 already defines
  it. The haiku keeper read the dense sentence as "titled and not archived
  = LIVE" for four hourly wakes in a row.

## Review

- r1: edge review, my own read of the diff against ref "## 0. Start" step 3, § Duplicate, § Out-of-band arm: no contradiction found (no change)
- r2: (verifier) keeper "Else NOT LIVE" dropped the reference's held-wake clause for the parent/last-started session (fixed: now "Neither, and no pending wake = NOT LIVE")
- r3: (verifier) a human-started RUNNING orchestrator that is not the parent can draw a second start (no change: pre-existing, documented in keeper.md, the second exits at ref step 3)
- r4: (verifier) the superseded check already filtered to own wakes, so the change clarifies rather than changes behaviour (no change: the successor's transcript shows it misread; clarifying text is the fix)
- r5: (verifier) "Duplicate's matter" pointer was hollow: Duplicate acts only on a LIVE session (fixed: text now says a retired one stops nothing)
- r6: (verifier) SWAP sentence lost its subject after the insert (wontfix: selftest pins "LIVE, and its pending wake's ... = SWAP"; the inserted sentence now ends on "NOT LIVE, whatever its title.", so LIVE reads as the next rule's subject)
- r7: (verifier) "stood down" was an unglossed term in keeper.md (fixed: dropped)
- r8: (verifier) needles pin prose not behaviour (wontfix: harness rules are prose, selftest pins prose by design)
- r9: (verifier) the 100-wake list_triggers cap can hide a live session's wake (wontfix: pre-existing bound in keeper.md, not changed here)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrator.md` Pass entry, Superseded.
- `.claude/commands/keeper.md` step 2.
