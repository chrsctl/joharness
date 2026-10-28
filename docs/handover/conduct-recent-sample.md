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
next: ci on the r22-r25 fixes, then PR and finish
---

## Goal

Conduct samples the work merged since its last run, riskiest first, and its
C1 CONCERN rate shows on the dispatch `conduct   :` line.

## Decisions

- A1: confirmed — `conduct_candidates` reads all `--diff-filter=D` history; `conduct_sample` sorts by sha1(<stem>).
- A2: confirmed — `conduct_age_h` is `git log -1 --first-parent` on the ledger path.
- A3: confirmed — `conduct_rows` finds `C<n>` columns by header name.
- A4: confirmed for the needle (scout.sh:568), but the window also breaks the fixture's dated cases (plan-checker r1).
- Window is a commit range, not a clock compare: `<L>..base`, L = the base commit the last ledger branch was cut from (r15, r23 moved it off the landing merge `conduct_age_h` dates); no ledger = `<B>..base`, B = newest first-parent commit at or before now minus HOURS. A late run leaves no gap, and a branch cut before L but merged after it is in.
- retro.sh and conf-keys.sh joined `scope:`: retro.sh's zulu retire was dated outside the window, conf-keys.sh carries the HOURS row.
- Each new case fails on the old code: plain sha1 order is scout-command hotel clerk-role delta bravo echo alpha charlie, so charlie>bravo, alpha>bravo, hotel>bravo and mike>lima all invert, and kilo>lima holds only with `--no-merges`; november is dropped by a landing-merge window; oscar (Feb) is in the whole-history window; the old dispatch line carries no rate; the old tally prints 33%.
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
- r11: (plan-checker) retro.sh and conf-keys.sh joined scope as `shared:` but drop-curator-session holds them unshared (wontfix: one-line edits each; whichever lands second reconciles, and this plan file retires at merge, holding nothing)
- r12: (plan-checker) plan said the tally needle becomes `50%`, built text is `50% of 2 (NO EVIDENCE is no verdict)` (fixed: plan names the printed text)
- r13: selftest git execs 28.1 per case over the 28 budget: four git calls per candidate (fixed: `conduct_fm` reads every workstream and plan file in one cat-file each; one log per candidate)
- r14: (verifier) `--first-parent` lists a reconcile merge's first-parent diff since git 2.31, so merging main counted as touching harness code; 3 of 77 live candidates misranked (fixed: `--no-merges`; fixture kilo reconciles over a main-side harness change)
- r15: (verifier) a retire merged while a reviewer's pull request is open lands before the ledger merge and is never sampled (fixed: window opens at the reviewer's own ledger commit, not the landing merge; fixture november)
- r16: (verifier) stems past the cap leave the window for good (no change: the plan wants recent work; orchestrated.md row and plan now say so)
- r17: (verifier) a failed cat-file or per-candidate log read as "no plan, no harness" (fixed: conduct_ranked prints `?`, conduct_sample passes it on)
- r18: (verifier) HOURS large enough to put the cut before 1973 makes git misread `--until=@<n>` (fixed: such a window is the whole history)
- r19: (verifier) the "below a plan named with no file" needle passed on the old order (fixed: needle asserts the two close the sample, tally line next)
- r20: (verifier) fixture never touched joharness.sh nor merged main into a branch (fixed: mike and kilo)
- r21: (verifier) tier parse missed CRLF, quotes and capitals (fixed: conduct_fm strips `\r` and quotes, lowercases)
- r22: (verifier) the r21 CR strip ran before the byte framing, so a CRLF file swallowed the next file's header and that candidate lost its tier (fixed: CR stripped per line after the count; fixture papa CRLF ahead of quebec)
- r23: (verifier) a reviewer that merges main in and then commits the ledger again pulls retires it never sampled behind the window (fixed: window opens at the commit the ledger branch was cut from; fixture reviewer reconciles and edits the ledger after november)
- r24: (verifier) r17, r18, r21 had no test failing without them (fixed: cat-file wrapper reads UNREADABLE, HOURS=999999 reaches oscar, papa CRLF quoted capitalised)
- r25: (verifier) lowercasing the plan value missed a mixed-case plan file (fixed: only the agent compare lowercases)
- r26: (verifier) a claim off the retire's first-parent line reads as no harness and walks all history (wontfix: the Loop claims on the branch's own line; a miss costs one rank step, never a wrong window)
- r27: a ledger edited straight on the base branch opens the window at that commit, dropping earlier unsampled retires (wontfix: the ledger is reviewer-only by conduct.md §4; a human edit is a deliberate reset)

## Blockers

None.

## Where to look

- `joharness.sh:conduct_candidates` — candidate window.
- `joharness.sh:conduct_sample` — risk order.
