---
workstream: requirement-partly-served
status: in-progress
branch: requirement-partly-served
pr: none
plan: requirement-partly-served
issue: 626
session: https://claude.ai/code/session_016EDW1X75GerKAg5ZJsL2RV
agent: opus
updated: 2026-10-25
next: ci and verify on head, re-verify the r10-r19 delta, then retire and PR
---

## Goal

Issue #626 follow-up: a plan naming `requirement:` must be able to say
which `## Satisfied when` clauses it serves (`serves:`), so a requirement
only partly planned is still offered for planning, and is not deleted at
retire with clauses unbuilt.

## Decisions

- A1: confirmed — `served` in `queue-context.sh` is `awk -F'\t' '$5 != ""…'`
  over plan rows: a stem set, no clause notion.
- A2: refuted in part — requirement files in this repo's history number
  their clauses (`1. **Prevention.** …`, defect-to-fix-loop.md) as well as
  bullet them. Clauses = top-level items, `-`/`*`/`+` or `<n>.`/`<n>)`,
  numbered by position; indented lines and fenced blocks excluded. The
  consumers' files (chrsctl/gx) are not reachable from this session.
- The recorded default answer (plan "Decide first") is adopted whole; it
  lives in `.agents/docs/product/README.md` "Clauses".
- Deletion check counts only when some plan naming the requirement declared
  `serves:`: no plan ever (exits 3/4) and any `all` stay today's behaviour.
  After partial plans, exit 3/4 clauses ride a last plan's `serves:`.
- `serves: all` beside `requirement: none` is not red: it is the template's
  default line.
- Queue SRV lines ride `rows_raw` like REF lines: `rows` keeps its columns,
  so no reader of it changes.
- `./joharness.sh verify` 2026-10-25: first run `5 passed, 1 failed`
  (container networking, docker-smoke-net name resolve, right after a
  cold dockerd start); second run `6 passed, 0 failed`. The diff touches
  no layer file.
- `dispatch` names a PARTLY PLANNED requirement as such on its spawn line;
  the `Requirements without plans` header stays, `drain_requirement` keys on it.

## Rejected

- None yet.

## Review

- r1: (plan-checker) listing counts open plans only, deletion counts retired too: a clause a merged plan built reads unserved and is re-offered (fixed: the listing adds retired plans' `serves:` from the base's history, read only for a requirement its open plans leave partial; selftest case)
- r2: (plan-checker) fixture acceptance names no command and no expected output (fixed: plan Acceptance names the selftest strings `ci` runs)
- r3: (plan-checker) both frontmatter readers print "" for absent and for empty `serves:` (fixed: `gr_has_field` and the hook's key test; selftest cases for both)
- r4: (plan-checker) A2 evidence cites product README for `## Satisfied when`; only TEMPLATE.md names it (fixed: plan A2 evidence corrected; README now names the section, Clauses)
- r5: (plan-checker) scope overlaps needs-cycle-lint on joharness.sh, ci-graph-lint.sh, graph.md, same function (no change: both mark the files `shared:`, a reconcile at finish is the declared cost; neither reads the other's result, so no `needs:`)
- r6: (plan-checker) scope overlaps release-claim-held-by-edge on joharness.sh (no change: `shared:`, no shared function)
- r7: (plan-checker) offering happens in dispatch, untested, and its spawn line says UNPLANNED (fixed: dispatch names PARTLY PLANNED; dispatch-order selftest case)
- r8: (plan-checker) manage.md routes `docs/product/<r>.md` as UNPLANNED only (fixed: the route names PARTLY PLANNED, plan the unserved clauses)
- r9: (plan-checker) product README still says a requirement with open plans is silent (fixed: the line names the PARTLY PLANNED exception)
- r10: (verifier) partial plans all retired, none open: the requirement read UNPLANNED, built clauses re-planned (fixed: `qc_unserved_retired` labels it PARTLY PLANNED from retired plans' `serves:`; selftest case, mutant reds it)
- r11: (verifier) a plan deleted as obsolete counts as served (wontfix: deletion is the only retirement git carries, built and obsolete look alike; product README Clauses makes deleting an obsolete partial plan a planning act that re-plans its clauses)
- r12: (verifier) a retire plus a similar add in one commit is a rename; the retirement vanished (fixed: `--no-renames` on both history reads and the deletion diff; selftest case asserts the rename, mutant reds it)
- r13: (verifier) shallow clone re-offers a clause a retired plan served (wontfix: the safe direction, one planner more; the lint warns, the hook has no per-row warn channel; written in product README)
- r14: (verifier) docs say open plans only, code counts retired (fixed: product README, plans README, graph.md say open and retired)
- r15: (verifier) product README's UNPLANNED test line and orchestrate.md's spawn row name UNPLANNED only; spawn line lacks the clauses (fixed: both name PARTLY PLANNED; the dispatch line carries `clause(s) N unserved`, dispatch-order case)
- r16: (verifier) `## Satisfied When` counted 0 clauses (fixed: heading matched case-blind in both readers; selftest case, mutant reds it)
- r17: (verifier) clause numbers are positions, an edit renumbers silently (wontfix: the recorded default; product README tells the PR that edits the clauses to re-check open plans' `serves:`)
- r18: (verifier) refute-only queue cases pass on an early exit (fixed: each carries a positive control on the listed plan)
- r19: fixture history poisoned the history cases: a retired no-`serves:` plan and `sv-word` (`serves: 1, two`) served clause 1 for every later read, so they passed without the fix (fixed: no-`serves:` case moved last, `sv-word` names no in-range clause; mutants for `--no-renames`, retired reads and retired-alone each red the run)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:served` — the stem set that silences `unplanned`.
- `joharness.sh:lint_graph` — requirement edge checks, `lint_existed`.
