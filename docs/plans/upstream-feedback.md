---
plan: upstream-feedback
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/docs/feedback.md, .agents/docs/orchestrated.md, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, .claude/commands, .agents/harness/selftest
---

## Goal

A child repo running this harness detects harness defects and cannot deliver
them. `.agents/docs/feedback.md` § *When the consumer is the detector* names
the four steps a session must walk by hand, and records that they were walked
by hand three times in one session and never mechanized. Under orchestrated
mode nobody is left holding them: the manager exits at its merge, and the
orchestrator writes nothing but a killed manager's workstream file. The
findings themselves are already gone by then — the finish ritual deletes the
workstream file, which is the `Retention: zero` row of the same document.

So: one switch the human sets, off by default, that routes what a merged edge
found ABOUT THE HARNESS from the child to canonical as a defect or improvement
report pull request. Off by default because it spends money nobody asked for
and files pull requests in a repository the child does not own.

## Scope

- `joharness.sh` — `upstream_mode` / `upstream_on` beside `review_mode` /
  `review_on`; `cmd_upstream` (report only, writes nothing, opens nothing);
  the `upstream` subcommand row in the dispatch table and the header map;
  one knob line in `cmd_dispatch`'s block and one verdict hint when on.
- `.agents/scripts/conf-keys.sh` — declare `JOHARNESS_UPSTREAM_FEEDBACK`,
  default `off`, so every consumer's sync names the key it does not answer.
- `.agents/scripts/bootstrap-consumer.sh` — the same key in the seeded
  heredoc. No interview question: a sixth question about an off-by-default
  beta mechanism is the cost `.agents/docs/orchestrated.md` already refused
  for its own knobs.
- `.claude/commands/upstream-report.md` — the child worker role. One merged
  edge, one report, exits.
- `.claude/commands/orchestrate.md` — the `done` row gains its action, the
  ledger gains `reported=`, the tools table gains the degradation.
- `.agents/docs/feedback.md` — the mechanism, under § *When the consumer is
  the detector*, as the mechanized form of those five steps.
- `.agents/docs/orchestrated.md` — one row in *What the mode changes*, one
  row in the knob table.
- `.agents/harness/selftest/upstream.sh` — cases below.

## Out of scope

- Filing anything from canonical. `JOHARNESS_CANONICAL=1` makes `upstream`
  say so and stop: a canonical session's findings are already in the repo
  that owns the fix, and there is nothing to route.
- Writing a requirement in canonical. `docs/product/` is the human's goal and
  `lint_requirement_writes` reds an unattended branch that adds one. The
  report is a research node — a question canonical's own queue lists, claims
  and deletes — never a requirement and never a plan asserting the fix.
- Fixing the harness from the child. The direction rule
  (`.agents/docs/consumer-repos.md`): the next sync overwrites every
  harness-owned file in the consumer, so a local fix is deleted by the
  mechanism whose job is keeping it current.
- Any change to what the review step already does. The switch routes what
  the review found; it does not add a round to the manager's own review.
- An interview question, a flag, or a default that is anything but `off`.

## Acceptance

- `./joharness.sh upstream` in this repo — prints `CANONICAL` and exits 0
  without reading a workstream file.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.
- `bash .agents/harness/selftest.sh` — 0 failed, and the new file's cases
  in the count.
- Plan `ci` calls SHIPS: `joharness.sh`, `.agents/docs/`, `.claude/commands/`
  all reach consumers, which is the only repo kind where the switch does
  anything.

## Where to look

- `.agents/docs/feedback.md:When the consumer is the detector` — the five
  steps this mechanizes, and the measured cost of walking them by hand.
- `joharness.sh:review_mode` — the off/on shape this copies: off reports,
  on is acted on.
- `joharness.sh:fb_collect` — the merged-edge walk and the finding keys.
- `joharness.sh:cmd_upgrade` — reads `CANONICAL_REPO` out of
  `.github/workflows/update.yml`; the same address this reports against.
- `joharness.sh:ship_path_ships` — canonical-only. A consumer cannot run it,
  so the harness-owned test here is its own.
- `.claude/commands/orchestrate.md` — the health table whose `done` row
  currently says "Nothing".

## Traps

- A session never writes `docs/product/`. The report is a research node.
- Report only: nothing in `joharness.sh` spawns, pushes or opens anything.
- Off by default, and a value that is not `on` reads as off. The switch
  fails closed like every other one in this file.
- Never relax a guard that just caught you (`.agents/docs/feedback.md` § 1).
  The report carries the measurement or it is not filed.
