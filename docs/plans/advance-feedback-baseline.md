---
plan: advance-feedback-baseline
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh
---

## Goal

`./joharness.sh sources` reports the sweep NOT dry: `JOHARNESS_FEEDBACK_EDGES=0
./joharness.sh feedback` counts 4 unmarked findings since `FB_SINCE`
(`bcebb325e92f`, set in PR #161). All four predate PR #181
(`marker-gate-retire-trigger`, merged as `847f64e3`), which closed the
loophole that let a branch retire — deleting its own workstream file — with
an undispositioned finding still in `## Review`. Before that gate, a branch
could merge straight from `review` to its retire commit without ever
tripping `lint_finding_markers`, and these four did:

- `PR161 r6`, `PR172 r5`, `PR173 r2`, `PR174 r2` — all end in prose (`(recorded
  — ...)`, or nothing at all) that `fb_marker` does not read as `(fixed`,
  `wontfix`, or `no change`. The workstream files that held them are deleted
  from every tree (delete-on-merge), survive only inside those four already-
  merged commits, and cannot be edited in place — the same
  structurally-undispositionable shape PR #161 baselined the first 155
  findings for, for the same reason: `sources` runs `dry=0` on any nonzero
  unmarked count, so an unattended fleet blocked on this can never stop.

source: merged review findings never acted on
evidence: `JOHARNESS_FEEDBACK_SINCE=847f64e32e8153e5a9e330ab0d84615c578e80c3
JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback` (run 2026-09-02) reports
0 unmarked since that commit; the default baseline
(`bcebb325e92f`) reports 4.

## Scope

- `joharness.sh:FB_SINCE` — the literal default, moved from `bcebb325e92f`
  (PR #161's base) to `847f64e3` (PR #181's merge commit, the point the
  retire-commit gate went live). Comment above it gets a short addendum
  naming the four findings this bump absorbs and why they cannot be
  dispositioned any other way.

## Out of scope

- Retroactively editing the four findings' text. The commits that hold them
  are already merged; nothing in this repo rewrites merged history.
- Any further change to `fb_marker`'s vocabulary or to the retire-commit
  gate itself (PR #181). Both already do their job; this plan only moves
  the line that says where "already accounted for" starts.
- `JOHARNESS_FEEDBACK_SINCE` overrides for consumer repos — per-repo by
  design (the comment already says so), untouched here.

## Acceptance

- `JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback` (default baseline,
  no override) — `0 unmarked`, `counted since 847f64e3`.
- `./joharness.sh sources` — the "merged review findings never acted on"
  line reads `0 unmarked`.
- `./joharness.sh ci` — pass, selftest green, no new failures.

## Where to look

- `joharness.sh:FB_SINCE` — the literal this plan moves.
- `joharness.sh:fb_since_ok` — resolves the literal; unaffected, but the
  same commit must resolve in a shallow consumer checkout the way
  `bcebb325e92f` already did (both are `main` ancestors going back further
  than any repo's own history could be shallow past in practice — same
  reasoning PR #161 already accepted for the first baseline).

## Traps

- A baseline a session moves to make its own backlog disappear is exactly
  what PR #161's design note warns against. This plan is not that: the
  four findings predate the fix (PR #181) that stops new ones from reaching
  this state, so nothing merged under the current gate is being swept under
  the rug — only debt that is provably impossible to disposition otherwise.
- Literal, not derived: `FB_SINCE` stays a plain sha in a reviewed diff, the
  same reasoning `joharness.sh:FB_SINCE`'s own comment already states for
  why it is not computed.
