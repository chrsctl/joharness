---
workstream: reserve-numbered-artefact
status: in-progress
branch: reserve-numbered-artefact
pr: none
plan: reserve-numbered-artefact
issue: none
session: https://claude.ai/code/session_01J1YMK3abvPj4cWij9VHP6o
agent: sonnet
updated: 2026-11-12
next: ci green; open PR, merge, retire workstream and plan files
---

## Goal

Plan reserve-numbered-artefact: plan writer reserves a numbered artefact's number at plan time.

## Decisions

- A1: confirmed — grep for reserve|reservation in the three files printed nothing (checked on origin/main).

## Review

- r1: (verifier) Numbered artefacts subsection sat above the core-path paragraph, which belongs to the shared: section (fixed: moved before A human remainder)
- r2: (verifier) clerk.md Never line ragged wrap (no change: style only, wording matches plan)
- r3: (verifier) manager.md carve-out wording terse (wontfix: manager.md is at its ci byte bound; PR body notes it)

## Blockers

None.

## Where to look

- `.agents/docs/plans.md:shared:` — registry paragraphs.
