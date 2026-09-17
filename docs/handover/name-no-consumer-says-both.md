---
workstream: name-no-consumer-says-both
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: name-no-consumer-says-both
issue: 273
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Write the plan, verify, then retire this file and open the pull request
---

## Goal

Issue #273, the oldest open issue with no queue item decomposing it.
`.agents/docs/consumer-repos.md`, `## Name no consumer`, answers one question
twice and differently, seven lines apart: `:207-209` says a consumer's pull
request numbers ARE covered by the naming rule, `:214-216` says they are NOT.

Step 2: nothing builds unplanned, and decompose IS the work. So this
session's item is the plan, not the fix.

## Decisions

- **Decompose rather than fix.** The Loop is explicit — an issue becomes a
  plan first. Small ask, small plan, still a plan.
- **The plan proposes an answer rather than parking on the human.** #273 says
  "which answer is right is the rule-owner's call", and that is still true of
  the FINAL word — but a plan that names no direction is a plan nobody can
  pick up. The asymmetry decides the default: treating a pull request number
  as covered costs a citation some precision; treating it as uncovered when
  it is covered ships a consumer's internal reference into every other
  consumer's copy, which is what the requester's standing rule exists to
  stop. The plan proposes COVERED, names the veto, and leaves the counting
  argument to the commit-hash exemption that already serves it.
- **`agent: sonnet`.** The judgement — which of two sentences survives — is
  made in the plan. What is left is a text edit against a named rule, with
  no measurement to take.

## Rejected

- **Writing the fix in this session as well.** One item per session, and
  the decomposition is the item. A session that decomposes and then builds
  has skipped the step where a second reader can disagree with the
  decomposition before the code exists.
- **Leaving the direction open for the implementer.** Tried in the draft: an
  acceptance that reads "one spelling survives" passes whichever sentence is
  deleted, including the one that ships internal references. An acceptance
  that cannot fail in the expensive direction is not an acceptance.

## Review

- (none yet)

## Blockers

None.

## Where to look

- `.agents/docs/consumer-repos.md`, `## Name no consumer` — both paragraphs.
- `.agents/docs/glossary.md` — why `ci` cannot gate this one: the glossary
  fixes contested TERMS, and this is a contested rule about a class of
  reference.
