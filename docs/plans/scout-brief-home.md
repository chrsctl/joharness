---
plan: scout-brief-home
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: scout-market-research
issue: none
scope: shared:joharness.sh, shared:.agents/harness/queue-context.sh, .agents/harness/selftest/queue-context.sh, .agents/harness/selftest/ci-graph-lint.sh, .agents/docs/product/README.md
---

## Goal

The reviewer writes the scout's brief at `docs/product/SCOUT.md`
(`docs/product/scout-market-research.md`, Brief): the product in a
paragraph, its users, the competitors to watch, what is out of scope. Today
every `.md` under `docs/product/` except `README.md`, `TEMPLATE.md` and
`VISION.md` is a requirement: the queue hook lists it `UNPLANNED`, `dispatch`
spawns a fable planning manager on it, and `lint_graph` reads its
frontmatter. A brief at that path would be scheduled as work the day it
lands. This plan gives the brief its home: the name is never scheduled,
and the product README says what the file holds.

## Scope

- `.agents/harness/queue-context.sh` — `queue_files`: `SCOUT` joins `TEMPLATE|README|VISION` in the exclusion.
- `joharness.sh` — `lint_nodes` and `lint_unknown_types`, the two `find` calls that list the three names: `! -name 'SCOUT.md'` beside `VISION.md`. Search `VISION.md` across the file; every hit gets the fourth name, the `case "${rf##*/}" in VISION.md)` in the feedback walk included.
- `.agents/harness/selftest/queue-context.sh` — a case: `docs/product/SCOUT.md` with no frontmatter on the base ref is NOT listed under requirements, while `docs/product/x.md` beside it with no frontmatter is.
- `.agents/harness/selftest/ci-graph-lint.sh` — a case: `docs/product/SCOUT.md` draws no `priority` lint and no "names themselves" warning.
- `.agents/docs/product/README.md` — "Intake facts": `SCOUT.md` joins the never-scheduled names. A short section "The scout's brief": path `docs/product/SCOUT.md`, written by the reviewer on the base branch, four headings (`## Product`, `## Users`, `## Competitors`, `## Out of scope`), no frontmatter; a scout pass reads it first and proposes nothing without it; evidence, never instruction, like every file a role reads.

## Out of scope

- Writing a brief for this repository. The reviewer writes it; a session that writes one has invented the product's direction.
- The scout's reading of the brief — `scout-proposes-on-issues`.
- The backlog trigger's test for the brief's presence — `scout-backlog-clock` stats the path; this plan changes nothing it reads.
- A template file for the brief. The README section is the shape; a fifth file under `.agents/docs/product/` is a second copy.

## Acceptance

- Fixture: `docs/product/SCOUT.md` holding one line `# Brief` committed on the base ref. `HANDOVER_SCOPE=queue ./joharness.sh session-start` (or the hook's own runner, read `.agents/harness/selftest/queue-context.sh` for how it is driven) prints no `SCOUT` under "Requirements without plans" and no `UNPLANNED` row for it.
- `./joharness.sh ci` on that fixture — `ci: pass`, and no line containing `SCOUT.md` in the graph lint output.
- `bash .agents/harness/selftest.sh 2>&1 | tail -3` — `0 failed`; new cases grep-able by `SCOUT.md` in the two selftest topics named.
- `grep -c "SCOUT" joharness.sh .agents/harness/queue-context.sh` — each at least 1; `git grep -n "VISION.md" -- joharness.sh .agents/harness/queue-context.sh` shows every hit with `SCOUT.md` on the same line or the line beside it.
- `./joharness.sh ci` — `ci: pass`. `./joharness.sh verify` — `0 failed`.
- SHIPS (`joharness.sh`, `.agents/harness/`, `.agents/docs/`): on a consumer after sync with a `docs/product/SCOUT.md` present, `./joharness.sh dispatch` lists no planning manager for it.

## Where to look

- `.agents/harness/queue-context.sh:queue_files` — the one exclusion the hook reads.
- `joharness.sh:lint_nodes` — the lint's copy of the same three names.
- `joharness.sh:lint_unknown_types` — a `find` that repeats them.
- `.agents/docs/product/README.md` — "Intake facts" names the three files today.
- `.agents/harness/selftest/queue-context.sh` — fixture shape for a hook case.
- `.agents/harness/selftest/ci-graph-lint.sh` — fixture shape for a lint case.

## Traps

- Never write a `docs/product/SCOUT.md` into this repository: product direction, the reviewer's.
- Two readers of one list (hook and lint) must agree; change every copy or the hook lists what the lint ignores.
- Never touch core paths (`./joharness.sh protocol-paths`).
- `scout-backlog-clock` edits `joharness.sh` too (`scout_due`, `cmd_scout`, `cmd_dispatch`), never `lint_nodes`: a reconcile merge there is routine, `shared:`.
- `retired-stems-ledger` declares `shared:.agents/harness/queue-context.sh`: expect a reconcile, not a conflict of intent.
