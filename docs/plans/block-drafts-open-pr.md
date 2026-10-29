---
plan: block-drafts-open-pr
urgency: urgent
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/commands/manager.md
---

## Goal

A block or park on a head with an open pull request leaves it mergeable by
hand, and the merge lands a stale workstream file on `main` (PR #693 here,
PRs #1090 and #1092 in chrsctl/gx). `.agents/docs/manager-reference.md` §
Block on an open pull request now says to draft it; `manager.md` must point
there so a manager reads it when it blocks.

## Scope

- `.claude/commands/manager.md` — §3 (the block bullet) and §4 (Finish): one
  `ref § Block on an open pull request` line each — on any block with a pull
  request open, and at step 7 on a resumed head whose pull request is a draft.

## Assumptions

- A1: `manager.md` has no draft step today — evidence: `grep -n draft
  .claude/commands/manager.md` prints nothing — confidence: high
- A2: the GitHub MCP `update_pull_request` takes `draft` — evidence: its
  schema lists `draft: boolean` — confidence: high

## Out of scope

- Any `joharness.sh` change (`finish` refusing a blocked head): a separate
  plan if wanted; it cannot stop the merge button.
- Rewording the reference section itself.

## Acceptance

- `grep -c 'ref § Block on an open pull request' .claude/commands/manager.md` — `2`
- `./joharness.sh ci` — `ci: pass`

## Where to look

- `.agents/docs/manager-reference.md:## Block on an open pull request` — the rule.
- `.claude/commands/manager.md:## 3. The contract with the orchestrator` — where a block is named.

## Traps

- `manager.md` is protocol text, not a core path: edit on the work branch.
