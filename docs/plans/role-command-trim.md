---
plan: role-command-trim
urgency: normal
agent: opus
effort: high
needs: heartbeat-is-a-precondition, clerk-role, scout-command
requirement: none
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md, shared:.agents/docs/orchestrated.md, shared:joharness.sh, .agents/harness/selftest/ci-context.sh, docs/handover/role-command-trim.md
---

## Goal

Requester, 2026-10-09, after `docs/research/token-optimization-techniques.md`:
"Is there anything to optimize also regarding the existing harness files"
— answered yes, plan approved. `.claude/commands/orchestrate.md` is 8,340
words (`wc -w`, 2026-10-09; 6,265 at
`git log --first-parent --reverse --after=2026-09-15 --format=%h origin/main -- .claude/commands/orchestrate.md | head -1`) and sits in the orchestrator's context for its whole life —
the session that re-read 1.21B cache tokens (`.agents/docs/agent-selection.md`
Cost levers). `.claude/commands/manage.md`, 1,950 words, loads into every
manager, 93% of fleet spend. Both carry why-explanations and incident
history that a role does not need to act; `.agents/harness/AGENTS.md`'s
own rule puts those under `.agents/docs/`. Move them there, keep every
instruction. Also make `./joharness.sh context` count these files, so the
next growth is seen — nothing counts them today.

## Scope

- `joharness.sh:ctx_report` — under `full` only, after the session-start
  row, a block `loaded when the role starts (<mode>):` with one row per
  role command file that exists (`.claude/commands/orchestrate.md`,
  `.claude/commands/manage.md`), same `%-32s %8s bytes %7s words` columns,
  and the merge-base delta the instructions row already prints. Reports;
  never gates. `ci`'s chain print unchanged.
- `.agents/harness/selftest/ci-context.sh` — one case: the block lists a
  role file present in a fixture, omits one absent.
- `.claude/commands/orchestrate.md` — § 2 Health pass first (4,432 words:
  `awk '/^## 2\./{p=1} /^## 3\./{p=0} p' .claude/commands/orchestrate.md | wc -w`,
  2026-10-09),
  then § 3 Spawn and § 4 Schedule: move rationale, incident narratives,
  "why" paragraphs and measured-history to `.agents/docs/orchestrated.md`
  under a heading named for the section they left. Leave one pointer line
  where a block moved only when the step still needs the reader to know
  the why exists. Keep: every imperative, every table the role fills, every
  field name, every number the role compares against.
- `.claude/commands/manage.md` — same treatment, § 4 Finish and § R
  Surveyor.
- `docs/handover/role-command-trim.md` `## Review` — a ledger, one line
  per removed block: `moved to <file>:<heading>` or
  `duplicate of <file>:<line>`. Nothing dropped without a line.

## Out of scope

- Rewording instructions that stay. Moving, not editing; a rewrite here
  is a rule change hidden in a size change.
- Splitting `manage.md` (e.g. surveyor into its own command). Changes
  routing in `joharness.sh` and `start`; separate plan if wanted.
- `.agents/harness/AGENTS.md`, root `AGENTS.md` — plan
  `agents-chain-dedupe`.
- Other command files (`curate.md`, `janitor.md`, `analyst.md`,
  `upstream-report.md`, each ~1,000-1,300 words). Loaded by rarer roles;
  count them first with the new `context` block, plan later.
- A size gate. `.agents/docs/caveman.md` "What it costs, counted": reports,
  never gates.

## Acceptance

- `./joharness.sh context` — prints `loaded when the role starts` followed
  by rows for `.claude/commands/orchestrate.md` and
  `.claude/commands/manage.md`, each with a negative delta against the
  merge base.
- `wc -w .claude/commands/orchestrate.md` — at or under 6,000. Above it
  only if the ledger names, per remaining block, why it is instruction.
  Record the before/after with this command in the workstream file.
- `wc -w .claude/commands/manage.md` — lower than the merge base; record
  before/after.
- Every anchor code and tests name still resolves — each command below
  prints at least one line:
  `grep -n '^| field | whose account | says |' .claude/commands/orchestrate.md`
  (the table `joharness.sh` calls "the field table"),
  `grep -n '^## 2\.' .claude/commands/orchestrate.md`,
  `grep -n '^## 3\.' .claude/commands/orchestrate.md`,
  `grep -n '^## 4\.' .claude/commands/orchestrate.md`,
  `grep -n -i 'surveyor' .claude/commands/manage.md`,
  `grep -n -i 'rescope' .claude/commands/manage.md`.
- Verifier (`.claude/agents/verifier.md`) reads the ledger against the
  diff: every removed line is in a destination or a cited duplicate.
  Finding tagged `(verifier)` in `## Review`.
- `./joharness.sh ci` — `ci: pass`. `./joharness.sh verify` — 0 failed
  (diff touches `joharness.sh`).
- Plan `ci` calls SHIPS: both command files and `orchestrated.md` sync to
  every consumer; `./joharness.sh ci` in a consumer checkout is the check.

## Where to look

- `joharness.sh:cmd_context`, `joharness.sh:ctx_report`,
  `joharness.sh:ctx_counts` — the counter and its row format.
- `.agents/harness/selftest/ci-context.sh` — existing context cases.
- `joharness.sh` references to section names: `grep -n
  'orchestrate.md\|manage.md' joharness.sh` (field table, step 2, step 3,
  step 4, surveyor, rescope). Printed to sessions; a moved heading breaks
  them silently.
- `.agents/harness/selftest/orchestrated.sh` block "the closing report:
  one field, two files, one spelling (issue #258)" — grammar `manage.md`
  asks for and `orchestrate.md` defines, pinned in both; keep both sides
  verbatim.
- `.agents/docs/consumer-repos.md` "2026-09-11 cutting
  `.agents/harness/AGENTS.md`" — last trim nearly replaced a fact with a
  pointer to a file consumers lack.

## Traps

- Four plans edit `orchestrate.md` first: the three in `needs:`, plus
  `orchestrated-only` (also `manage.md`), ordered before this one through
  `clerk-role`. Re-measure after they merge; the 8,340 baseline is
  stale by then.
- More open plans edit these files, all marked `shared:` (merged to
  `main` 2026-10-10): `janitor-rules-agree`, `ledger-losses-named`,
  `manager-ceiling-row`, `plan-on-a-branch-visible`,
  `rescope-settled-by-merged-superset`, `stall-rows-say-what-git-knows`
  (`orchestrate.md`); `lineup-cache-read-pricing` (`manage.md`);
  `role-files-say-it-first` (both). Trim last: at start run
  `grep -l 'commands/orchestrate.md\|commands/manage.md' docs/plans/*.md`;
  each one still open = reconcile on its merged text, never undo it.
- `role-files-say-it-first` adds selftest pins on `orchestrate.md`'s
  `description:` line and `manage.md`'s `## Never`; both stay put.
- `orchestrated-only-docs` also edits `.agents/docs/orchestrated.md`
  (both marked `shared:`); reconcile.
- `joharness.sh` is also in `clerk-role`, `upstream-placement-defects`
  and `abandoned-reaches-every-reader`; `clerk-role` also marks
  `shared:.claude/commands/manage.md`. Reconcile, do not overwrite.
- Pointer to a file a consumer may not have = lost fact. Destination is
  `.agents/docs/orchestrated.md`, which syncs.
- Glossary: moved text keeps its spelling; `ci` reds banned ones.
- NEVER edit core paths (`./joharness.sh protocol-paths`).
