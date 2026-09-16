---
workstream: issues-to-plans
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Write the five artifacts, review, retire, open the pull request
---

## Goal

Direct human ask: convert the open issues to plans. Loop step 2 is the rule
this serves — nothing builds unplanned, an issue decomposes into a plan
before code, and the decomposition IS the work. Five issues are open: #249,
#251, #254, #258, #260. None of them is buildable as filed; each names more
than one thing, and in four of the five part of what it names is a human's
decision rather than a build.

## Decisions

- `issue: none` in the frontmatter, deliberately. The field holds one
  number and this work decomposes five; naming one would tell another
  session the other four are free. The queue this produces is the claim
  surface, not this file.
- One artifact per issue, except #258, which the issue itself splits into
  options its own text calls "close to free and mostly independent". Two
  plans there, because one plan mixing an `orchestrate.md` prose change with
  a `joharness.sh` gate is the kind a literal reader half-does.
- Two of the five become RESEARCH files, not plans. #249's remainder is a
  scheduler, and the issue says in its own words that how it is scheduled
  "is the open question, and it is the whole question". #251's remainder
  needs a judgement nobody has made. A plan for either would be a plan whose
  Acceptance cannot be written, which is the shape
  `.agents/docs/research/README.md` exists to catch.
- Nothing here decides anything the issues left to the human: the sampling
  reviewer's cost (#251), blocked-versus-gone (#254), a time bound on an
  unowned block (#254), where a consumer's findings should go (#258). Each
  is named as out of scope in the artifact that would otherwise absorb it,
  with the reason, so the next session does not quietly decide it by
  building.
- No consumer repository is named in any artifact, per the requester's
  standing rule and `.agents/docs/consumer-repos.md`, "Name no consumer".
  The measurements the issues carry are cited as measurements.

## Rejected

- One plan per issue mechanically, including for #249 and #251. Writing
  "spawn a sampling conduct reviewer" as a plan would hand an unattended
  session a cap-beating spawn the issue explicitly does not claim is worth
  its cost. The plan file is an instruction, and an instruction is acted on.
- Re-filing the four rules withdrawn from #249 (PR #253) as a plan blocked
  on `docs/research/liveness-in-a-long-turn.md`. That node already promises
  to graduate into the health pass; a blocked plan beside it would be the
  same work named twice, and the churn that withdrew those rules is exactly
  what a second name invites.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/plans/README.md` — plan shape, the `scope:` rules, and why
  a registry gets `shared:`.
- `.agents/docs/research/README.md` — the nine sections, and what makes a
  file a node rather than prose.
- `docs/plans/findings-with-the-fix.md` — already carries #251's cheap
  slice, and its Out of scope promises a question filed here.
