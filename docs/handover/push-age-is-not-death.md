---
workstream: push-age-is-not-death
status: in-progress
branch: claude/push-age-is-not-death
pr: none
plan: push-age-is-not-death
issue: 283
session: https://claude.ai/code/session_01F6UGCmZwiRAyMXPraicZSa
agent: opus
updated: 2026-10-10
next: ci green on r1-r8 fixes, retire workstream file, PR, merge
---

## Goal

Research node `docs/research/push-age-is-not-death.md` (issue #283): may the
scheduler print a respawn instruction on a row whose only evidence is the
age of the branch's last commit? Settle it, graduate the answer into
`joharness.sh`, delete the node.

## Decisions

- Answer: NO. No git-view signal separates a stopped manager from a stopped
  fleet; the row may ask for a control-plane read, never order a respawn.
  The code half already merged (PR #362: respawn clause cut, `PR in flight`
  softened, stopped-fleet suspicion line). This node graduates the answer
  as the record: `dispatch_age_min` comment (commit date, not push time)
  and a paragraph in `.agents/docs/orchestrated.md` under the knob table.
- Option 2 (`cost_usd` discriminator) stays open and is NOT a rule: its
  four frozen-cost windows and the WEAK mark land in orchestrated.md beside
  the 13-minute withdrawal, so they do not die with the node.
- `pushed` label kept: renaming it touches every row and its selftests, and
  since #362 the age only raises a cross-check, so the mislabel orders
  nothing. Comment says what it is.
- Option 2 re-filed as its own node, `frozen-cost-is-not-death-yet`, not
  dropped: the parent said it graduates separately (verifier r5).

## Rejected

- Editing `no-ceiling-on-one-item.md` / `asking-is-a-push-not-a-wait.md`
  pointers to this node: not my items; history recovers it.

## Review

Round 1, verifier at opus on 3c51ea8e. `./joharness.sh ci` at 3c51ea8e: `ci: pass`
(2026-10-10). `./joharness.sh verify` same day: `1 passed, 5 failed`, every
fail Docker Hub `429 Too Many Requests` pulling `alpine:3` — registry rate
limit, not this diff; the GitHub run's docker job is the layer's reading.

- r1: (verifier) orchestrated.md "no git row carries a respawn" — LOOP? churn row (`grep -n "respawn with the churn rule" joharness.sh`) is git and names a respawn (fixed: scoped to rows built on AGE; axis is what a reading is about)
- r2: (verifier) "all mid-step-7" overstates — node's third summary is mid-build (fixed: dropped; "both edge rows" for the two)
- r3: (verifier) windows are 18m19s–30m47s, not 19–31 (fixed: "18 to 31"; durations written in the new node)
- r4: (verifier) no-ceiling-on-one-item.md:208 says the windows are "carried by" the deleted node (wontfix here: another item's file, editing it collides with its manager — sent as lead no-ceiling-on-one-item; history recovers the node)
- r5: (verifier) deleting the node drops option 2 from the queue and its negative control and four refuted signals (fixed: new node docs/research/frozen-cost-is-not-death-yet.md carries them; orchestrated.md points at it; PR-in-flight boundary choice now said in orchestrated.md)
- r6: (verifier) 172.273s freeze labelled an issue number (fixed: says saved pages, re-computable, unconfirmed)
- r7: (verifier) 24-window text looser than code's three conditions (fixed: all three named)
- r8: (verifier) graph-lint warns workstream file claims a gone research stem (no change: expected; retire commit removes the file)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — edge `STALL?` row and `PR in flight` row.
- `joharness.sh:dispatch_age_min` — the age behind the row.
