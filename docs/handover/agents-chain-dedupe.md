---
workstream: agents-chain-dedupe
status: review
branch: claude/agents-chain-dedupe
pr: none
plan: agents-chain-dedupe
issue: none
session: https://claude.ai/code/session_01BDfsCGoruYgyX1BNVnpv83
agent: opus
updated: 2026-10-10
next: retire plan + workstream file, PR, merge
---

## Goal

Every session loads `CLAUDE.md`, root `AGENTS.md` and
`.agents/harness/AGENTS.md`. They say several things twice and the harness
file carries history. State each fact once; move the why out
(`docs/plans/agents-chain-dedupe.md`).

## Decisions

- No workers: the build is one file (`.agents/harness/AGENTS.md`); a shared
  file is sequential anyway, and every cut is a judgement call against the
  plan's keep-every-rule bar, not typing.
- Root `AGENTS.md` untouched, Part 2 included: its CI-runnable clause is the
  one non-Claude readers see, and the count reaches 2 from the harness side.
- Every why the plan named already lived in its allowed destination doc, so
  nothing was MOVED: each cut is a duplicate, and the sentence keeps a
  pointer where it had a citation.

Size, `./joharness.sh context`, 2026-10-10, clean tree at the commit
carrying this line: instructions 17730 bytes / 2490 words at merge base ->
16915 bytes / 2381 words (harness file 2080 -> 1971 words).

## Rejected

## Review

Ledger, one row per removed block (plan Scope). A table, not bullets: the
bullets below are findings (`- r<N>:`), which `feedback` attributes to files.

| Removed | Where it lives |
| --- | --- |
| harness env paragraph ("Environment rules are not here ...") | duplicate of AGENTS.md:5-9 (root Part 1, ships to consumers). |
| step 4 "Six merged edges paid for this one" | duplicate of .agents/docs/feedback.md:148 (Worked example: tree or diff); pointer kept. |
| step 4 "another PR merging mid-build is cheap to catch now ..." | duplicate of .agents/docs/product/README.md:164-166 (Branch flow, Long-running session); pointer kept. |
| step 5 CI-runnable clause | criterion kept, now as the `ci-verify` marker of .agents/env/README.md:24-28 (the plan's "pointer at step 7" did not hold: step 7 never stated which layers, r1); full clause kept in root Part 2 (AGENTS.md:44-46); step 7 keeps its read-the-run clause. |
| step 7 "(ratified 2026-08-23)" | duplicate of .agents/docs/product/README.md:126 (Branch flow, Finish). |
| step 7 "squash/rebase merge breaks the merged-branch ancestry filter" | duplicate of .agents/docs/product/README.md:133-135 (Branch flow); pointer kept. |
| step 7 "Skipped, the base branch accretes finished workstreams ..." | duplicate of .agents/docs/handover/README.md:508,526 (Graduation); pointer kept, heading named. |
| harness Handover "One file per workstream under docs/handover/, lives on work branch" | duplicate of AGENTS.md:13. |
| harness Handover "Same commit as code. Push early ..." | duplicate of AGENTS.md:18-19 and harness step 6. |
| harness Handover "Push time not liveness. Wrong both directions. /who = truth." | rule duplicate of AGENTS.md:20; "wrong both directions" why lives in .agents/docs/handover/README.md:288,298 (r3). |
| harness Handover "Diff self-describing." | duplicate of harness step 2 (copy or sync task sentence). |
| harness Handover "Full protocol + why: handover/README.md" | duplicate of AGENTS.md:13-14 ("Protocol: ..."). |

Left in place, cites no allowed doc: step 2 "oldest edge branch is the one closest to abandoned" (none); step 5 bash-guard incidents and Stop guard why (`.agents/harness/pretool-bash-guard.sh`); step 7 "Why two strengths" (`joharness.sh:fin_strength`); step 7 "merge on their clock ... follow-up pull request to undo" (none); step 7 "every other guard fires after the merge" (none); step 2 curate and step 7 heartbeat text (mode text, out of scope; orchestrated.md / curate.md).

- r1: (verifier) step 5 pointer "which ones: step 7" sent the reader to a step that never says which layers GitHub verifies; criterion lost from the chain a consumer loads (`git show origin/main:.agents/harness/AGENTS.md | grep -n CI-runnable` -> 84, 145) (fixed: step 5 names the `ci-verify` marker and `.agents/env/README.md`; count stays 2)
- r2: (verifier) branch-side size numbers in Decisions were taken mid-edit, not on the head (context at 63555f3a: 16875 / 2379) (fixed: recounted on the head that carries them)
- r3: (verifier) ledger called "Wrong both directions" an exact duplicate of AGENTS.md:20; that why lives only in handover/README.md:288,298 (fixed: ledger row says so; why, not a rule, so no text restored)
- r4: (verifier) kept Handover copy-or-sync bullet partly repeats step 2; step 6 repeats root :18,21 (wontfix: only the bullet says NO workstream file and names consumer-repos.md; step 6 outside plan scope)
- r5: (verifier) docs/research/an-injection-live-under-a-dispatched-reader.md:152-154 quotes the removed "Six merged edges" line at a line number already off on main (wontfix: out of scope, research file is a dated record)

## Blockers

None.

## Where to look

- `docs/plans/agents-chain-dedupe.md` — scope, acceptance.
