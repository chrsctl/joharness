---
plan: orchestrate-diet-guards
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: shared:.agents/harness/selftest/reading-budget.sh, shared:.agents/harness/selftest/orchestrated.sh, .claude/commands/keeper.md, .claude/commands/scout.md, .agents/docs/orchestrated.md
---

## Goal

The owner asked (session 2026-10-23) to improve on the role-file-diet
merge (PR #551). That split `.claude/commands/orchestrate.md` (41,573 to
21,438 bytes) into a reference file
`.agents/docs/orchestrate-reference.md`. Three gaps remain. Nothing keeps
`orchestrate.md` from growing back. Many moved rules carry no selftest pin,
so a silent edit in a file read only on demand goes unseen. Citations in
other docs still name moved text and land one hop away, on a pointer. Close
all three without changing any rule.

## Scope

- `.agents/harness/selftest/reading-budget.sh` — bound
  `.claude/commands/orchestrate.md` the way `rb_bound` bounds the two docs:
  counted size 21,480 (`wc -c` on `origin/main` after PR #551; re-count
  before writing and use that number), bound = counted plus a tenth. The
  helper reads under `.agents/docs` only, so generalise the path, or add a
  second helper for `.claude/commands`; either way, one case per file.
- `.agents/harness/selftest/orchestrated.sh` — pin each of these moved
  rules in `ref § <name>` text (`$reffold`). None has a pin today:
  - HELD BY HUMAN: `ledger \`held-human=<pr>\``.
  - The UNRATIFIED BLOCK nudge text.
  - The STILLBORN row.
  - The `held=<updated_at>` row.
  - Core wait: `corewait=<stem>[,<stem>]`, and the drop rule.
  - The LOOP record: `Looped, killed by the orchestrator`.
  - GUARD's `--force-with-lease=refs/heads/<branch>:<sha>`.
  - "A scout issue needs the scout" with its (i), (ii) and (iii).

  Every needle must be grep-checked against the file before commit, as the
  file's own comment requires.
- `.claude/commands/keeper.md`, `.claude/commands/scout.md`,
  `.agents/docs/orchestrated.md` — each citation of moved text names the
  reference section directly, for example "(`orchestrate-reference.md`,
  "A scout issue needs the scout")". Find them with
  `grep -n "orchestrate.md" <file>`, and check each against the pointer
  list in `orchestrate.md` (`grep -n "ref §" .claude/commands/orchestrate.md`).
  A citation of text that stayed in `orchestrate.md` stays as it is.

## Out of scope

- `.claude/commands/orchestrate.md` and
  `.agents/docs/orchestrate-reference.md`: no rule moves and no word
  changes. If a citation fix seems to need one, the citation is wrong.
- `.claude/commands/manage.md`: plan `manage-file-diet`.
- The `harness=` hash rule (Pass entry).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Raise `orchestrate.md` past its bound on a scratch copy: the new
  reading-budget case FAILS. Restore it: the case passes. Record both
  results in `## Review`.
- Delete one pinned sentence from a scratch copy of the reference: its new
  pin FAILS.
- `grep -n "orchestrate.md" .claude/commands/keeper.md
  .claude/commands/scout.md .agents/docs/orchestrated.md`: every remaining
  hit cites text that `orchestrate.md` still holds. List each in
  `## Review`.
- Every selftest pin still passes, none removed. A pinned sentence whose
  citation changed gets its needle updated, never dropped.
- Plan `ci` calls SHIPS.

## Where to look

- `.agents/harness/selftest/reading-budget.sh:rb_bound` — the bound
  pattern.
- `.agents/harness/selftest/orchestrated.sh:reffold` — the reference
  pins and the both-ways pointer check.
- `.agents/docs/orchestrate-reference.md` — the moved text.

## Traps

- NEVER skip, disable or quarantine a test.
- Docs state status quo: no history in the citation edits.
- No core paths.
- Plan `manage-file-diet` also edits `orchestrated.sh` and `reading-budget.sh` (both
  `shared:`): expect a reconcile at step 7, and keep both plans' cases.
