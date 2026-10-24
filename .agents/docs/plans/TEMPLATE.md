---
plan: short-kebab-name
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: none
---

<!--
Copy to docs/plans/<plan>.md. Queue rules: .agents/docs/plans/README.md.

Write for literal reader. Scope and out-of-scope both explicit; acceptance
= runnable commands with expected output; traps = the Part 2 prohibitions
this plan can trip, one line each.

`needs` = plan names whose RESULT this plan reads; blocked while those
files exist. Related-but-independent = fake edge, leave `none`.
`requirement` = the one this plan serves (docs/product/); hook stops
flagging it unplanned. Last plan of a requirement: its PR deletes the
requirement file too.
`issue` = the GitHub issue a clerk turned into this plan (`/clerk`); `none`
otherwise. The manager's PR closes it (`Closes #N`) when no other plan names it and
the plan has no `## Issue remainder` section (then `Refs #N`).
`scope` = comma-separated path prefixes this plan will touch (a file, a
directory, a layer). The queue hook partitions free plans into waves of
disjoint scopes — parallel proven inside a wave, the conflicting pair
named across. `none` = independence stays unprovable; the plan is listed
but joins no wave. Prefix a path `shared:` when a reconcile merge there is
routine: marked by BOTH plans, it stops splitting the wave and is named as
the cost instead (.agents/docs/plans/README.md).

`scope` is also what the ship-scope stage reads to say whether this plan's
diff reaches consumers. Incomplete scope, wrong verdict — same field, two
readers.
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
  The diff reaches every consumer at its next sync, so a bar met only here
  is met in the one repo that was never the risk.

## Escape

<!-- Optional; required in a plan made from a `defect:` issue. Delete otherwise.
Answer in the pull request body, each with its command:
Entry: which merge introduced it? Bisect, or say why not.
Gate: which check should have caught it, and why did it pass?
Route: a gate this repo owns is fixed here or in a plan this adds; a gate
canonical owns gets a `## Review` finding `rN: <canonical path> … (wontfix: canonical's file)`. -->

## Where to look

- `path/to/file.py:symbol` — why this spot matters.

## Traps

- Relevant prohibition, restated. (AGENTS.md Part 2 has reasoning.)
