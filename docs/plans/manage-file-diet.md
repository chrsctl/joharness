---
plan: manage-file-diet
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: .claude/commands/manage.md, .agents/docs/manage-reference.md, shared:.agents/harness/selftest/orchestrated.sh, shared:.agents/harness/selftest/reading-budget.sh
---

## Goal

The owner asked (session 2026-10-23) to cut token usage, after the
role-file-diet split of `orchestrate.md` (PR #551). Every manager session
loads `.claude/commands/manage.md` whole: 16,234 bytes (`wc -c` on
`origin/main`, 2026-10-23). Managers outnumber orchestrators, so this file
costs the fleet more. By section, measured the same day:

| section | bytes |
| --- | --- |
| `## 4. Finish` | 5,429 |
| `## 0. Orient` | 3,269 |
| `## 2. Decompose` | 2,978 |
| `## 3. The contract` | 1,850 |
| `## R. Surveyor` | 1,135 |

Much of it covers kinds or branches most managers never reach: `free`,
`rescope`, the surveyor, the human remainder, a defect outside the item, a
carried plan, GitHub lost at step 7, scout labels. Cut `manage.md` to
10,000 bytes or less without changing any behaviour, by the
`orchestrate.md` method.

## Scope

- `.claude/commands/manage.md` keeps every rule a plain plan item runs:
  - orient;
  - claim;
  - decompose and the worker prompt;
  - the contract, blocking included;
  - finish's common path;
  - Never.

  Move rare branches verbatim to new `.agents/docs/manage-reference.md`,
  one `##` per branch, behind one pointer line each. Use the same `ref §
  <name>` convention, defined once at the top, read from `git show
  origin/main:`. A pointer fires on its branch's own trigger: the item
  kind, the plan's `issue:`, a failure that is not the item's. Keep
  section headings `## 0.` to `## 4.` and `## R.` in place: other files
  cite them (`grep -rn "manage.md" .claude .agents`).
- Build it with a script, as role-file-diet did. Each move is an exact
  substring of the old file, replaced by its pointer, and swapping every
  pointer back for its text rebuilds the old file byte for byte. Run that
  check before commit.
- `.agents/harness/selftest/orchestrated.sh` — every `$mgrtext` pin whose
  text moved reads the reference instead, and none is removed. Add the
  both-ways check: every section has a pointer, every pointer names a
  section, and every section holds text. Copy the reference-check block
  from `orchestrate-reference.md`'s pins.
- `.agents/harness/selftest/reading-budget.sh` — bound `manage.md` at its
  new counted size plus a tenth.

## Out of scope

- `.claude/commands/clerk.md`: a separate decision, once this one is
  measured.
- Changing any rule, threshold or step order.
- `orchestrate.md` and its reference: plan `orchestrate-diet-guards`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `wc -c .claude/commands/manage.md` — 10,000 or less.
- `cat .claude/commands/manage.md .agents/docs/manage-reference.md | wc -c`
  — within 5% of the original 16,234 bytes.
- In `## Review`, list:
  - each moved section and the pointer that reaches it;
  - the reconstruction check's result;
  - the selftest's `INFO manager reading set` line before and after.
- Every selftest pin still passes, none removed.
- Plan `ci` calls SHIPS.

## Where to look

- `.claude/commands/manage.md` sections `## 0. Orient`, `## 2.`, `## R.`,
  `## 4. Finish`.
- `.agents/docs/orchestrate-reference.md` and
  `.claude/commands/orchestrate.md` — the finished pattern: pointer lines,
  the convention line, section names.
- `.agents/harness/selftest/orchestrated.sh:reffold` — the pins to mirror.
- `.agents/harness/selftest/reading-budget.sh:rb_bound` — the bound
  pattern.

## Traps

- A rule a plain plan item needs must not move. When unsure, keep it.
- A pointer whose trigger is narrower than its rule hides the rule: check
  every drop and cleanup rule the moved text holds, not only the branch it
  starts.
- NEVER skip, disable or quarantine a test.
- Docs state status quo: move rationale verbatim, add no history.
- No core paths.
- Plan `orchestrate-diet-guards` also edits `orchestrated.sh` and `reading-budget.sh` (both
  `shared:`): expect a reconcile at step 7, and keep both plans' cases.
