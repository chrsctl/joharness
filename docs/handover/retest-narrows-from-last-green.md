---
workstream: retest-narrows-from-last-green
status: in-progress
branch: claude/magical-ramanujan-1nafcm
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK5E6SxsEcCUph3motq
agent: opus
updated: 2026-11-20
next: open PR, finish, merge, sync to chrsctl/gx
---

## Goal

`finish` under local checks starves on a busy base: the retest set, measured
from the certificate every lap, keeps a path both sides changed once even
when the last green retest ran it as both sides still hold it (chrsctl/gx
#1990: 9 laps of ~23 min, every CRM suite each lap for
`platform/tests/served.py`). Carry such paths from the last green scoped
retest of the same chain. The human asked for it through the fast lane.

## Decisions

- Root and bound stay at `C`; the record only narrows `R`, never certifies.
- A path is carried only when BOTH its base side is unchanged since the green
  retest's pinned tip AND HEAD's blob equals the green head's blob.

## Review
- r1 (verifier): RETEST line printed an empty sha: CHECKS_CARRY_FROM set inside a command substitution (fixed: caller reads the head off the record)
- r2 (verifier): selftest red — case 2 counts 4 base commits now, consumer-repos.md over its reading bound (fixed: expectation, doc trimmed to 27443 ≤ 27484)
- r3 (verifier): case 14 passed with the feature absent (fixed: presence asserted before the full run)
- r4 (verifier): a check that touches SCOPED without running a handed path makes it carried on later laps (wontfix: such a check already passes its own lap; the contract — re-run every suite a set path feeds — is unchanged and binds every lap)
- r5 (verifier): record written before checks_level_end, so a BEHIND-red run leaves it (no change: it names the head and base actually tested green, same ordering as the certificate)
- r6 (verifier): doc omitted the from=C / ancestor conditions (fixed: "from this `C`" in step 3; ancestry is the code's guard)
