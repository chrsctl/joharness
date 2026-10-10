---
workstream: cost-per-merge-levers
status: in-progress
branch: claude/cost-per-merge-levers-r1
pr: none
plan: cost-per-merge-levers
issue: none
session: https://claude.ai/code/session_01PKRtVz3i86StN45K3yZ7nE
agent: opus
updated: 2026-10-10
next: Fold the second-context recheck into the research file Verification, run review + verifier, retire, PR
---

## Goal

Settle `docs/research/cost-per-merge-levers.md`: does any of four levers cut
cost per merged edge by >=20% without raising respawns, kills or reverts.

## Decisions

- Settle by CEILING before trial: a lever can cut cost per merge by at most
  (share of fleet cost it touches) x (its largest price cut). Under 20% =
  NO with no trial, which needs no human. Only a lever whose ceiling
  clears 20% needs the human-switched trial the file's Method planned.
- Denominator = manager cost only (orchestrator left out): it raises every
  ceiling, so a NO under it is safe.
- Lever 2: 0 of 168 children of the two orchestrators ran Fable
  (list_sessions, 2 pages) — touched share 0.
- Measured rates, Qnp3Vu sonnet-5-5 modelUsage: read 0.10, 5m write 2.50,
  out 10 reproduce 8.188 USD exactly; the claude-api skill table's 0.20
  sonnet cache read does not.

## Rejected

- Closing lever 3 NO on the equal-token ceiling (18.6% here): a sonnet
  verifier spending <=92% of the opus tokens clears 20%, so that NO would
  be a guess. Split out as `sonnet-verifier-on-opus-plans`.

## Review

- r1: (verifier) Method gave sonnet 5 the sonnet 5.5 rates as checked; its 3 sessions price to ~58% of billed (fixed: sonnet 5 marked not established, no ceiling uses their split; graduation line rewritten)
- r2: (verifier) lever 1 in-turn reading overwrote `## Echo` and left Findings saying touched share 0 (fixed: Echo restored from origin/main, reading moved to Findings)
- r3: (verifier) GROUNDED on split-based findings while Verification called the split WEAK (fixed: second re-take of the split for the 4 sessions that carry levers 3 and 4, marks set from it)
- r4: (verifier) "37.1% of opus-tier manager cost" divides by all 12 sessions (fixed: relabelled in follow-up node and graduation)
- r5: (verifier) follow-up settling rule undefined for a missed wontfix/no-change finding and for whose record counts (fixed: the merged edge's own `## Review` is the record; only `(fixed)` misses count)
- r6: (verifier) follow-up 0.46 threshold drops the manager-only caveat (fixed: stated as NO-only, fleet trial decides YES)
- r7: (verifier) follow-up scope is this repo but its consequence edits rules every consumer runs (fixed: consequence scopes the change, human decides how)
- r8: (verifier) "within 0.24 on 23 of 24" off by wording (fixed: 0.11 on 23 of 24)
- r9: (verifier) "175 fleet children" counts a third orchestrator's 7 (fixed: 168 + 7 named separately)
- r10: (verifier) "cuts 80% vs opus 5" holds for cache read only (fixed: "at most 80% (cache read; 60% on the rest)")
- r11: (verifier) overage, in-turn rule and merged reading missing from Method (fixed: three Method bullets; overage now rests on per-turn 5m writes, not the read-time flag)
- r12: (verifier) graduation duplicated the page's own 0.10 note and had an 85-column line (fixed: line removed, reflowed)
- r13: (verifier) hand-written dates beside measurements (no change: Loop step 5 asks a measured number to name when; the follow-up Echo's date was removed)
- r14: (verifier) ci red on the empty Review (fixed: this section)

## Blockers

None.

## Where to look

- `docs/research/cost-per-merge-levers.md` — the question and its Method.
- `.agents/docs/agent-selection.md` Cost levers — graduation target.
