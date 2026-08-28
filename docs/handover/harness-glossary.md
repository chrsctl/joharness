---
workstream: harness-glossary
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: harness-glossary
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Adversarial review, then finish
---

## Goal

Plan `docs/plans/harness-glossary.md`: the same node has two names in files
every session loads. The glossary fixes each contested term, names the
wordings that are not it, and a lint stage keeps it from rotting into a wish.

## Decisions

- Counts RE-COUNTED here before any of them ship, because the plan's own
  figures had already drifted twice and it says so:
  `grep -rnoi "<term>" --include=*.md --include=*.sh . | grep -v '^./.git' | wc -l`
  on 2026-08-28 gives workstream file 205 against its older spelling 14,
  agent tier 10 against its older spelling 6, environment layer 24 against
  its older spelling 5. The plan quoted 146 / 12
  at 2026-08-24 and noted 208 by 2026-08-27. Nothing here quotes a figure
  without that command beside it.
- Files using BOTH spellings of the workstream-file term today: eight, not
  the five the plan names — `docs/plans/fork-seam-rules.md`, this plan, and
  `docs/research/glossary-enforcement.md` joined since it was written.

## Rejected

- ADOPTING Vale rather than building. `docs/research/glossary-enforcement.md`
  refuted the plan's implied "no prior art": Vale's `accept.txt` plus
  `Vale.Terms` is exactly this mechanism, running at Datadog and Elastic, and
  the research left adopt-or-build open for this plan. Built: that is a Go
  binary in a `ci` whose whole toolchain is shell and shellcheck, installed
  into every consumer and a sandbox behind an egress allowlist, for three
  substitutions. Recorded because "we invented it" would be false.
- A marker comment to exempt a file that must name what it bans. The plan
  forbids it and the reason showed up immediately: the exemption would have
  had to spread to the selftest fixture too. The fixture ASSEMBLES the banned
  wording at runtime instead, so exactly one path stays exempt.
- Restating the ban list in the lint. It reads the glossary's own table, so
  the list cannot rot against the file that publishes it — the defect this
  whole stage exists to catch.

## Review

(pending)

## Blockers

None.

## Where to look

- `joharness.sh:lint_graph` — the stage shape a new lint copies.
- `.agents/docs/graph.md` Nodes — the closest thing to a canonical vocabulary.
- `docs/research/glossary-enforcement.md` — prior research for this plan.
