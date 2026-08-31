---
plan: unsupervised-goal-lifecycle
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
scope: joharness.sh, .agents/harness/selftest
---

## Goal

The goal bound adopted in PR 169 adds two `Satisfied when` bullets that
nothing implements, and both are about where the fleet STOPS:

> An unsupervised session at the queue edge with no open requirement stops
> and asks, exactly as a supervised one does, and says the goal is reached
> rather than going quiet.

> When every `Satisfied when` bullet of a requirement reads true, the next
> unsupervised session deletes the requirement file rather than inventing
> more work against it.

Today `cmd_drain`'s unsupervised branch defers to the source sweep whether or
not a requirement is open, so with every goal satisfied the fleet would keep
generating work against nothing — the failure the bound exists to prevent.

## Scope

- `drain` under unsupervised, at the edge: if no requirement file is open,
  stop and say the goal is reached. Distinct wording from the dry-sweep stop,
  because they are different facts and a reader acts on which one fired.
- `sources`' stop condition gains the goal as a stated part, the same way
  PR 160 made the other four explicit. An uncountable or absent part must
  never read as satisfied.
- Deleting the requirement is the SESSION's action, not the command's.
  `sources` reports; it does not act — its own banner says so. What this
  plan adds is the report that makes the action obvious.

## Out of scope

- **Deciding whether a bullet "reads true".** That is a judgment and the
  requirement is the human's. The harness can report which bullets open plans
  cite; it cannot mark one satisfied. A rubric scoring bullets was already
  rejected on the goal branch — "a second definition of done competing with
  the requirement's own".
- Supervised behaviour. It already stops at the edge and asks; this must be
  byte-identical there, which is a `Satisfied when` bullet of its own.

## Acceptance

```
./joharness.sh drain            # supervised output unchanged
./joharness.sh mode unsupervised
./joharness.sh drain            # with a requirement open: defers to the sweep
                                # with none open: stops, names the goal reached
./joharness.sh mode default
bash .agents/harness/selftest.sh   # 0 failed
```

Cases for both unsupervised branches, and each must red under
`./joharness.sh mutate` when its branch is disabled.

## Where to look

- `joharness.sh:cmd_drain` — the unsupervised branch that currently defers
  unconditionally.
- `joharness.sh:src_stop_condition` — the four parts and the CANNOT COUNT
  discipline to copy.
- `.agents/harness/queue-context.sh` — how requirements are found, and the
  `unplanned` split, which is not the same question as "open".

## Traps

- An absent `docs/product/` and a directory of satisfied requirements are
  different facts. Absent is not "goal reached" any more than absent is empty
  — the queue part of the stop condition already learned this once.
- The dry-sweep stop and the goal-reached stop must not share a message. A
  session that cannot tell them apart cannot tell the human which happened.
