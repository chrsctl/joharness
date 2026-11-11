---
workstream: retired-respawn-prompt
status: in-progress
branch: manager/retired-respawn-prompt
pr: none
plan: retired-respawn-prompt
issue: none
session: https://claude.ai/code/session_01J1YMK3ESUPtSD86bcqYoBC
agent: sonnet
updated: 2026-11-11
next: ci, verify, then retire commit and PR.
---

## Goal

Give a retired branch's respawn a prompt and a manager rule it can follow (plan retired-respawn-prompt).

## Decisions

- A1: confirmed — Loop step 7 deletes the workstream file before the PR opens.
- A2: confirmed — only the `gone` edge row lands on a file-less branch.
- A3: confirmed — Loop step 7 says the PR body carries the recover command.
- Orchestrator byte bound: moved "`suspect a stopped fleet` decides nothing" into orchestrator-reference.md.

## Review

- r1: "never restart the plan" dropped from the gone row (verifier) (fixed: restored; bytes saved by shortening the UNCLAIMED row, detail lives in ref § Unclaimed spawn rows)
- r2: RESPAWN paragraph ambiguous, prompt text off the plan's (verifier) (fixed: "Edge row, instead:" with the plan's exact prompt)
- r3: fallback recover command could hit another stem's deletion (verifier) (fixed: path scoped to docs/handover/<stem>.md)
- r4: moved "suspect a stopped fleet" line misplaced, carried history text (verifier) (fixed: now in ref § Control plane fields, history text dropped)
- r5: unrelated @new sentence edit (verifier) (fixed: reverted)
- r6: manager.md clause one unwrapped line (verifier) (wontfix: style only, within bound)

## Blockers

None.

## Where to look

- docs/plans/retired-respawn-prompt.md
