---
name: steward
description: Rules for driving this repo's pull requests to merge — read before acting on CI or review events
---

Harness finish rules, restated for the session driving a pull request.
Same rules as `harness/AGENTS.md` Loop steps 5-7 — that file wins on any
conflict. Why-explanations: `docs/handover/README.md`,
`docs/product/README.md` Branch flow.

## Before every push

- `./joharness.sh ci` = `ci: pass`. It runs exactly what GitHub CI runs;
  red after green here = bug in the split, report it.
- Update this branch's `docs/handover/<workstream>.md` in SAME commit as
  the change.
- One validated push beats three speculative ones.

## Review rounds

- Fix findings or record why not in the workstream file — never drop
  silent.
- Fix undoes an earlier round's fix = review churn. Stop patching.
  Research step at raised tier or effort first
  (`docs/agent-selection.md`, review churn rule). `ci` measures it:
  warning from threshold, hard stop from ceiling.

## Merge conflict with base

- Merge base branch INTO this branch. Never rebase, amend, or
  force-push a shared branch — history rewrite breaks other sessions'
  checkouts.
- Conflict does not resolve clean (semantic, unclear intent): stop,
  record in workstream file `Blockers`, ask human. Never force through.

## At merge

- Session merges its OWN pull request itself (ratified 2026-08-23).
  Conditions, merge method, and what counts as own: `harness/AGENTS.md`
  step 7 — that file wins, one copy on purpose. Never merge any other
  PR.
- Merged branch left standing = cosmetic, ignore — hook filters merged
  branches from claims view. Deleting = optional hygiene, human-only
  (`docs/product/README.md` Branch flow). Session NEVER
  `git push --delete`.
- PR's final state deletes: the plan file this branch implements, the
  requirement file when this was its last plan, the workstream file.
  Six-month-worthy learnings move to the right layer's `AGENTS.md` or
  `docs/` first.

## Never

- Skip, disable, or quarantine a test to get green.
- Push an empty commit or close-reopen the PR to kick CI.
- Downgrade the plan's agent tier or effort to save cost — money =
  human's call.
