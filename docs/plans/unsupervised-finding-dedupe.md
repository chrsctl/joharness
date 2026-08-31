---
plan: unsupervised-finding-dedupe
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
scope: shared:joharness.sh, .agents/harness/selftest/feedback.sh
---

## Goal

The requirement's constraint:

> A finding that unsupervised-generated work itself introduced is not a
> source finding. Without this the mode manufactures its own backlog and the
> sweep never dries. Dedupe against the plans that already cited the
> finding, open or in history.

**Nothing implements it.** `grep -rn "dedupe\|already cited\|cited the
finding" joharness.sh .agents/harness/*.sh` returns nothing, 2026-08-31.

The count that detector reports is **151 unmarked findings** (`main`
`aab2fa4`). Every merged edge adds more, and each plan written to address
one adds its own review findings on merging. So the detector this constraint
guards is the one that can least reach zero, and the mode's stopping
condition runs through it.

## Scope

- A finding already cited by a plan — open on `main`, or in history because
  the plan merged and was retired — stops counting as unmarked.
- History matters as much as the tree: plans are deleted when done
  (`.agents/docs/plans/README.md`, Lifecycle), so a tree-only check counts
  every addressed finding forever. This is the "tree or diff" class again
  (`.agents/docs/feedback.md`) in a third caller.
- Report what the dedupe removed, not just the reduced number. A count that
  drops with no way to see why is a count nobody can audit.

## Out of scope

- Marking findings by hand, or a field in the workstream file that says
  "addressed". Field discipline fails exactly when someone hurries — the
  reason plans carry no status field either.
- Deciding whether 151 is too many. This plan changes what counts, not what
  the number should be.
- The stop condition's other three parts — `unsupervised-stop-condition`.

## Acceptance

```
JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback   # unmarked count drops
./joharness.sh sources                               # and the sweep agrees
bash .agents/harness/selftest.sh                     # 0 failed
```

The fixture must contain a finding cited by a RETIRED plan, not only by a
live one. That is the case a tree read gets wrong, and it is the whole
reason this is not a one-line grep.

## Where to look

- `joharness.sh:cmd_sources` — the unmarked detector.
- `joharness.sh:fb_*` — the walk that produces findings, and `fb_fix_map`
  which already keys a finding to the file its fix touched.
- `.agents/docs/feedback.md`, "Worked example: tree or diff" — the rule this
  must not break for the seventh time.

## Traps

- A finding cited by a plan that was ABANDONED, not merged, is still open
  work. History includes branches that never landed; do not count those.
- Do not dedupe on the finding's text. Ids exist (`r1:`), `lint_finding_ids`
  already reports the ones that cannot be keyed, and text matching would
  silently absorb a different finding that reads alike.
