---
plan: hold-cost-on-the-holder
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest/dispatch.sh
---

## Goal

Issue #254, its first proposal. A branch in flight holds other plans out of
the queue through its file claims, and `dispatch` prints that only under the
HELD plans, never on the holder. The expensive branch looks free. Measured in
the issue: one branch claiming a broad path put nine plans on HOLD, and the
HOLD count fell from 16 to 10 in one pass when it merged.

## Scope

- `joharness.sh`, the in-flight row loop — annotate each row with how many
  DISTINCT plans its claims hold. The data exists: `holdmap` is already
  `<held stem>\t<holder> on <path> (claimed on <branch>)`, so the count is
  that map grouped by holder branch, deduplicated on held stem because one
  holder can hold one plan through two paths.
- `.agents/harness/selftest/dispatch.sh` — the cases go in the EXISTING
  dispatch topic, which already builds a fixture where one branch holds
  another plan. A new topic file would rebuild that fixture to assert
  against it.

## Out of scope

- What counts as free. A held plan is held exactly as before; this adds a
  number to a row and changes no verdict, no count and no spawn decision.
- The BLOCKED holder. It already releases its holds (`hold_live`), and a
  released hold must not be counted against the blocked row — that would
  reintroduce the misreading this fixes, one direction over.
- Issue #254's other two proposals. Resolving blocked-versus-gone decides
  whether a session may respawn a branch a human parked, which is product
  direction; bounding how long an unowned block may sit needs a threshold,
  and thresholds here are the human's.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- A fixture where one in-flight branch's claims hold two plans prints the
  count on that branch's row, and a fixture where it holds none prints no
  count. Both asserted: a row asserted in one direction passes when the
  annotation is deleted.
- A holder holding ONE plan through TWO declared paths counts 1, not 2.
  NOT asserted on this branch: the existing fixture has no such holder and
  building one is a fixture change wider than this diff. The dedupe is in
  the code (`seen[$1]++`) and the one-plan case refutes a count of 2, which
  is weaker. Named here rather than claimed, because the dedupe is the part
  a reimplementation gets wrong and the next reader should know it rests on
  reading the awk.
- A BLOCKED holder's row carries NO count, since its holds are released.
  Asserted, and it fails if the count is computed before the release.
- The numbers `dispatch` already prints are unchanged by this diff: the same
  fixture's free, HOLD and WAIT counts read identically before and after.
  This is the bullet that catches an annotation that accidentally moves a
  verdict.
- SHIPS: `joharness.sh` reaches every consumer. In a consumer,
  `./joharness.sh dispatch` under orchestrated mode on a queue with one
  holding branch prints the count on that branch's row.

## Where to look

- `joharness.sh:holdmap` — the map to invert, and its exact field shape.
- `joharness.sh:hold_live` — the blocked release, and why a released hold
  must not be counted.
- `joharness.sh:cmd_dispatch` in-flight loop — where `flag` is built, which
  is the one place a row's annotations belong.

## Traps

- Count DISTINCT held plans, never holdmap lines. One holder, two paths, one
  held plan is a count of 1.
- The count is presentation. A reader must not be able to tell the free
  count changed, because it must not.
