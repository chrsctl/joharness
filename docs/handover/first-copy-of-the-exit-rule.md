---
workstream: first-copy-of-the-exit-rule
status: in-progress
branch: manage/first-copy-of-the-exit-rule
pr: none
plan: first-copy-of-the-exit-rule
issue: none
session: https://claude.ai/code/session_01AscSbhH5MAQTqzMu8omcjj
agent: sonnet
updated: 2026-10-10
next: Run ci, review, retire this file and the research file, open PR, merge
---

## Goal

Settle research `first-copy-of-the-exit-rule` (#303): does orchestrate.md's description carry the DRAINED qualifier, and is it gated.

## Decisions

- Already fixed on main: description ends "with nothing in flight" (`.claude/commands/orchestrate.md:2`), pinned by `.agents/harness/selftest/orchestrated.sh:218` (9fde144a). Only the glossary dead end was unrecorded; kept as a comment at the pin.
- `.claude/commands/` is NOT a protocol path (`./joharness.sh protocol-paths` prints joharness.conf, .claude/settings.json, .github), contrary to the research file's last line.

## Rejected

- Glossary row: substring match would ban the correct sentence.

## Review

- r1: (verifier) ran grep + protocol-paths on the branch, 2026-10-10: claim holds, no defects; only note was the pin cited as :218 when the expect is at :219-220. (no change: file is retired in the next commit)

## Blockers

None.
