---
plan: unsupervised-plan-provenance
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
scope: joharness.sh, .agents/harness/selftest
---

## Goal

Two more bullets the goal bound (PR 169) adds and nothing implements:

> Every plan an unsupervised session generates names the requirement it
> serves and the `Satisfied when` bullet it advances. A plan that serves no
> open requirement is not generated.

> No unsupervised session writes a requirement. The goal is the human's to
> set, and a fleet that writes its own finish line has none.

Half of the first exists: plans carry `requirement:` frontmatter and
`lint_graph` resolves the edge. What does not exist is the BULLET, and
nothing at all enforces the second.

The second is the load-bearing one. `protocol_paths` covers protocol text;
`docs/product/` is not in it, and correctly so — a requirement is product,
not protocol. So today an unsupervised session could write itself a new
requirement and keep the fleet alive forever, which is exactly the
circularity the bound was adopted to close.

## Scope

- A generated plan names the bullet it advances, not just the requirement.
  Decide the spelling — frontmatter field or a required section — and lint
  it. Prefer the one that rots visibly in a diff.
- `ci` reds an unsupervised branch that adds or edits a file under
  `docs/product/`. Supervised is untouched: writing requirements is what a
  human-attended session does with a human.
- The guard reads the DIFF against the merge base, never the tree.

## Out of scope

- Requiring the bullet on plans a HUMAN writes. The bullet is about what an
  unsupervised session generates; a human writing a plan by hand is not the
  risk, and a gate that fires on them is one they route around.
- Adding `docs/product/` to `protocol_paths`. It is not protocol text, and
  the boundary's own Constraint says the rule is the role. This is a
  different guard with a different reason.

## Acceptance

```
./joharness.sh mode unsupervised
./joharness.sh ci     # RED on a branch touching docs/product/
./joharness.sh mode supervised
./joharness.sh ci     # green on the same branch
bash .agents/harness/selftest.sh    # 0 failed
```

Both modes, because a guard that reds everywhere is one that gets disabled,
and a guard that reds nowhere is the one being fixed. Each case must red
under `./joharness.sh mutate`.

## Where to look

- `joharness.sh:protocol_paths` and the unsupervised banner — the existing
  boundary, and the shape to copy without widening it.
- `joharness.sh:lint_graph` — where `requirement:` is already resolved.
- `.agents/harness/handover-guard.sh` — the other reader of the boundary,
  and the precedent for reporting facts rather than blocking.

## Traps

- This diff itself edits `docs/product/`. Write the guard so it could not
  have stopped its own requirement amendment — supervised, by a human's
  direction — or it is the wrong guard.
- A plan naming a bullet by quoting it goes stale silently when the bullet is
  reworded. Naming by index rots the same way when a bullet is inserted.
  Pick deliberately and say which failure you accepted.
