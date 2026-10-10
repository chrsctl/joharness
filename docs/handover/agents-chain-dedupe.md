---
workstream: agents-chain-dedupe
status: in-progress
branch: claude/agents-chain-dedupe
pr: none
plan: agents-chain-dedupe
issue: none
session: https://claude.ai/code/session_01BDfsCGoruYgyX1BNVnpv83
agent: opus
updated: 2026-10-10
next: ci + verify green, verifier review, retire, PR
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

Size, `./joharness.sh context`, 2026-10-10: instructions 17730 bytes /
2490 words at merge base -> 16860 bytes / 2378 words on this branch
(harness file 2080 -> 1968 words).

## Rejected

## Review

Ledger, one row per removed block (plan Scope). A table, not bullets: the
bullets below are findings (`- r<N>:`), which `feedback` attributes to files.

| Removed | Where it lives |
| --- | --- |
| harness env paragraph ("Environment rules are not here ...") | duplicate of AGENTS.md:5-9 (root Part 1, ships to consumers). |
| step 4 "Six merged edges paid for this one" | duplicate of .agents/docs/feedback.md:148 (Worked example: tree or diff); pointer kept. |
| step 4 "another PR merging mid-build is cheap to catch now ..." | duplicate of .agents/docs/product/README.md:164-166 (Branch flow, Long-running session); pointer kept. |
| step 5 CI-runnable clause | cut to a pointer at step 7; kept whole in step 7 and root Part 2 (AGENTS.md:44-46). |
| step 7 "(ratified 2026-08-23)" | duplicate of .agents/docs/product/README.md:126 (Branch flow, Finish). |
| step 7 "squash/rebase merge breaks the merged-branch ancestry filter" | duplicate of .agents/docs/product/README.md:133-135 (Branch flow); pointer kept. |
| step 7 "Skipped, the base branch accretes finished workstreams ..." | duplicate of .agents/docs/handover/README.md:508,526 (Graduation); pointer kept, heading named. |
| harness Handover "One file per workstream under docs/handover/, lives on work branch" | duplicate of AGENTS.md:13. |
| harness Handover "Same commit as code. Push early ..." | duplicate of AGENTS.md:18-19 and harness step 6. |
| harness Handover "Push time not liveness. Wrong both directions. /who = truth." | duplicate of AGENTS.md:20. |
| harness Handover "Diff self-describing." | duplicate of harness step 2 (copy or sync task sentence). |
| harness Handover "Full protocol + why: handover/README.md" | duplicate of AGENTS.md:13-14 ("Protocol: ..."). |

Left in place, cites no allowed doc: step 2 "oldest edge branch is the one closest to abandoned" (none); step 5 bash-guard incidents and Stop guard why (`.agents/harness/pretool-bash-guard.sh`); step 7 "Why two strengths" (`joharness.sh:fin_strength`); step 7 "merge on their clock ... follow-up pull request to undo" (none); step 7 "every other guard fires after the merge" (none); step 2 curate and step 7 heartbeat text (mode text, out of scope; orchestrated.md / curate.md).

## Blockers

None.

## Where to look

- `docs/plans/agents-chain-dedupe.md` — scope, acceptance.
