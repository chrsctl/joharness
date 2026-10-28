---
workstream: conduct-recent-sample
status: in-progress
branch: claude/conduct-recent-sample
pr: none
plan: conduct-recent-sample
issue: none
session: https://claude.ai/code/session_01J1YMK3jCqjLJi3BLSYzNCG
agent: opus
updated: 2026-10-28
next: ci green on the rewritten conduct fixture, then verify, verifier, PR
---

## Goal

Conduct samples the work merged since its last run, riskiest first, and its
C1 CONCERN rate shows on the dispatch `conduct   :` line.

## Decisions

- A1: confirmed — `conduct_candidates` reads all `--diff-filter=D` history; `conduct_sample` sorts by sha1(<stem>).
- A2: confirmed — `conduct_age_h` is `git log -1 --first-parent` on the ledger path.
- A3: confirmed — `conduct_rows` finds `C<n>` columns by header name.
- A4: confirmed for the needle (scout.sh:568), but the window also breaks the fixture's dated cases (plan-checker r1).
- Window is a commit range, not a clock compare: `<L>..base`, L = the first-parent commit `conduct_age_h` dates; no ledger = `<B>..base`, B = newest first-parent commit at or before now minus HOURS. A late run leaves no gap, and a branch cut before L but merged after it is in.
- retro.sh and conf-keys.sh joined `scope:`: retro.sh's zulu retire was dated outside the window, conf-keys.sh carries the HOURS row.
- Built directly, not by workers: every edit lands in joharness.sh and scout.sh, one shared file pair = sequential.

## Rejected

- None yet.

## Review

- r1: (plan-checker) window breaks the existing dated conduct fixture cases, not one needle (fixed: plan Acceptance names the re-dating)
- r2: (plan-checker) dispatch rate excludes NO EVIDENCE while the tally's rate counts it (fixed: plan aligns the tally's rate)
- r3: (plan-checker) "the conduct lines" vs "not due / DUE printers" disagree (fixed: plan names every line but UNREADABLE)
- r4: (plan-checker) "0% of 3" expires when a conduct run lands (fixed: acceptance reads the ledger at check time)
- r5: (plan-checker) consumer acceptance not runnable here (wontfix: the standard SHIPS line, checked after sync by design)
- r6: (plan-checker) shared scope overlaps with queued plans (wontfix: every overlap is `shared:` in both, reconcile at finish)
- r7: (plan-checker) a later fixed-date first-parent commit (foxtrot) closes the no-ledger window over the re-dated retires; plan never said which timestamp (fixed: plan names the cut point, fixture dates foxtrot and retro.sh's zulu now)
- r8: (plan-checker) harness-touch range lacked `--first-parent`, so a reconcile merge would count (fixed: plan wording; code already first-parent)
- r9: (plan-checker) rate suffix undefined for unreadable ledger and rows with no FINE/CONCERN (fixed: plan defines nothing / `0% of 0`, as built)
- r10: (plan-checker) JOHARNESS_CONDUCT_HOURS gains the no-ledger reach but its rows did not say so (fixed: KNOBS, orchestrated.md, conf-keys.sh rows)

## Blockers

None.

## Where to look

- `joharness.sh:conduct_candidates` — candidate window.
- `joharness.sh:conduct_sample` — risk order.
