---
workstream: stall-rows-say-what-git-knows
status: in-progress
branch: manage/stall-rows-say-what-git-knows
pr: none
plan: stall-rows-say-what-git-knows
issue: 283
session: https://claude.ai/code/session_015AjcweMJ4sZHA4LAqqMhrM
agent: opus
updated: 2026-10-10
next: ci green on r9-r12 fixes, retire, PR, merge
---

## Goal

Issue #283: `dispatch` says three things without evidence — `PR in flight`
(it never reads a PR), `respawn on the branch to FINISH it` on a STALL? edge
row (verdict belongs to orchestrate.md's health table), and nothing when the
whole fleet is silent and `main` frozen (a suspension, not N dead managers).

## Decisions

- Base age read through `dispatch_age_min <base>`: the one `git log -1
  --format=%ct` the plan allows, already `</dev/null`, already the unit
  the stall test uses.
- Stopped-fleet fixtures get their own repo: the condition is about EVERY
  row in flight and the base's own age, both decided elsewhere in the
  shared fixture. A third case (window 180m: row stalls, 24x does not)
  pins the multiple, not just the 1x test.
- Built without workers: three files, ~100 lines, and orchestrate.md must
  change in the same commit as dispatch's row text (plan Traps).

## Rejected

- Printing the line on 1x stall window: with one manager in flight the base
  only moves when it merges, so it fires on every ordinary stall (plan).

## Review

Round 1, verifier at opus on 6051a47a. Mutation counts below: dispatch topic
alone (`selftest.sh` with its topic loop cut to `dispatch`), 2026-10-10; the
one carve-out FAIL in each is that cut runner's own file, not the tree.

- r1: (verifier) stopped-fleet line fired with a manager pushed 1h ago and main 48h still — base age alone is no suspension (fixed: youngest stall row must be past 24 windows too; mutation drops it → `FAIL a manager silent one hour is no frozen fleet`)
- r2: (verifier) `JOHARNESS_STALL_MINUTES=0` → 24 windows = 0, line prints on a 0m base (fixed: `stall -gt 0` guard; mutation → `FAIL and suspects no fleet on a zero multiple`)
- r3: (verifier) `n_stall -eq n_inflight - n_blocked` unpinned, green both ways (fixed: one-stalled-one-live case at 180m, plus a blocked row that must not void it; mutation → `FAIL and one live row voids the suspicion`)
- r4: (verifier) line ignores fetch_failed: a stale clone reads as a stopped fleet (fixed: line says `(or this clone is stale: no fresh fetch this pass)` when the pass did not fetch; orchestrate.md says so too)
- r5: (verifier) curator/janitor/scout branches never count into n_inflight, so a live one does not void the line (wontfix: those branches are scanned only when their cycle is due, so on most passes there is no row or age to read without new git calls the plan does not budget; the line speaks of managers, which they are not, decides nothing, and orders a control-plane read for each row — reason corrected per r11)
- r6: (verifier) docs/research/push-age-is-not-death.md Verification greps and no-ceiling-on-one-item.md:168 quote the removed text (wontfix here: research items this branch does not own — named in the PR body and as a lead)
- r7: (verifier) plan Acceptance `bash .agents/harness/selftest/dispatch.sh` cannot run alone (no change: ran the topic through selftest.sh with its loop cut to `dispatch` — 423 passed, 1 failed (the cut runner's own file); full `./joharness.sh verify` and `ci` recorded in the PR)
- r8: (verifier) `not 1 dead managers` at n=1 (fixed: `manager(s)`, the file's own plural)

Round 2, verifier at opus on ca2354d3.

- r9: (verifier) the stale suffix tested only where it prints — every fixture pass ran DISPATCH_FETCH=0; mutation printing it always stayed 424/0 (fixed: a DISPATCH_FETCH=1 pass against the fixture's bare origin refutes it)
- r10: (verifier) suffix said `no fresh fetch this pass` where a short refspec fetched main fresh (fixed: names all three causes, as the scout-hold line does)
- r11: (verifier) r5's reason overstated — curator ages are already read, and role rows print only when due (fixed: r5 reason reworded; code unchanged)
- r12: (verifier) plan Scope still specs the pre-r1 line (no change: the plan file is retired in this PR; this record carries the delta, and the PR body names it)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — edge_rows text, verdict tail.
