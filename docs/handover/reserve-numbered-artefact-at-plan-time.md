---
workstream: reserve-numbered-artefact-at-plan-time
status: in-progress
branch: research/reserve-numbered-artefact-at-plan-time
pr: none
plan: reserve-numbered-artefact-at-plan-time
issue: none
session: https://claude.ai/code/session_01J1YMK78vSStgy6SqLSw8Wb
agent: opus
updated: 2026-11-12
next: rerun ci, retire (delete workstream file), open PR, finish, merge
---

## Goal

Settle the research question: should plan writing reserve a numbered
artefact, and should the finish loop's retest set treat a rename of a
branch-changed path as RETEST rather than a full run. Graduate the answer to
`.agents/docs/consumer-repos.md`, delete the research file.

## Decisions

- (b) settled GROUNDED: `checks_paths` uses `--no-renames`; a replay of step 3's
  commands on a fixture (branch renames its own 0390 file to 0391 after merging
  a base that added another 0390) leaves the destination stray = full run. A
  gap, not a bound: decided the destination of a rename whose source is in
  `known` joins `R`. Code change = plan `retest-renamed-branch-path` (a
  research PR touches only the file and its graduation target).
- (a) decided yes: reserve the number in the plan's own PR; rule line goes to
  `plans.md`, `plan.md`, `clerk.md` via plan `reserve-numbered-artefact`; the
  why graduates to `consumer-repos.md`.

## Rejected

- (a) as consumer-only practice: the harness's parallel managers create the
  race, and the reservation rides a PR that merges anyway.

## Review

- r1: (verifier) spawn prompt carried intent and a focus list beyond subagents.md (no change: report judged without it; noted for later spawns)
- r2: (verifier) consumer-repos.md over its reading budget, ci red (fixed: graduation paragraphs cut to fit)
- r3: (verifier) retest plan Acceptance named a nonexistent `selftest` subcommand and an impossible grep (fixed: `bash .agents/harness/selftest.sh` with label greps)
- r4: (verifier) both plans SHIP but Acceptance named no consumer check (fixed: consumer `ci` line added to each)
- r5: (verifier) reserve plan collides with clerk and manager "plans only", and `shared:` re-created the registry edit (fixed: carve-outs in scope, `shared:` instruction dropped)
- r6: (verifier) "merged before any build" overclaimed, plans can ride the building branch; "rule in plans.md" not yet true (fixed: "when it merges ahead of the build", rule cited as the plan)
- r7: (verifier) rename rule admitted any >=50% similar new path, e.g. helpers.py to conftest.py (fixed: same directory, names equal but for digits; plan adds non-renumber rename and plain add cases)
- r8: (verifier) research diff adds plan files beyond file and graduation target (no change: manager.md §2 routes follow-up work that must outlive the session into plan files in this PR; research.md's rule targets code)
- r9: (verifier) reservation paragraph ran into the commit-count knob text, line past wrap (fixed: paragraphs rewritten, knob text stays before them)
- r10: (verifier) doc said the destination joins R, it already does; it joins known (fixed: "counts as known")
- r11: (verifier) "where a catch-up would do" wrong, it is a RETEST (fixed: phrase removed)
- r12: (verifier) gx figures labelled WEAK though the node had them UNGROUNDED (no change: WEAK, a consumer's reading, is the doc's convention for a consumer's own record)
- r13: (verifier) GROUNDED replay not recorded as commands (fixed: commands in retest plan A2)

## Blockers

None.

## Where to look

- `docs/research/reserve-numbered-artefact-at-plan-time.md` — the item.
- `.agents/docs/consumer-repos.md` "The finish loop" — graduation target.
