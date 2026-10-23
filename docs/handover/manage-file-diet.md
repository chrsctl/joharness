---
workstream: manage-file-diet
status: done
branch: claude/manage-file-diet
pr: none
plan: manage-file-diet
issue: none
session: https://claude.ai/code/session_01Vgabenkn9wouDYWpydWeNe
agent: opus
updated: 2026-10-23
next: PR open, merge after finish
---

## Goal

Cut `.claude/commands/manage.md` to 10,000 bytes or less without changing
behaviour: rare branches move verbatim to `.agents/docs/manage-reference.md`
behind pointer lines, as role-file-diet did for `orchestrate.md`.

## Decisions

- Nine moves, built by a script (exact substrings, pointer in place, rebuild
  check byte for byte): Carried plan, Free, Human remainder, Surveyor,
  Carried plan at retire, Plan issue, Link the issue, Lead, Defect.
- Kept in place: GitHub lost at step 7 (its before-retire read runs on every
  item; `github: GitHub MCP lost` is pinned in manage.md), the plan-only
  follow-up sentence (not issue-bound), the rescope conflict and upstream
  paragraphs (small; every item can hit them), R's `free` parenthetical and
  its `$ARGUMENTS` sentence (the reference gets no substitution).
- Pointers keep each branch's trigger text in manage.md and move only what
  follows it.

## Rejected

- Pointers repeating the trigger sentence in full (Carried plan, Human
  remainder): sum 17,144 bytes, 5.6% over the original; past the 5% bound.

## Review

- r1: (verifier) the manage.md pointer check passed a pointer whose longer section was deleted (`ref § Carried plan at retire.` read as `Carried plan`) (fixed: a manage.md pointer's name must end at a period; the block run alone on a reference without that section fails with the fix, passes silent without it, 2026-10-23)
- r2: (verifier) swapping `ref § <name>.` back does not rebuild the old file at three pointers (no change: the rebuild swaps each whole pointer string, trigger words included, for its section; that check is byte-identical, 16234 bytes, re-run after r3)
- r3: (verifier) Lead pointer's trigger narrower than its rule: leads about an issue, a merged item or the harness also route there (fixed: pointer names them)
- r4: (verifier) bound 9248 + a tenth allows 10,172 bytes, past the plan's 10,000 (wontfix: the plan's Scope sets the bound at counted size plus a tenth)
- r5: (verifier) `## Lead` says "the next paragraph" for the defect route, now the next section (no change: `## Defect` follows `## Lead`, and the pointer for it sits right below in manage.md)
- r6: moved sections and pointers: Carried plan (§0 item 2, plan on another branch), Free (§0 item 3, `free <branch>`), Human remainder (§2, a core-path remainder), Surveyor (§R), Carried plan at retire (§4), Plan issue (§4, `issue: N`), Link the issue (§4, body names Closes/Refs), Lead (§4), Defect (§4, a failure not the item's) (no change)
- r7: sizes, `wc -c` 2026-10-23: manage.md 16234 -> 9248; plus reference 7743 = 16991 (+4.7%). INFO manager reading set: 71237 bytes on origin/main (summed by hand, same six files), 64251 after (`wc -c` sum of the same six files on this branch, 2026-10-23); ci pass and verify 6 passed, 0 failed on the branch head before the base merge (no change)

## Blockers

None.

## Where to look

- `docs/plans/manage-file-diet.md` — the plan.
