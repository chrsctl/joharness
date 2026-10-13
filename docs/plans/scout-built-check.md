---
plan: scout-built-check
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 454
scope: shared:.claude/commands/scout.md, shared:joharness.sh, shared:.agents/harness/selftest/scout.sh
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

- `.claude/commands/scout.md` §2 — add to the inside reads, as records not code: `git log --first-parent --format=%s origin/<base>` (retired plan and merge subjects; on a shallow clone, `git fetch --unshallow origin` first, bounded, or the line says the history ends at the boundary and a "no hit" covers only that window); `docs/plans/RETIRED.md`; and the names and `## Goal` of `docs/research/*.md` and, where present, `docs/findings/*.md`. Named paths only — never "anything under `docs/`": a plan's body beyond frontmatter and `## Goal` stays forbidden. Each read is one `## Decisions` line as now.
- `.claude/commands/scout.md` §6 — `## Memory` gains a required line per proposal: the dedupe commands run and their result (`<command> → no hit` or the hit), before the issue is filed. A hit = no proposal, or a proposal that says what the hit lacks.
- `.claude/commands/scout.md` "What you read" — the summary sentence names the new records so it matches §2.
- `joharness.sh` — `cmd_scout`'s "evidence a scout reads" list names the same new records, so the command and §2 agree.
- `.agents/harness/selftest/scout.sh` — assert the list names `RETIRED.md` and the `first-parent` log.

## Out of scope

- Allowing product-code reads, or a code-search tool.
- The budget and cost lines — issue #461 (scout simplification) decides them.
- `joharness.sh` beyond `cmd_scout`'s "evidence a scout reads" list.

## Acceptance

- `grep -n 'first-parent' .claude/commands/scout.md` — at least one hit, in §2.
- `grep -n 'no hit' .claude/commands/scout.md` — at least one hit, in §6's `## Memory` bullet.
- `grep -c 'product code' .claude/commands/scout.md` — at least `1` (the prohibition stays).
- `./joharness.sh scout` — the evidence list names `RETIRED.md` and the first-parent log.
- `bash .agents/harness/selftest.sh` — the new `scout` assertion prints PASS; with the `cmd_scout` list reverted it prints FAIL.
- `./joharness.sh ci` — `ci: pass`.
- Plan ships (scout.md syncs): consumer check = the consumer's synced `.claude/commands/scout.md` carries the §2 records line (`grep first-parent`).

## Where to look

- `.claude/commands/scout.md` — "What you read", "## 2. Read, inside", "## 6." body sections (`## Memory`).
- `joharness.sh:cmd_scout` — the "evidence a scout reads" list.
- `docs/plans/RETIRED.md` — the retired-plan ledger.
- `.claude/commands/clerk.md` — §3's rule for read-only commands the scout's new reads must stay within.

## Traps

- Never widen the rule to product code: the issue proposes records, not code.
- Test for a fix must FAIL without it; run selftests through `.agents/harness/selftest.sh`, never a topic file alone.
- `scout.md` and `joharness.sh` are `shared:`: merge `origin/main` in before the pull request.
- Glossary spellings: `ci` fails a contested term spelled another way.
