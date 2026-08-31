---
plan: unsupervised-mark-findings-at-the-edge
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
scope: joharness.sh, .agents/harness/selftest
---

## Goal

The baseline (PR 161) makes the unmarked-findings source reachable: today it
counts 0. Keeping it reachable is a different problem, and it is the half the
requirement's constraint was really about.

Loop step 5 already says findings must be dispositioned — "Fix them or record
why not — never drop silent". Nothing enforces it, and **155 findings across
this repo's history are unmarked**, 62 of them without an id. Every one of
those was a session that recorded a bullet and never said what happened to
it. Under unsupervised mode each such edge feeds the source sweep that
decides whether the fleet may stop, so the mode manufactures its own backlog
exactly as the constraint warns — the baseline just moves the starting line.

## Scope

- `ci` reports an unmarked finding in THIS branch's workstream file, and reds
  once the file says `status: done`.
- Two strengths, and the reason is the same one `fin_strength` already
  carries: a gate that reds mid-build fights the review gate, which needs
  findings recorded while the review is still happening. Report at the edge,
  red at done.
- Another session's inherited workstream file is reported and never red. A
  gate that fails for somebody else's omission is one sessions route around
  — `cleanup`'s business, and the rule `ci` already applies to leftover
  workstream files.

## Out of scope

- The 155 historical findings. They are inside merged commits and cannot be
  edited; the baseline is what handles them, and re-litigating that is
  `docs/product/unsupervised-mode.md`'s Constraints, ratified 2026-08-31.
- Inventing a marker vocabulary. `fb_marker` already reads `wontfix`,
  `no change`, and `(fixed`; use exactly those.
- Findings with no `rN:` id. `lint_finding_ids` already reports them and it
  is a different defect — unkeyable, not undispositioned.

## Acceptance

```
./joharness.sh ci     # reports an unmarked finding on a review-status branch
./joharness.sh ci     # RED on the same branch once status: done
bash .agents/harness/selftest.sh                 # 0 failed
```

Every new case must red under `./joharness.sh mutate` when its branch is
disabled. A case green both ways pins nothing — three of those have been
found in this repo in four days.

## Where to look

- `joharness.sh:fb_marker` — the vocabulary, already defined.
- `joharness.sh:lint_finding_ids` — the report-only stage this joins, and
  the precedent for reporting rather than failing.
- `joharness.sh` finish gate — `fin_strength`, the two-strength reasoning
  this copies rather than reinvents.

## Traps

- The workstream file is DELETED in the last commit before the pull request
  opens. A gate reading the tree at that point finds nothing; read the diff
  against the merge base, which is the rule `.agents/docs/feedback.md`
  graduated after six edges paid for it.
- A finding recorded and dispositioned in the same commit is the normal case,
  not an error.
