---
plan: scout-built-check
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 454
scope: shared:.claude/commands/scout.md
---

## Goal

A scout may not read product code (`.claude/commands/scout.md`, "What you
read"), yet every outside finding raises "does this repository already
have it?". Issue #454 measured a consumer pass: 4 of 4 deltas could not be
settled from the allowed reads, so the scout grepped product code (breaking
the rule); 3 of 4 were settled by `git log` subjects naming retired plans;
the one filed proposal was wrong because a findings document and a phase
spec, both outside the allowed list, already named the feature.

Decided by the clerk: product code stays forbidden. The repository's own
RECORDS of what is built join §2's allowed reads, and §6's `## Memory`
must say how "not already built" was established, so the reviewer sees the
check and its gap.

## Scope

- `.claude/commands/scout.md` §2 — add to the inside reads: `git log --first-parent --format=%s origin/<base>` (retired plan and merge subjects), and, where present on the base branch, `docs/research/`, `docs/findings/` and phase specs under `docs/` (records, not code). Each read is one `## Decisions` line as now.
- `.claude/commands/scout.md` §6 — `## Memory` gains a required line per proposal: the dedupe commands run and their result (`<command> → no hit` or the hit), before the issue is filed. A hit = no proposal, or a proposal that says what the hit lacks.
- `.claude/commands/scout.md` "What you read" — the summary sentence names the new records so it matches §2.

## Out of scope

- Allowing product-code reads, or a code-search tool.
- The budget and cost lines — plan `scout-budget-reads-the-pass` owns them.
- `joharness.sh` changes: nothing here is printed by a command.

## Acceptance

- `grep -n 'first-parent' .claude/commands/scout.md` — at least one hit, in §2.
- `grep -n 'no hit' .claude/commands/scout.md` — at least one hit, in §6's `## Memory` bullet.
- `grep -n 'not product code' .claude/commands/scout.md` — still present (the prohibition stays).
- `./joharness.sh ci` — `ci: pass`.
- Plan ships (scout.md syncs): consumer check = the consumer's synced `.claude/commands/scout.md` carries the §2 records line (`grep first-parent`).

## Where to look

- `.claude/commands/scout.md` — "What you read", "## 2. Read, inside", "## 6." body sections (`## Memory`).
- `.claude/commands/clerk.md` — §3's rule for read-only commands the scout's new reads must stay within.

## Traps

- Never widen the rule to product code: the issue proposes records, not code.
- `scout.md` is `shared:`: merge `origin/main` in before the pull request.
- Glossary spellings: `ci` fails a contested term spelled another way.
