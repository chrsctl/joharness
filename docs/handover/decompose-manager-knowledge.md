---
workstream: decompose-manager-knowledge
status: in-progress
branch: claude/decompose-manager-knowledge
pr: none
plan: none
issue: 258
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-10-07
next: Write the plan for what remains of #258, then verify, review, retire and merge
---

## Goal

`drain` named `docs/plans/unowned-block-age.md`, but Loop step 2 puts open
GitHub issues ahead of plans and `drain` does not read GitHub. Checked: of the
14 open issues, #249, #251, #254/#257, #267, #271 and #273 already have a plan
or an open question. The oldest with NO decomposition is **#258**
(2026-09-16), "A manager's closing report is three words — everything it
learned is discarded on success and delivered only on failure".

Nothing builds unplanned, so decomposing it IS this item.

## Decisions

- **Two of #258's three directions have already landed, and the plan says so
  rather than re-proposing them.** Every claim in an issue is a hypothesis
  until checked against current code; this one is three weeks and many merges
  old.
  - Option 1, widen the merge message → DONE, and precisely on the issue's
    sharpest point. `.claude/commands/manage.md` §4 now defines
    `lead <stem>: <text>`, explicitly for "what you learned about somebody
    ELSE's" files, with the stem required to be a queue item's name.
  - Option 2, make the loss visible at `finish` → DONE.
    `joharness.sh:6235-6237` prints "N finding(s) recorded on this branch stop
    existing when it retires" and "This diff promotes into M file(s)".
  - Option 3, give the findings a destination → OPEN. This is what the plan
    scopes.
- **The issue's central factual claim is now false, and that narrows it.** It
  says the findings are "written down properly and then destroyed on merge".
  They are not: `cmd_feedback` (`joharness.sh:3981`) serves findings out of
  merged history keyed by path. Verified by running
  `./joharness.sh feedback joharness.sh`, which returns findings from merged
  edges including `6b0a210`. So the loss is narrower than filed: what has no
  home is the finding that names no path this repo owns — `upstream` lists it
  as `unplaceable` and says in its own output that it "will not guess".
- **The destination is the requester's call, so the plan makes asking a gate.**
  Where a consumer's own-product findings should land is product direction,
  not implementation. The plan proposes one and requires ratification as an
  acceptance item — the pattern `docs/plans/name-no-consumer-says-both.md`
  already uses — rather than stopping with nothing written.

## Rejected

- **Implementing option 3 in this item.** Decompose IS the work (step 2). A
  session that decomposed and then built would be two items.
- **Closing #258 as done.** Two directions landed and the third did not; the
  issue's own summary calls option 3 "the real fix". Closing it would discard
  the part nobody has addressed.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_upstream` — where `unplaceable` is printed with no
  destination.
- `.claude/commands/manage.md` — §4, the `lead` line that closed option 1.
- `joharness.sh:cmd_feedback` — why "destroyed on merge" no longer holds.
