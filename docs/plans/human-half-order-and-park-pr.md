---
plan: human-half-order-and-park-pr
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 597
scope: shared:.claude/commands/manage.md, .agents/docs/manage-reference.md
---

## Goal

Two gaps from issue #597. (1) A `human/<stem>` pull request that renames or
moves a path the tree still uses can merge before its code half and turn
`origin/main` red for every manager. (2) `manage-reference.md` § Defect parks
a finished item with no pull request when the only red reproduces on the
base, leaving no artifact on GitHub.

## Scope

- `.claude/commands/manage.md` §2 — a `human/<stem>` PR that moves or renames a path the tree still uses says in its body that it merges with or after its code half, naming that branch.
- `.agents/docs/manage-reference.md` § Defect — step 2, "Yes, and step 2 found M": when the item is otherwise done (verify green apart from the base red), open the pull request anyway, retire commit included, body naming the base red and issue M; then park.

## Assumptions

- A1: § Defect step 2 parks with no PR — evidence: `sed -n 126,142p .agents/docs/manage-reference.md` — confidence: high
- A2: §2 names no merge-order rule — evidence: `grep -n "human/<stem>" .claude/commands/manage.md` — confidence: high
- A3: opening the PR before the park does not break `finish`, which refuses a red base — evidence: `joharness.sh:cmd_finish` — confidence: low

## Out of scope

- Code that enforces merge order; wording only.
- Changing `defect-resume` or dispatch rows.
- Merging a PR parked on the base red: `finish` still refuses.

## Acceptance

- `./joharness.sh ci` — pass.
- `grep -n "merges with or after" .claude/commands/manage.md` — 1 line.
- `grep -n "open the pull request" .agents/docs/manage-reference.md` — in § Defect.

## Where to look

- `.agents/docs/manage-reference.md` § Defect, `.claude/commands/manage.md` §2.

## Traps

- Docs state status quo: no incident, date or past in the text.
- A3 low: confirm `finish` behaviour before writing the rule; if it conflicts, record in `## Decisions`.
