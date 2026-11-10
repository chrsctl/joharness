---
plan: block-draft-guard
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
serves: all
issue: none
scope: .agents/harness/handover-guard.sh, .agents/harness/selftest/handover-guard.sh, .claude/commands/manager.md, .agents/docs/manager-reference.md, .agents/docs/handover.md
---

## Goal

A manager blocked a retired head without drafting its open pull request
(chrsctl/gx PR #1437, retire `746dbd759`, restore `2c3e4b6ce`, haiku tier);
a human merged it and `docs/handover/mcp-server-docstring-escape.md` landed
on `main`. manager-reference.md § Block on an open pull request is prose only.
Add the cheapest mechanical catch git can see, in the session that skips it,
and make manager.md name it.

## Scope

- `.agents/harness/handover-guard.sh` — new fact: a `docs/handover/*.md` at
  HEAD with `status: blocked` that this branch deleted earlier (retire, then
  restore) and whose frontmatter has no `drafted: <N>` (digits, `#` optional)
  blocks the stop once, naming § Block on an open pull request.
- `.agents/harness/selftest/handover-guard.sh` — cases: fires on
  retire+restore+blocked without `drafted:`; silent with `drafted: #N`;
  silent on blocked without a retire; silent on `drafted: none`? no — fires.
- `.claude/commands/manager.md` §3 — the block line names `drafted:` and the guard.
- `.agents/docs/manager-reference.md` § Block on an open pull request — write
  `drafted: <N>` after the read-back; the guard checks it.
- `.agents/docs/handover.md` — the field, one line.

## Assumptions

- A1: The PR opens only after the retire commit deletes the workstream file,
  so "deleted on this branch, present at HEAD" means a PR exists — evidence:
  `.claude/commands/manager.md` §4 / Loop step 7 — confidence: high
- A2: The Stop hook runs in every manager session and fires when the branch is
  ahead of `origin/main` even with a clean pushed tree — evidence:
  `.agents/harness/handover-guard.sh` early-exit condition — confidence: high
- A3: No reader parses a `drafted:` key, so a new key breaks nothing —
  evidence: `grep -rn drafted joharness.sh .agents/harness` — confidence: high

## Out of scope

- Calling the GitHub API from the guard (harness commands never do).
- `ci`/`finish` refusing a head that adds a workstream file: a human merging
  red ignores it; not this plan.
- Un-draft on resume: stays prose.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`, including the new handover-guard cases.
- The new fire case FAILS with the guard change reverted.

## Where to look

- `.agents/harness/handover-guard.sh:add_fact` — where facts join the reason.
- `.agents/docs/manager-reference.md:Block on an open pull request` — the rule.

## Traps

- Guard output embeds in JSON unescaped: fixed words and digits only, no path.
- Never a nonzero exit from the guard.
