---
workstream: graduate-scorecard-finding
status: in-progress
branch: claude/graduate-scorecard-finding
pr: none
plan: scorecard-without-gaming
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Graduate the Goodhart finding into .agents/docs/agent-selection.md, then retire the research file
---

## Goal

`docs/research/scorecard-without-gaming.md` is answered and verified and has
not graduated. The plan it judged, `process-scorecard`, has since merged and
retired, so the finding now describes a command that exists — which makes
graduating it more urgent, not less: the reasoning that should govern the
shipped `scorecard` lives only in a research node scheduled for deletion.

## Decisions

- Picked over `fanout-live-run`, which `drain` names first and which stays
  unclaimable: its precondition is a wave of two or more, and it is now the
  only free plan. It also wants an explicit human go-ahead.
- Edge branch NOT taken. Its session went IDLE, not gone, and it is
  review_ready with no pull request open. Step 7 gives this session its own
  pull requests and no others, so this is a flag to the human, not a merge.

## Rejected

- None yet.

## Review

opus, adversarial. Lenses: did the graduation carry the corrected attributions
intact, is it accurate about the command that now exists, and does the queued
follow-up scope cleanly.

- r1: the graduated section asserts Goodhart 1975, Strathern 1997 citing
  Hoskin, Austin, and dora.dev's siloing wording. I did NOT re-verify any of
  them from source; they are carried from the research file's independent
  verification pass, which corrected two of them and marked the DORA sentence
  UNGROUNDED. Correct per the protocol — graduation carries a finding, it does
  not re-ground it — but this branch adds no new grounding and says so.
  (wontfix)
- r2: checked that the section does not quietly restore the sentence the
  verification pass killed. It does not: "individual metrics create competition
  while team metrics create collaboration" appears nowhere, and the section
  states explicitly that DORA does not say it. That claim was the whole reason
  the research needed a second context, so re-introducing it in the graduation
  would have wasted the pass. (no action)
- r3: the section claims `scorecard` reports and never gates. Verified against
  the shipped command rather than the plan's intent — `joharness.sh` usage
  reads "Reports only, never gates". (no action)
- r4: the workstream file anchors `docs/research/scorecard-without-gaming.md`,
  which this branch deletes, and `ci` warns twice about it. Harmless — the file
  retires before the merge — but a warning a reader has to learn to ignore is
  the same failure this repo keeps paying for. Anchor moved to the graduation
  target. (fixed)
- r5: `scorecard-counterweights` could read as licence to add a gate later. Its
  Out of scope says the opposite in the plan's own words, and names why: a gate
  creates the pressure the pairing exists to survive. (no action)

## Blockers

None.

## Where to look

- `.agents/docs/agent-selection.md` — where it lands.
- `joharness.sh:cmd_scorecard` — the command the finding now governs.
