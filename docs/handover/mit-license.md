---
workstream: mit-license
status: in-progress
branch: claude/mit-license-ijf0vy
pr: none
plan: mit-license
issue: none
session: https://claude.ai/code/session_014oTKfpgfCaRPHB8pThK2uV
agent: haiku
updated: 2026-09-04
next: Run ci and verify, record review, retire plan and this file, open pull request
---

## Goal

Human asked, verbatim: "at mit license". Repo carries no license file. Add MIT
so the harness a consumer copies has an explicit grant.

## Decisions

- Copyright holder `Christian Westhoff`, not `chrsctl` and not `Anthropic`.
  Human owns the repo; commits by that name and email lead its history.
- Year 2026 only. Single-year form is what a first license file takes; a range
  would claim publication years the history does not have.
- No SPDX headers in harness files. They get copied into consumer repos whose
  own license governs — a header would travel with the copy and assert the
  wrong terms there.

## Rejected

- README badge (shields.io). Adds a network fetch to a README that has none and
  says nothing the `## License` line does not.

## Review

- r1: (pending)

## Blockers

None.

## Where to look

- `LICENSE` — the grant.
- `README.md` — `## License`, last section.
