---
plan: short-kebab-name
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: none
---

<!--
Copy to docs/plans/<plan>.md. Rules: .agents/docs/plans/README.md (Shape).
Write for a literal reader: scope and out-of-scope explicit, acceptance =
runnable commands with expected output.
needs: plan names whose RESULT this plan reads, or a requirement no plan
  builds yet; else none. Never a gate in prose: dispatch cannot read it.
requirement: the one this plan serves; its last plan's PR deletes it.
serves: which of its `## Satisfied when` clauses this plan builds, numbered
  by position (`1, 3`), or `all`. No line = all. Fewer than all leaves the
  requirement PARTLY PLANNED: offered for planning until every clause has a
  plan.
issue: GitHub issue a clerk turned into this plan; manager's PR says Closes #N
  (Refs #N when another plan names it or `## Issue remainder` exists).
scope: comma-separated path prefixes; prefix `shared:` for routine reconcile;
  also read by ship-scope.
-->

## Goal

Why this work exists, requester's terms. One paragraph.

## Scope

- `path/new_file.py` — what goes in it.
- `path/existing.py` — what changes.

## Assumptions

- A1: <claim> — evidence: <path:symbol or command> — confidence: high|medium|low
<!-- One bullet each. Plan rests on none? One line saying so. -->

## Out of scope

- Thing a helpful agent would add. Reason it stays out.

## Acceptance

- `command` — expected output, exact.
- Project suite — all green.
- Plan `ci` calls SHIPS: one check a consumer runs, not only a local one.

## Escape

<!-- Optional; required in a plan made from a `defect:` issue. Delete otherwise.
Entry, Gate, Route: answer in the PR body (plans README, Shape). -->

## Where to look

- `path/to/file.py:symbol` — why this spot matters.

## Traps

- Relevant prohibition, restated. (AGENTS.md Part 2 has reasoning.)
