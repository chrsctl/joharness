---
workstream: mark-mixed-protocol-scope
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: mark-mixed-protocol-scope
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-02
next: Record verifier findings, fix or disposition each, retire this file and the plan, open the pull request.
---

## Goal

Direct ask after a review of the merged plan `unsupervised-drain-only`
(PR 197): "Research and solve". Three findings from that review, two
solved here and one raised for the human.

## Decisions

- `qc_scope_class` marks on ANY protocol path, not only on ALL.
  `handover-guard.sh` counts ANY, so the queue and the guard disagreed and
  the queue was the wrong one. Reverses a deliberate, commented, tested
  decision — the reasoning is in the plan's Goal and the short form is:
  the old rule assumes a session can half-finish a plan, and the Loop has
  no such state.
- Two labels, both marking, both de-ranking: `is all protocol text` and
  `includes protocol text`. One label would erase the distinction the old
  classes carried, and the shapes want different fixes — an `only` plan is
  supervised work forever, a `some` plan might be split.
- `unknown` untouched. Guessing stays out of scope.
- `unsupervised-drain-only.md` gets a stale-plan fix in place, not a new
  plan: `.agents/docs/plans/README.md` names that route, and the file is
  already on `main`.
- Its `advances:` is REMOVED rather than repointed. It advances no bullet:
  it rewrites the requirement. `lint_plan_advances` only fires on plans a
  branch ADDS, so a merged plan losing the field reds nothing.
- Found while building: `cmd_drain`'s NOT YOURS block explains the marked
  rows with "Scope is entirely protocol text", false for a `some` plan the
  moment this lands. Fixed with the block, not left for the next reader —
  `joharness.sh` and `selftest/drain.sh` joined the plan's scope for it.
- Finding 4 of the review — after that plan lands, the mode is one line of
  `drain` text, the spawn line, the `ci` requirement gate, the guard and
  the banner — is NOT acted on. Whether a mode that thin earns its switch
  is product direction. Raised in the pull request.

## Rejected

- Leaving `mixed` alone and fixing only the plan's prose. The prose said
  "Supervised session only" already; attempt four measured prose losing to
  dispatch. A rule nothing reads is the defect, not the wording.
- Marking `mixed` without de-ranking it (a note only). The hazard is that
  `drain` hands the plan out as `next:`; a note does not stop that.
- Changing the plan's `scope:` to protocol paths only. It genuinely
  touches `docs/product/`; a scope that lies to get a marking is worse
  than the marking being wrong.
- Splitting `unsupervised-drain-only` into two plans along the boundary.
  Its doc half rewrites a requirement to describe behavior the code half
  has not got yet; shipping that half alone makes the requirement lie.

## Review

None yet.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:qc_scope_class` — the comparison this
  branch changes.
- `.agents/harness/selftest/queue-context-supervised-only.sh` — "partial
  overlap is a different case", the block that inverts.
- `docs/plans/unsupervised-drain-only.md` — `advances:`, the Traps line
  claiming the queue marks it, and decision 3's bundle.
