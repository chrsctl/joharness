---
plan: surveyor-name
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .claude/commands/manage.md, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/docs/plans/README.md, .agents/harness/selftest/dispatch.sh, shared:.agents/docs/glossary.md
---

## Goal

Every role in the orchestrated lineup is an agent noun carrying one line of
its own job: orchestrator, manager, worker, reporter, curator. The
`OVERLAP-BOUND` repair is called "rescope manager" — a task wearing the
manager's title. It has no name, so it has no job description either, and a
reader meets it as a manager doing something rather than as a role with its
own bounds. Name it `surveyor` and give the name its job.

## Scope

- `joharness.sh` — the four `dispatch` comments and two `printf` verdict
  strings that say "rescope manager". Prose only; `dispatch_rescope_branches`
  and every `rescope-<key>` identity stay byte-exact.
- `.claude/commands/manage.md` — section R gains the one-line job
  description and names the role. The `rescope <key>` kind in section 0
  keeps its spelling: that is the argument the orchestrator passes.
- `.claude/commands/orchestrate.md` — the `OVERLAP-BOUND` spawn rule, the
  never-do line, and the spawn `title`, which becomes `surveyor: <key>`.
  Every other spawn title already names the role — `manager: <stem>`,
  `curator: <UTC date>`, `reporter: <stem>`, `orchestrator: <owner/repo>` —
  and no code reads a title: the orchestrator looks sessions up by
  `manager: <stem>` only. `prompt` = `/manage rescope <key>` stays exactly
  as it is.
- `.agents/docs/orchestrated.md` — Roles row, "What each role reads" row, the
  Concurrency paragraph, the closing line.
- `.agents/docs/plans/README.md` — the one sentence naming the repair.
- `.agents/harness/selftest/dispatch.sh` — the `expect`/`refute` strings that
  pin the reworded verdict, and the comments around them.
- `.agents/docs/glossary.md` — one row: canonical `surveyor`, banned
  `rescope manager`. Marked `shared:` above because a renaming plan appends
  a row here and a reconcile is routine.

## Out of scope

- Renaming any identifier: `workstream: rescope-<key>`, `plan: none`,
  `rescoped=<key>`, `rescope-<key>@new`, `claude/rescope-<key>`,
  `/manage rescope <key>`, `dispatch_rescope_branches`, the `rescope :`
  block header. `rescope` is the PASS and stays the pass; `surveyor` is the
  worker who runs it. Touching them costs the scan, the ledger grammar and
  every selftest fixture for no reader.
- A `.claude/commands/rescope.md`. The role is manager-shaped — claim,
  branch, one pull request, the stall contract — so its own file would copy
  sections 0, 1 and 3 of `manage.md`. Settled with the requester.
- Any change to what the role DOES. This plan renames and describes; the
  rules in section R are correct and stay byte-for-byte.
- Rewriting the `Not this` cells of existing glossary rows.

## Acceptance

- `git grep -Fni "rescope manager" -- . ':!docs/'` — one hit, the glossary's
  own `Not this` cell (exempt by path, `joharness.sh:GLOSSARY_EXEMPT_RE`).
- `git grep -c "rescope-" joharness.sh .agents/harness/selftest/dispatch.sh`
  — unchanged from the base commit. The identities did not move.
- `./joharness.sh ci` — `ci: pass`. Covers the glossary lint, which reds on
  any surviving `rescope manager` in scope.
- `.agents/harness/selftest/dispatch.sh` — `0 failed`. This is the check a
  consumer runs too: the diff reaches every consumer at its next sync, and
  the verdict strings it pins ship with `joharness.sh`.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — the identity scan. Read it to
  see which strings are mechanism and must not move.
- `.claude/commands/manage.md:## R.` — the role's instructions.
- `.agents/docs/orchestrated.md` — Roles, and "What each role reads".
- `.agents/harness/selftest/dispatch.sh:879` — the overlap-bound fixture.

## Traps

- Glossary bans are LITERAL, case-blind SUBSTRINGS over `GLOSSARY_PATHS`.
  `rescope manager` as a ban hits nothing else; do not shorten it to
  `rescope`, which would ban every identity this plan keeps.
- `docs/` is out of glossary scope on purpose — the plan and workstream files
  may quote the losing spelling, the scanned files may not.
- The diff touches `joharness.sh`, `.agents/harness/` and `.claude/commands/`
  — protocol paths. Supervised only; an unattended session cannot commit it
  (`.agents/docs/unsupervised.md`).
- Verify with counted numbers, not written ones: run the selftest, read its
  own total.
