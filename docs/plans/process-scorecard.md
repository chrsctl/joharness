---
plan: process-scorecard
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/docs/graph.md, .agents/harness/selftest.sh
---

## Goal

`ci` already counts one process fact. `== churn` (`joharness.sh:234`) reads
git, counts commits per file since the merge base, warns at a threshold and
fails at a ceiling — and it earned that gate on evidence: the twelve-round
sync branch peaked at 13 where every other merge in this repo's history sat
at 4 or below. Every other claim the Loop makes about how a branch behaved
is uncounted. Step 5 says findings land in `## Review` before the fix and
in the same commit as it. Step 7 says the pull request's final state
deletes the workstream file and the done plan. Both are honour-system: no
command reports whether either happened, and the one measurement anyone did
take found the failure real — 23 stale workstream files in one consumer,
thirteen merges adding six and removing none.
`kitchen-engineer42/joharnessburg` answers this with
`scripts/process_scorecard.py`: deterministic, read-only, frozen rubric,
reporting how a run *behaved* rather than whether its output was good. Take
the idea; derive it from git instead of from a log.

## Scope

- `joharness.sh` — a `scorecard` subcommand beside `graph`
  (`cmd_graph`, line 548), registered in the dispatch block at line 796 and
  in `usage`. Read-only, exit 0 always, derived at read time. Counts for
  the current branch against its merge base: commits; files touched;
  whether a workstream file exists and how many commits touched code
  without touching it; `## Review` lines present; plan and requirement
  files the diff deletes; the `churn_top` maximum already computed. Counted
  numbers only — no grade, no score, no adjective.
- `.agents/docs/graph.md` — the Serving section names `./joharness.sh graph`
  as the derived whole-graph view. Add this one beside it, in the same
  terms, so the next reader finds both.
- `.agents/harness/selftest.sh` — scratch repos per the file's existing
  fixture style: a branch with review lines and a same-commit workstream
  update, a branch with neither, a branch whose diff deletes its plan file.
  Each count asserted exactly.

## Out of scope

- A lessons ledger. John pairs its scorecard with `.john/lessons/`, an
  append-only per-lesson store, and that half does not transplant:
  `.agents/docs/graph.md` Rules says "No stored graph, no auto-extraction"
  and "Derived state = second copy, rots", and the graph already carries a
  `graduated` edge (workstream to `AGENTS.md` or `docs/`, carried by the
  merge commit that deletes the file) with Loop step 7 as its ritual. The
  promotion path exists. Adding a store beside it duplicates the thing this
  repo has already measured going wrong. Do not build it, do not build a
  smaller version of it.
- Failing `ci` on any scorecard number. `churn` earned its ceiling with a
  backtest over every merge on main; this has no backtest yet. Report
  first. A later plan gates whichever number the data supports.
- Judging work quality. The scorecard reports process behaviour and nothing
  else — findings recorded, not findings correct.
- Scoring other branches. Current branch against its merge base, same
  frame `churn_top` already uses.

## Acceptance

- `./joharness.sh scorecard` on this repo's `main` — runs, exits 0, prints
  counts, invents nothing. Paste the output.
- `./joharness.sh scorecard` on a branch with code commits and no
  workstream file — the workstream count reads 0 and the line says so
  plainly. A silent zero reads as a pass.
- `./joharness.sh scorecard` in a repo with no merge base (shallow
  checkout, detached HEAD) — exits 0, says it could not compute, does not
  print a wrong number.
- Every number reproduced by hand from `git log` for at least one branch,
  the commands recorded in the workstream file. Trust counted numbers: that
  includes these.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `joharness.sh:308` — `churn_top()`, the existing merge-base walk with its
  protocol-path exclusions. Reuse it; do not write a second walk.
- `joharness.sh:234` — the `== churn` stage, for how a counted process fact
  is already worded to a session.
- `joharness.sh:548` — `cmd_graph`, the precedent for a read-time derived
  view as its own subcommand.
- `joharness.sh:411` — `lint_graph()`, for how frontmatter is parsed here.
- `.agents/docs/graph.md`, Rules and Serving — the two paragraphs that
  decide what this may and may not store.
- `.agents/docs/handover/README.md:86` — what a `## Review` line is, so the
  count matches the protocol's definition.

## Traps

- No state store, in any form, however small. `.agents/docs/graph.md`
  Rules. This is the prohibition the plan lives next to.
- Derived at read time or not at all. A cached scorecard is the second copy
  the same rule forbids.
- `compact-reorient` and `harness-glossary` also touch
  `.agents/harness/selftest.sh`; `harness-glossary` and `ci-scope-selftest`
  also touch `joharness.sh`. Not a wave with those.
- Never hand-write time or source into a file (`.agents/docs/graph.md`,
  Rules) — provenance is commits, so the scorecard reads them rather than
  recording its own run.
- A check that prints nothing when it finds nothing is indistinguishable
  from a passing one. Every count prints, including the zeroes.
