---
workstream: name-no-consumer
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Reword the fifteen mentions, add the rule to consumer-repos.md, review, retire, open the pull request
---

## Goal

Requester's rule, 2026-09-16: internal development and review stay separate
from the harness. Fifteen places name a specific consumer repository, and
most of the files carrying them ship to every consumer, so one operator's
internal work travels into all of them. `#250` cleared the three files it
was already editing; this clears the rest and writes the rule down so it
does not recur.

## Decisions

- No plan file. The work is a rename sweep with a self-describing diff and
  no design content, the same carve-out the protocol gives copy and sync
  tasks (`.agents/docs/handover/README.md`, "When NOT to write one"). The
  rule it lands is one paragraph, not a feature.
- Identity out, measurement in. Every citation keeps its command, its
  commit, its counts and its date; only the repository name goes. A number
  stops being re-countable by a stranger either way — they never had that
  repo — and stays re-countable by whoever does.
- The rule goes in `.agents/docs/consumer-repos.md`, which owns the
  canonical-to-consumer boundary and already carries the neighbouring rule
  about not pointing at a conf comment a consumer may not have.
- No `ci` gate proposed here. A check listing consumer names would be the
  leak it prevents, and a looser `owner/repo` pattern check is a design
  question for the human, recorded in the rule's own text as the open
  option rather than built on this branch.

## Rejected

- Rewriting history to remove the name from merged commits. Out of scope, it
  is not what was asked, and a force-push over shared history is forbidden
  by the branch-flow rules whatever the motive.

## Review

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` `DIRS`/`FILES` — which of the eight
  files reach a consumer and which stay canonical-only.
