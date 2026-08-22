---
workstream: review-ledger
status: in-progress
branch: claude/review-ledger-4rub8a
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
agent: sonnet
updated: 2026-08-23
next: Add the Review section to protocol and template, tier-scaled review depth to agent-selection, hook line, selftest
---

## Goal

Human feedback after two days of live use: the review loop is opaque and
every loop runs at the same uniform intensity. Both check out against the
repo's own history. The sync-tool branch ran twelve "harden per review
round N" commits at a steady eleven-minute metronome; what round 7 found is
unrecoverable - the findings lived in the reviewer conversation and
evaporated. The protocol stores five non-derivable things; review findings
are a sixth non-derivable thing that nobody stores. And review depth is
uniform: a two-line doc fix pays the same review as a 490-line tool, while
the instrumentation to differentiate (agent tiers) already exists and is
ignored by exactly this one node.

## Decisions

- Findings go into the workstream file (new ## Review section), one line
  per finding, written BEFORE the fix commit and in the same commit as the
  fix. Same lifecycle as everything else there: travels with code,
  delete-on-merge, history keeps it.
- The hook prints "review: N findings recorded" per branch only when N>0.
  Absence next to a visibly churning branch is the signal a human reads;
  no synthetic metric pretends to read it for them.
- Review depth scales with the plan's tier as a rule in
  docs/agent-selection.md: haiku one pass, sonnet standard, opus
  adversarial with separate lenses. Rule text only - that is how every
  rule in this harness works, and the literal-reader findings say it is
  the mechanism that holds.

## Rejected

- An opacity check in ci counting rounds against findings lines. Soft
  metric over prose, gameable with filler, and it recreates the
  status-field failure the Graduation section documents: a check that
  depends on the hurried session maintaining text fails exactly when
  needed. Deliberately discarded before building.
- Review verdict as a frontmatter field. Second copy of the section,
  same field-rot exposure.
- Parsing "review round N" commit subjects. Free-text convention;
  rejected for the churn metric already, same reason here.

## Blockers

None.

## Where to look

- docs/handover/README.md - the five become six.
- docs/handover/TEMPLATE.md - the section shape.
- harness/handover-context.sh - the per-branch line.
- docs/agent-selection.md - the depth rule.
