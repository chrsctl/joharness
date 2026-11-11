---
workstream: rescope-human-answers-on-github
status: done
branch: rescope-human-answers-on-github
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01J1YMK2w7gTovJxWnFLkzcr
agent: sonnet
updated: 2026-11-11
next: none — the overlap on orchestrated.md and orchestrator-reference.md is real; the 3 held plans wait for human-answers-on-github to merge
---

## Goal

Surveyor for `rescope human-answers-on-github`: retired-edge-stall-window,
stranded-branch-plans (both on `orchestrated.md`) and heartbeat-read-cheaper
(on `orchestrator-reference.md`) held behind human-answers-on-github.

## Decisions

- The holder REWRITES existing paragraphs of `orchestrated.md` (Bounds, scout
  paragraph) and `orchestrator-reference.md` (§ Relay, § Held by human, "A new
  issue needs the clerk", scout trigger) IN PLACE; it registers in no index
  and claims no directory. The held plans already carry `shared:` where they
  append (stranded's table row, knob rows) or edit in place
  (heartbeat's `orchestrator-reference.md`). manager-reference § Surveyor:
  in-place edits stay, so nothing is marked. The hold is GENUINE. No pull
  request.
- Marking the holder `shared:` would claim its paragraph rewrites merge
  line-independently with edits to the same prose docs; the Scope shows
  neither is a registry append, so no.

## Review

- r1: clean pass, no scope: line changed (no change)

## Blockers

None.

## Where to look

- `docs/plans/human-answers-on-github.md` — holder `## Scope`.
