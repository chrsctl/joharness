---
workstream: scorecard-counterweights
status: review
branch: claude/scorecard-counterweights
pr: none
plan: scorecard-counterweights
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Merge once green
---

## Goal

Closes the two gaps `scorecard-without-gaming` found and `process-scorecard`
shipped without: a count wants a counterweight, and no count is retired.

## Decisions

- The counterweight for "findings recorded" is UNMARKED findings, not fixed
  ones. What noise avoids is deciding — a finding with no disposition costs
  nothing to write — so unmarked is the quantity that moves with the gaming.
  Fixed-vs-total would instead reward marking, which is the cheaper act.
- Pairing prints at zero too. A parenthetical that appears only when something
  is wrong is one a reader learns to skip, and then it is absent on the day it
  matters.
- Retirement is prose beside the counts, not a frontmatter field. The judgment
  is "can this still surprise anyone", and a field invites a gate — which is
  the pressure the pairing exists to withstand.
- Reused `fb_findings` and `fb_marker` rather than parsing dispositions again.
  This file has already paid for spelling one rule twice.

## Rejected

- Pairing every count. Checked each: `commits` and `paths touched` already
  constrain each other by construction, the no-workstream-file count is a
  violation nobody inflates upward, and `plan files retired` is judged by
  `finish` and `cleanup` rather than here. Only `findings recorded` has the
  shape the research names.
- Any gate. `scorecard` reports; a gate would create the target.

## Review

opus, adversarial.

- r1: verified the existing assertions still hold with text appended to the
  findings line — `expect` is a substring match, so `"review findings recorded
  5"` still matches as a prefix. Checked rather than assumed, because a
  formatting change that quietly breaks a neighbouring case is how a suite
  starts getting edited to fit the code. (no action)
- r2: both new behaviours proved red when reverted — dropping the pairing reds
  two cases, dropping the retirement prose reds one. (no action)
- r3: the fully-marked case exists because the zero path is the one most
  likely to be dropped by a later "tidy up" edit, and its absence is invisible
  in normal use. (no action)
- r4: `local line` added inside `cmd_scorecard` rather than reusing an outer
  name — the function already declares its locals in one place, and a loop
  variable leaking into a later block is the kind of bug this file has fixed
  before. (no action)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_scorecard` — the pairing and the retirement prose.
- `.agents/docs/agent-selection.md` — the reasoning the output points at.
