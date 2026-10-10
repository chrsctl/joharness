---
plan: upstream-placement-defects
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .claude/commands/upstream-report.md, .agents/harness/selftest/upstream.sh, .agents/docs/feedback.md
---

## Goal

`./joharness.sh upstream` drops 57 findings about canonical's own files into
the bucket it labels unplaceable, and that label is false about 151 of the 530
findings it holds. Both counted over this repo's 273 merged edges, 2026-10-08;
the sweep, the numbers and why the obvious fix is wrong are in
[`.agents/docs/feedback.md`](../../.agents/docs/feedback.md), "Where a
consumer's OWN findings go". The research question that produced them is
answered and retired — this plan is only the code the answer named.

## Scope

- `joharness.sh:upstream_harness_path` — accept the forms the repo's own prose
  actually writes a harness path in. A leading `./` (12 of the 57 are
  `./joharness.sh`, which the predicate's first case would match without it).
  And a bare basename, resolved by **ownership, not by path uniqueness**: if
  every tree path with that basename is canonical-owned, the verdict is
  canonical's even though the path is not unique. One match
  (`selftest.sh`, `janitor.md`, `review.sh`, `drain.md`, `agent-selection.md`,
  `graph.md`) is 44 of the 57; several-but-all-canonical's
  (`handover-context.sh` 5, `queue-context.sh` 4, `TEMPLATE.md` 4) is the
  other 13, and rejecting those would manufacture 13 false negatives while
  the predicate's own comment says the doubtful cases are IN because a false
  negative loses the finding entirely. Reject only a MIXED set: a bare
  `README.md` matches nine `.agents/` paths and the root `README.md`, which
  canonical does not own, so that basename stays rejected and is why the
  count is 57 and not 59.
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
- `.claude/commands/upstream-report.md` — line 45 asserts an unplaceable
  finding "is listed with no path at all", the same sentence defect 1 calls
  false about 151 of 530. The reporter reads it, so leaving it turns the fix
  into a doc that contradicts the command. Already a protocol path, so
  declaring it changes nothing about SUPERVISED ONLY.
- `.agents/docs/feedback.md` — correct the SECOND limit bullet under "When the
  consumer is the detector" (the no-fix-commit one; the first, about a
  multi-finding fix commit, matches `upstream_multi_ids` and is not in
  question), and re-count the two tables in "Where a consumer's OWN findings
  go" against the fixed predicate. NOT `shared:` — no concurrent plan touches
  it and `shared:` means a reconcile is routine here, which would claim a
  parallel safety this plan does not have.

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
  the 57 move out of unplaceable and into the report, and the remaining
  unplaceable count equals the 379 that carry no path token plus the 94 whose
  tokens resolve to nothing canonical owns (8 real non-canonical + 86 junk).
  Paste the counted numbers and the command into `## Review`.
- Whatever shape the fix takes: `upstream_harness_path './joharness.sh'`
  returns 0, and `upstream_harness_path 'docs/handover/README.md'` still
  returns 1. That second one is a real consumer-owned path in every repo
  running this harness, and a suffix match would claim it for canonical — the
  overclaim the research session caught in its own first count (`## Review`,
  r1 of `where-a-consumers-own-findings-go`).
- **The consumer-side check**, because this plan SHIPS (`./joharness.sh ci`,
  ship scope stage): `./joharness.sh upstream` is the one entrypoint changed
  here and canonical can never run its classifying path —
  `JOHARNESS_CANONICAL=1` returns early. So the bar is met in a repo without
  that line or not at all. Either a real consumer, or the stripped-conf
  fixture the graduation documents:
  `JOHARNESS_CONF=<scratch>/consumer.conf ./joharness.sh upstream <edge>`
  must print a bucket heading that is true of every finding under it, and the
  44 must appear under `harness findings`. Local-only green here proves the
  code path nobody runs.

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
- Never relax a guard that just caught you. The fix routes 57 findings the
  bucket was holding; it does not widen what counts as owned past a basename
  whose every tree match is canonical's. A MIXED match set stays rejected.
- A test written for a fix must FAIL without it.
