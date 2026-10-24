---
requirement: halt-and-hold
priority: normal
---

## Goal

Requester (repository owner), 2026-10-24, in a chrsctl/gx orchestrator
session: *"Can we add to joharness a mechanism to halt an already taken item
and put it back and deprioritize behind other items without locking a
spot"*. The requester then agreed the gap is narrower than that, because
plans already have `needs:`. Two gaps remain, both measured in gx on
2026-10-24 and checked against this repo's code:

1. **Halting a live claim when a human orders it.** `status: abandoned`
   releases a claim, but only `./joharness.sh janitor --apply` writes it.
   It releases only claims idle longer than `HANDOVER_STALE_SECONDS`
   (518400 s by default) that are not `blocked` and carry no `pr:`. Any
   other claim gets `not a candidate (pushed recently …)`, even when its
   session is already ARCHIVED. In gx a human stopped a planning manager
   three minutes after it started. The harness had no way to release its
   claim, so an orchestrator typed `status: abandoned` into the workstream
   file by hand.
2. **Holding an unplanned requirement behind other work without taking a
   slot.** Only plan frontmatter has `needs:`. A requirement has only
   `requirement` and `priority` (`normal` | `urgent`), so it cannot say
   that the human wants it built only after another item lands. In gx the
   orchestrator used its own ledger key instead (`humanhold=<stem>`), which
   dispatch does not know.

## Satisfied when

All of these can be measured in `./joharness.sh dispatch` output:

- A claim a human orders halted, at any age, with or without an open pull
  request, can be released through a harness command instead of a hand
  edit. After that its item holds no slot, and dispatch never offers that
  branch to be respawned.
- A halted item comes back to the queue and is offered again, unless it
  is also held.
- An unplanned requirement can be held, or deferred behind another item.
  While held it is not offered and holds no slot. Once the condition
  clears, it is offered again without a further edit.
- The hold or the halt is recorded in git, not in an orchestrator's
  ledger. Harness commands still never call the GitHub API.

## Constraints

- The mechanism is the planner's choice: these clauses fix outcomes, not
  field names or commands.
- Claims nobody halted keep today's janitor safety rules (proof that the
  session is gone, the age gate, the guard and its lease).
- No core path edit (`./joharness.sh protocol-paths`) without a
  `human/<stem>` pull request.
