---
workstream: surveyor-name
status: in-progress
branch: claude/rescope-job-description-ehcvid
pr: none
plan: docs/plans/surveyor-name.md
issue: none
session: https://claude.ai/code/session_01CH8JvqV2WAada6gNuuWwuz
agent: sonnet
updated: 2026-09-11
next: Read the ci run and the verifier's findings, record them under ## Review with the fix in the same commit
---

## Goal

Requester: "Can we give rescope a job description" — "all the others have role
names, e.g. orchestrator curator manager". Every role in the orchestrated
lineup is an agent noun with a one-line job of its own. The `OVERLAP-BOUND`
repair is not: it is called "rescope manager", a task wearing the manager's
title, so it borrows the manager's description and has none of its own. Name
it, and give the name a job description.

## Decisions

- Name is `surveyor`. `rescope` stays the PASS; the surveyor is the worker
  who runs it. So every mechanical identity is untouched — `workstream:
  rescope-<key>`, `plan: none`, `rescoped=<key>`, `/manage rescope <key>`,
  branch `claude/rescope-<key>`. Renaming those would cost
  `dispatch_rescope_branches`, the ledger grammar and 20-odd selftest
  fixtures, and buy nothing a reader needs.
- The word says the job to a literal reader, which is what a role name is
  for: a surveyor fixes the recorded boundaries so neighbours stop
  colliding, and builds nothing on the land. That is the role's two halves —
  it edits `scope:` declarations, never product code.
- Role stays a kind of `/manage`; no `.claude/commands/rescope.md`. It is
  manager-shaped — claim, branch, one pull request, the stall contract — so
  its own command file would copy sections 0, 1 and 3 of `manage.md`.
  Requester chose this over the split.
- Spawn `title` moves too: `rescope: <key>` becomes `surveyor: <key>`. Every
  other spawn title names the ROLE (`manager: <stem>`, `curator: <UTC date>`,
  `reporter: <stem>`, `orchestrator: <owner/repo>`); this was the one naming
  the pass. Safe: no code reads a title, and the orchestrator's only title
  lookup is `manager: <stem>`.
- The glossary's "the code wins" rule does not bite here. It settles two
  spellings of ONE term by counting identifiers; no identifier spells this
  ROLE at all — every `rescope` in code names the PASS or the branch. So the
  count is 0 against 0 and the rule has nothing to say.
- Glossary row bans `rescope manager`. A rename sweep's one risk is a later
  session writing the obvious description again; nothing else catches it.
  All five files touched sit inside `GLOSSARY_PATHS`.

## Rejected

- `rescoper` — the exact curate/curator, orchestrate/orchestrator pattern,
  and it keeps the noun on the verb the code already keys on. Rejected by the
  requester: the word is ugly and tells a literal reader nothing about what
  the role may not do.
- `registrar` — the role does mark shared registries, but it keeps no
  register. The word promises a duty the role does not have.
- Splitting section R into its own command file — see Decisions.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — the scan keyed on `workstream:
  rescope-<key>` + `plan: none`. Identity, not prose: untouched by this diff.
- `.claude/commands/manage.md:## R.` — the role's actual instructions, and
  where its job description goes.
- `.agents/docs/orchestrated.md` — Roles table and "What each role reads",
  one row each.
- `.agents/harness/selftest/dispatch.sh:879` — asserts the verdict strings
  this diff rewords.
