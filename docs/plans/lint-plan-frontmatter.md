---
plan: lint-plan-frontmatter
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh
---

## Goal

A plan file with NO frontmatter passes `ci` silently. `lint_enum` returns 0 on
an empty value — correct for optional fields, wrong for the ones the queue
depends on — so a plan missing `plan:`, `agent:` and `effort:` is linted as
clean.

Not hypothetical. `docs/plans/perf-window-fixed-cost.md` lost its whole
frontmatter block in a merged edit (#140, a Python splice that rebuilt the file
from `## Goal` onward). `ci` passed. The queue hook then listed the plan as
`unscoped, independence not provable`, dropped it out of every wave, and
printed a defaulted tier for it — a plan the queue could no longer schedule,
with nothing red anywhere.

`AGENTS.md` step 2 says a plan names `agent` + `effort` and "no tier, no
build". A lint that lets a tier go missing contradicts the rule it exists to
enforce.

## Scope

- `joharness.sh`, the plan-lint block that already calls `lint_enum` on
  `urgency`, `agent` and `effort` — fail RED when one of the required keys is
  absent, not merely when its value is unrecognised. Required: `plan`,
  `urgency`, `agent`, `effort`. Optional and unchanged: `needs`,
  `requirement`, `scope`, `research`.
- The same gap for research files (`research`, `urgency`, `agent`, `effort`,
  `graduates`) — check it, and fix it here if present rather than leaving a
  second copy of one bug.
- `.agents/harness/selftest/` — a case per required key, each red when the key
  is removed.

## Out of scope

- Requiring `scope`. The hook already reports an unscoped plan and says what to
  do about it; that is a warning by design, not a gate.
- Inferring a missing field from the filename. A plan whose frontmatter is gone
  should be fixed, not guessed at — guessing is how the file stays broken.
- Any change to `lint_enum` itself. Its empty-is-fine behaviour is right for
  optional fields; the presence check belongs at the call site.

## Acceptance

- A plan file with no frontmatter fails `ci` with a message naming the file and
  the missing key.
- A plan missing only `agent` fails; a plan missing only `needs` passes.
- Each new case red when its check is reverted.
- `./joharness.sh ci` — `ci: pass` on the repo as it stands.

## Where to look

- `joharness.sh:lint_enum` — why an empty value returns 0.
- `joharness.sh`, the `gr_fields urgency agent effort needs requirement
  research` read — the call site that needs the presence check.
- `.agents/harness/selftest/ci-graph-lint.sh` — where the lint's cases live.

## Traps

- A presence check that fires on the TEMPLATE or README under `.agents/docs/`
  turns `ci` red for everyone. The existing walk already filters those; keep
  using it rather than adding a second filter.
- Never skip, disable or quarantine a test to get green.
