---
workstream: caveman-self-contained-notice
status: in-progress
branch: claude/licensing-matches-verify-qtamqe
pr: none
plan: caveman-self-contained-notice
issue: none
session: https://claude.ai/code/session_01BgxrYUJru5VR12hRuPxkdV
agent: haiku
updated: 2026-09-04
next: Embed the MIT text in caveman.md, extend the selftest, run ci and verify
---

## Goal

Human asked: "Can we Attribute correctly". Make `.agents/docs/caveman.md`
carry the complete MIT notice of its upstream, copyright line and permission
text, so the attribution holds for a copy of the file made on its own.

## Decisions

- Full MIT text in the file, not a pointer: MIT names "this permission
  notice" as part of what every copy includes, and a pointer to a sibling
  file does not survive copying the file alone. #206 flagged exactly this.
- Placed at the end under its own heading, so the rules stay first for the
  reader and the notice is not mistaken for a style rule.

## Rejected

- HTML comment block for the notice. Invisible in rendered views, and a
  notice that hides is not a notice.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/docs/caveman.md` — last section.
