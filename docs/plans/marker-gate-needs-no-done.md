---
plan: marker-gate-needs-no-done
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest
---

## Goal

The finding-verdict gate (PR 162) reds only when a branch says
`status: done`. Nothing requires a branch to ever say it — so a branch that
goes `review` straight to the retire commit merges with undispositioned
findings and the gate never fires.

Not hypothetical, and the evidence is this repo's own history. **PR 172's
workstream file said `status: review` when it was retired**, so its `r5` —
"(recorded — the cases were written first thereafter)", which carries no
verdict `fb_marker` recognises — merged unchecked and is now one of the two
sources `./joharness.sh sources` counts:

```
git log --all --format=%H --diff-filter=D -1 -- docs/handover/plan-provenance.md
# then: git show <that>^:docs/handover/plan-provenance.md | grep '^status:'
#   status: review
```

The gate's two strengths are right — a gate that reds mid-build fights the
review gate. What is missing is that "done" is optional, so the strong
strength is opt-in.

## Scope

- Decide what the RED trigger should be, given that `status: done` is not
  reachable by contract. The obvious candidate is the retire commit itself:
  a branch deleting its own workstream file is at the edge by definition,
  which is the same signal `finish` already gates on and does not depend on a
  field a hurried session can skip.
- Whatever is chosen must still not red mid-build. The two-strength shape is
  not the defect.
- `(recorded` is not a verdict `fb_marker` knows, and this session has
  written it repeatedly. Decide deliberately: either add it to the
  vocabulary, or leave it out so those findings keep counting as work. Say
  which and why — a third spelling accepted by accident is how two counts
  drift apart.

## Out of scope

- Rewriting the historical findings. They live in merged commits and cannot
  be edited; the baseline (`FB_SINCE`) is what handles the pile.
- The verifier finding. Its disposition is a human's (issue #168) and no gate
  can resolve it.

## Acceptance

```
bash .agents/harness/selftest.sh    # 0 failed
./joharness.sh ci                   # ci: pass
```

Plus a case for the branch shape that leaks today: `review` → retire commit,
with one undispositioned finding, must red. It must red under
`./joharness.sh mutate` when the new trigger is disabled — and the existing
`status: done` cases must keep passing, or the fix has replaced one hole
with another.

## Where to look

- `joharness.sh:lint_finding_markers` — the gate and its `fin_strength` call.
- `joharness.sh:fin_strength` — returns `done` or `edge`; `edge` is what a
  retiring branch actually is.
- `joharness.sh:fb_marker` — the vocabulary, and the `(recorded` question.

## Traps

- The workstream file is DELETED in the retire commit, so a trigger reading
  the tree finds nothing at exactly the moment it must fire. Read the diff,
  which `lint_ws_in_diff` already does.
- Do not make `status: done` mandatory as the fix. It moves the problem to a
  field rather than removing the dependence on one.
