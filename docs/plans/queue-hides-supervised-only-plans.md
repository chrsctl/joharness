---
plan: queue-hides-supervised-only-plans
urgency: urgent
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
advances: Started once, the fleet keeps going for hours with no human turn
scope: .agents/harness/queue-context.sh, joharness.sh, .agents/harness/selftest
---

## Goal

The endurance retry of 2026-08-31 spent **55 minutes and $12.05** on a plan
an unsupervised session could never finish, and every fact needed to know
that was already in the tree.

`docs/plans/marker-gate-needs-no-done.md` declares:

```
scope: joharness.sh, .agents/harness/selftest
```

Both are protocol paths (`./joharness.sh protocol-paths`). The requirement's
Constraints put protocol text off limits to a session running unattended. So
the plan was undoable by that fleet **before it was dispatched**, and the
queue offered it as the top free item anyway.

The session behaved correctly at every step: it ran `authority`, claimed by
pushing, implemented the fix, tested it green, ran `code-review --high`,
then reverted its own protocol-path edits, wrote the full design into its
workstream file, marked itself `blocked` and handed off. The boundary held.
**Nothing upstream of it looked.**

## Scope

- `queue-context.sh` marks a plan whose declared `scope:` is entirely
  protocol paths as **SUPERVISED ONLY**, and in unsupervised mode does not
  offer it as the top free item.
- `drain` says the same thing when it names the next item, since a session
  re-reads `drain` between items rather than remembering the hook.
- The list of protocol paths comes from `protocol_paths()`, never a second
  copy — that is the defect issue #114 already paid for.

## Out of scope

- Blocking the session from taking it anyway. A human-directed session may
  legitimately work such a plan supervised; this marks and de-ranks, it does
  not forbid.
- Changing the boundary itself, or what counts as protocol text.
- Guessing scope for a plan that declares none — see Traps.

## Traps

- **A plan with no `scope:` is UNKNOWN, never "safe".** Absent is not
  empty, the rule this repo keeps relearning. An undeclared scope must not
  read as "contains no protocol paths".
- **Partial overlap is not the same case.** A plan touching one protocol
  file and three others is not undoable — the session can do the rest and
  record the remainder. Only an ENTIRELY protocol-path scope is
  disqualifying, and the distinction has to survive in the code.
- Do not mark on path *prefix* alone without matching how
  `protocol_paths()` entries are compared elsewhere, or `joharness.shX`
  style near-misses decide a dispatch.

## Acceptance

- A plan scoped entirely to protocol paths is marked SUPERVISED ONLY in the
  queue and is not the top free item in unsupervised mode.
- The same plan is unchanged in supervised mode.
- A plan with mixed scope is not marked.
- A plan with no `scope:` is not silently treated as clean.
- Cases for each, and `mutate` reds them.
