---
workstream: lint-plan-frontmatter
status: review
branch: claude/lint-plan-frontmatter
pr: none
plan: lint-plan-frontmatter
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Merge once green
---

## Goal

Close the gap that let a defect of mine through: `lint_enum` returns 0 on an
empty value, so a plan or research node carrying no frontmatter at all passed
every check silently. PR 140 dropped a plan's whole frontmatter block; `ci`
stayed green; the queue then listed it unscoped with a defaulted tier.

## Decisions

- One `lint_required` helper rather than the check spelled eight times. The
  rule is "the queue schedules on this key", and it is the same rule for both
  node types.
- Per key, not one has-frontmatter test. A node that loses only its tier is
  the more likely failure and would stay green under a whole-block check.
- `scope` deliberately excluded. The hook already reports an unscoped plan and
  says what to do; making it red would turn a by-design warning into a gate.
- `graduates` keeps its own existing red rather than being folded in — it
  carries a reason of its own, not just presence.

## Rejected

- Changing `lint_enum` to fail on empty. Its behaviour is right for optional
  fields, which are most of them; the presence question belongs at the call
  site where required-ness is known.
- Inferring a missing `plan:` from the filename. The stem usually matches, so
  the guess would usually work — and a guard that repairs its own input is one
  nobody fixes the input for.

## Review

opus, adversarial.

- r1: checked `lint_nodes` already filters TEMPLATE, README and VISION, so the
  trap the plan named — a presence check firing on the templates and reddening
  ci for everyone — is covered by the existing walk. Verified rather than
  assumed, and no second filter added. (no action)
- r2: `research` was already a local COUNTER in `lint_graph`, so reading the
  field into it would have silently clobbered the count in the summary line.
  Used `rstem`. Same shape as the `tip`-absorbs-the-subject bug in PR 141:
  a name already in scope, reused for a different thing. (fixed)
- r3: all six new cases proved red with the check reverted. (no action)
- r4: the refute cases matter more than the expects here — they pin that the
  check is per key and that `scope` stays optional. Without them this is a
  guard that could be tightened later into the gate the plan forbids. (no
  action)

## Blockers

None.

## Where to look

- `joharness.sh:lint_required` — the helper and the defect it exists for.
- `joharness.sh:lint_nodes` — why the templates are already exempt.
