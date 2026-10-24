---
plan: human-half-order-and-park-pr
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 597
scope: .agents/docs/manage-reference.md
---

## Goal

Narrower than issue #597. A `human/<stem>` pull request that renames or moves
a path the tree still uses can merge before its code half and turn
`origin/main` red for every manager. `manage-reference.md` § Human remainder
step 2 says `merge after <your branch> lands on main` only when `ci` is red
on the human branch; a rename where `ci` passes escapes it. Widen that one
rule. The issue's second gap (open a PR when parking on a base red) is not
planned: it contradicts Loop step 5/7 (retire commit deletes the park record;
`verify` red before a PR) and needs a human decision on the Loop.

## Scope

- `.agents/docs/manage-reference.md` § Human remainder step 2 — the `merge after <your branch> lands on main` lead applies also when the core-path edit moves or renames a path the tree still uses; the body names the code half's branch. Edit that sentence, add no second rule.

## Assumptions

- A1: step 2 gates the lead on `ci` red only — evidence: `grep -n "merge after <your branch>" .agents/docs/manage-reference.md` — confidence: high
- A2: `manage.md` §2 delegates to this section — evidence: `grep -n "Human remainder" .claude/commands/manage.md` — confidence: high

## Out of scope

- Opening a PR when parking on a base red (issue #597 gap 2): conflicts with Loop; stays for a human.
- Code that enforces merge order; wording only.
- A second rule in `manage.md`.

## Acceptance

- `./joharness.sh ci` — pass.
- `grep -c "merge after <your branch>" .agents/docs/manage-reference.md` — 1, and the sentence names a rename or move.
- Consumer check: `./joharness.sh ci` in a synced consumer — pass (docs ship).

## Where to look

- `.agents/docs/manage-reference.md` § Defect, `.claude/commands/manage.md` §2.

## Traps

- Docs state status quo: no incident, date or past in the text.
- One rule, one home: widen the existing sentence.
- `block-names-awaited-pr` (issue #596) covers a code half waiting on an independent human PR; do not touch that.
