---
workstream: review-ledger
status: in-progress
branch: claude/review-ledger-4rub8a
pr: none
session: https://claude.ai/code/session_01HpvQWwG3Q7HbibhT4NoUUb
agent: sonnet
updated: 2026-08-23
next: Open the PR from claude/review-ledger-4rub8a — local ci is green, shellcheck runs only in GitHub CI
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

## Review

- r1: Loop step 5 (`harness/AGENTS.md`) still read "in-depth review, always:
  `/code-review` (high)" and named no home for findings — the two things
  this workstream changes. That file is what an agent reads at review time;
  a docs-only edit never reaches it. (fixed)
- r2: a workstream file copied from TEMPLATE.md and left unedited carries
  the placeholder bullet, so the hook prints "1 finding(s) recorded" for a
  branch that recorded none — the signal inverted for exactly the hurried
  session it targets. First called wontfix on "same exposure as every
  other TEMPLATE placeholder"; that does not hold, no other placeholder is
  read as a metric. Placeholder rewritten as prose, counts 0, regression
  test on a verbatim TEMPLATE copy. (fixed)
- r3: `.claude/commands/handover.md` step 3 names Decisions, Rejected and
  Blockers, never Review. That file ships to consumers via
  `scripts/sync-to-consumer.sh`, so every consumer would get a section and
  a hook counter that nothing writes. (fixed)
- r4: the haiku rung of the depth rule names no tool — "one review pass"
  next to a sonnet rung that says `/code-review` explicitly. A literal
  reader concludes haiku needs no `/code-review` at all, which weakens the
  guard for the tier least likely to have written careful code. Rung now
  names the tool. (fixed)
- r5: the "Findings land in…" paragraph in agent-selection.md sat at 2-space
  indent with no blank line after the 4-space opus continuation — lazy
  continuation in CommonMark, so the rule rendered as opus-only. (fixed)
- r6: README heading still read "The two rituals" over three. (fixed)
- r7: `[ "$review_n" -gt 0 ]` lacked the emptiness guard its churn sibling
  carries; empty awk output prints "integer expression expected" to stderr,
  against the file's contract that anything unexpected exits 0 silently.
  (fixed)
- r8: README cited twelve commits by a literal subject only nine carry —
  and round 7, the round the sentence names, is one of the three that do
  not. Greppable written number contradicting the counted one is the exact
  failure "trust counted numbers, never written numbers" exists to stop.
  (fixed)
- r9: README said the hook prints the count "per branch"; it prints for
  other branches only. Own-branch output is unchanged deliberately — the
  churn line sits in the same loop for the same reason, and this branch's
  file is one the hook already orders read in full. Wording corrected
  instead. (fixed)

## Blockers

None.

## Where to look

- docs/handover/README.md - the five become six.
- docs/handover/TEMPLATE.md - the section shape.
- harness/handover-context.sh - the per-branch line.
- docs/agent-selection.md - the depth rule.
- harness/AGENTS.md - Loop step 5, the rule at the point of use.
