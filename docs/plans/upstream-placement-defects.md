---
plan: upstream-placement-defects
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest/upstream.sh, shared:.agents/docs/feedback.md
---

## Goal

`./joharness.sh upstream` drops 44 findings about canonical's own files into
the bucket it labels unplaceable, and that label is false about 151 of the 530
findings it holds. Both counted over this repo's 272 merged edges, 2026-10-08;
the sweep, the numbers and why the obvious fix is wrong are in
[`.agents/docs/feedback.md`](../../.agents/docs/feedback.md), "Where a
consumer's OWN findings go". The research question that produced them is
answered and retired — this plan is only the code the answer named.

## Scope

- `joharness.sh:upstream_harness_path` — accept the two forms the repo's own
  prose actually writes a harness path in. A leading `./` (12 of the 44 are
  `./joharness.sh`, which the predicate's first case would match without it).
  And a bare basename that resolves to exactly ONE canonical-owned path in the
  tree (`selftest.sh`, `janitor.md`, `review.sh`, `drain.md`,
  `agent-selection.md`, `graph.md`). Ambiguous basename, or more than one
  match: reject, as now.
- `joharness.sh:cmd_upstream` — the middle branch reads
  `[ -n "$paths" ] && [ "$from_text" -eq 0 ]`, so a text-placed finding on no
  canonical path cannot reach "this repo's own" and falls to the unplaceable
  `else`. Split the third bucket in the output instead of mislabelling it:
  findings with NO path token at all keep today's heading; findings whose text
  named paths that are not canonical's say so, and say the paths came from
  prose. The `from_text` caveat exists already and is built into the kept
  bullet only.
- `.agents/harness/selftest/upstream.sh` — a case per defect, each failing
  before the fix.
- `shared:.agents/docs/feedback.md` — correct the two limit bullets under
  "When the consumer is the detector" that describe the behaviour the code
  does not have, and re-count the table in "Where a consumer's OWN findings
  go" against the fixed predicate. `shared:` because the file is the
  graduation target of the question that produced this plan.

## Out of scope

- **Narrowing `upstream_text_paths`.** 142 of the 151 text-path findings
  resolve to nothing real (`origin/main` 20, a bare `/` 8, `precision/recall`,
  `before/after`), and a tokenizer tightened to drop those drops the 44 too.
  The ownership predicate is what is wrong. Leave the tokenizer alone.
- **A destination for the 379 pathless findings.** They are `wontfix` and
  no-change verdicts with no path by construction; a path-keyed place cannot
  hold them. Settled, not deferred — `.agents/docs/feedback.md`, same section.
- **Pointing `upstream` at the consumer** (issue #258's third direction). The
  count says it is a destination for nothing. Do not build it.
- **`JOHARNESS_UPSTREAM_FEEDBACK`'s default.** Stays `off`. The requester's,
  not an implementer's.
- **Narrowing `fb_fix_map`.** Commit-level attribution is `feedback`'s and
  changing it moves every number that command prints.

## Acceptance

- `bash .agents/harness/selftest.sh` — 0 failed. Read the pass count this
  tree prints; a written one would be true for one layer only.
- `./joharness.sh ci` — `ci: pass`.
- Each new case fails with the fix reverted and passes with it restored.
  Green both ways pins nothing (`.agents/harness/AGENTS.md` step 5).
- The sweep in `.agents/docs/feedback.md` re-run against the fixed predicate:
  the 44 move out of unplaceable and into the report, and the remaining
  unplaceable count equals the findings that genuinely carry no path token.
  Paste the counted numbers and the command into `## Review`.
- `printf '%s\n' './joharness.sh' | ...` — whatever shape the fix takes,
  `upstream_harness_path './joharness.sh'` returns 0 and
  `upstream_harness_path 'docs/handover/README.md'` still returns 1. That
  second one is a real consumer-owned path in every repo running this harness,
  and a suffix match would claim it for canonical — the overclaim the research
  session caught in its own first count (`## Review`, r1 of
  `where-a-consumers-own-findings-go`).

## Where to look

- `joharness.sh:upstream_harness_path` — the predicate, and the comment saying
  doubtful cases are deliberately IN because a false negative loses the
  finding entirely. These 44 are that false negative.
- `joharness.sh:cmd_upstream` — the three-way split, and its comment naming
  the third bucket as the one an earlier round got wrong.
- `joharness.sh:upstream_text_paths` — the tokenizer. Read it to see why it is
  out of scope, not to change it.
- `.agents/docs/feedback.md` — the measurement, the cross-check against
  `cmd_feedback`'s own volume line, and the trap.

## Traps

- `joharness.sh` is a protocol path (`./joharness.sh protocol-paths`). This
  plan is **SUPERVISED ONLY**: `export JOHARNESS_MODE=supervised` in the
  session that implements it, and that session is a human's.
- Trust counted numbers, never written numbers — including every number in
  this file. The command that re-counts each one is beside it.
- Never relax a guard that just caught you. The unplaceable bucket caught 44
  real findings; the fix routes them, it does not widen what counts as owned
  past one unambiguous match.
- A test written for a fix must FAIL without it.
