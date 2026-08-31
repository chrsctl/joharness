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

**Rewritten 2026-08-31**, after the requester directed that creating queue
items is always allowed. What this plan was originally going to enforce —
"a plan that serves no open requirement is not generated" — **is no longer
the rule**, and building it would have made a session drop real findings on
the floor whenever no goal was open. See the requirement's Satisfied when,
"Recording is always allowed; generating is what the bound governs."

What remains is the half that was always load-bearing:

> No unsupervised session writes a requirement. The goal is the human's to
> set, and a fleet that writes its own finish line has none.

Nothing enforces it. `protocol_paths` covers protocol text; `docs/product/`
is not in it, and correctly so — a requirement is product, not protocol. So
today an unsupervised session could write itself a new goal and keep the
fleet alive forever, which is exactly the circularity the bound was adopted
to close. The goal-reached stop (PR 170) is only as strong as this.

And a smaller piece: a plan generated **while a goal is open** should name
the `Satisfied when` bullet it advances, not just the requirement. One
recorded with **no** goal open names neither, because there is nothing to
name.

## Scope

- `ci` reds an unsupervised branch that ADDS a file under `docs/product/`.
  Supervised is untouched: writing requirements is what a human-attended
  session does with a human.
- The guard reads the DIFF against the merge base, never the tree.
- A generated plan names the bullet it advances **when it serves a
  requirement**. Decide the spelling — frontmatter field or required section
  — and lint it only in that case. Prefer the one that rots visibly in a
  diff.

## Out of scope

- **Blocking a plan that serves no requirement.** That was this plan's
  original purpose and it is now the opposite of the rule. Recording is
  always allowed; a plan with no `requirement:` is a note for a human, and
  `ci` must not stop it being written.
- **EDITING a requirement, as distinct from adding one.** An unsupervised
  session annotating a `Satisfied when` bullet with a measured result is what
  PR 163 did and it is useful. Adding a NEW goal is the circularity; decide
  deliberately whether an edit is caught, and say which you chose and why.
- Requiring the bullet on plans a HUMAN writes. The bullet is about what an
  unsupervised session generates; a gate that fires on a human writing a plan
  by hand is one they route around.
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
- The guard must not stop a session RECORDING work. It is about
  `docs/product/`, not `docs/plans/`, and the two were one sentence until
  2026-08-31.
- A plan naming a bullet by quoting it goes stale silently when the bullet is
  reworded. Naming by index rots the same way when a bullet is inserted.
  Pick deliberately and say which failure you accepted.
