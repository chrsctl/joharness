---
workstream: orchestrator-edge-slot-leak
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: orchestrator-edge-slot-leak
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-07
next: Retire this file and the plan as the last commit before the pull request
---

## Goal

The in-flight count I merged in PR #225 holds a slot for every unmerged branch
past its retire commit. In the consumer it landed in there are five such
branches, 70h to 613h old, none of them a merge in flight — zero open pull
requests in that repository, every item already merged by another route. Cap
4, five leftovers, so `slots : 0 of 4 free` permanently: nothing spawnable,
and the verdict can never read DRAINED.

The plan that asked for the count named this exact risk and I shipped it
anyway ("must still be distinguishable from a genuinely abandoned branch, or
this trades a duplicate-spawn defect for a slot that never frees"). The trade
got made and it went the wrong way: a duplicate costs one manager, this costs
every manager the queue would ever have spawned.

## Decisions

- **The discriminator is the item's presence on the base branch**, one
  `git cat-file -e`. Step 7 deletes the plan file on the BRANCH; the base
  keeps its copy until that merge lands. Present = mid-merge, hold the slot.
  Absent = the merge already happened, by this branch or another, and what is
  left commits nothing. The comment claiming "the difference is not in git"
  was wrong for every row that names an item, and is rewritten rather than
  left standing beside the new check.
- **Never the forge, never push age.** A network and a credential under the
  queue's core read is a different harness; and age cannot separate a quiet
  manager with a live pull request from a leftover pushed ten minutes ago,
  which is exactly the pair that must not be confused.
- **A leftover is REPORTED, not silently dropped.** It gets its own block and
  a row naming the human as the one who clears it, because a branch nobody
  will merge is still litter somebody has to sweep, and because the plan's
  objection to the old behaviour was silence, not the count itself.
- **The `?` row** — no item, so the question cannot be asked — keeps its slot
  while it is fresh and becomes a leftover past the stall window. One rule,
  said in the row. Fresh, it may be a manager that retired minutes ago; past
  the window there is nothing left to cross-check, since the row carries
  neither item nor session line, and a slot held on no evidence is the leak
  this fix exists to end.
- **The verdict tells the two zeroes apart.** "0 slots, N managers working" is
  a fleet at capacity; "0 slots, N leftovers" is a fleet that has stopped.
  They printed the same line, which is how an orchestrator ended up reading
  `0 of 4 free` with no way to act.

## Rejected

- **Reverting the count.** The undercount it fixed was measured on 11 of 28
  passes in the same run. This is a missing discriminator, not a wrong idea.
- **Deleting the branches.** A session never `git push --delete`. The row
  tells the human.

## Review

One `verifier` pass at opus, fourteen findings. Three would have shipped a
defect of the same family as the one being fixed.

- r1: (verifier, correctness) `for cand in $items` was an UNQUOTED expansion,
  so a plan path holding `*`, `?` or `[` — legal in git, legal under the
  queue hook's own row pattern — globbed against the caller's working
  directory and the slot was decided from a DIFFERENT file. Both directions
  reproduced: `docs/plans/x[y].md`, absent from the base, matched a present
  `xy.md` and held its slot forever, which is precisely this defect; and an
  untracked `ab.md` beside the caller made a real mid-merge read as a
  leftover. Direct descendant of PR225 r13, which fixed this field for spaces
  only. shellcheck does not flag a `for` list. (fixed: a newline list read
  with `while IFS= read -r`; the `x[y].md` fixture reds 2 cases without it.)
- r2: (verifier, correctness) the swept-record fallback bypassed the space
  filter the deleted-item scan applies, so half a path reached the row — and
  post-fix half a path would have decided a slot. (fixed: same filter on that
  arm; `mgr-spacey` pins it, and the row prints `?` rather than
  `docs/plans/foo`.)
- r3: (verifier, test) the `?`-past-window rule — the plan's whole second
  Scope bullet — was pinned by ZERO cases: `mutate` on that line said NOTHING
  REDDED. (fixed: `mgr-sweep` asserted both sides, walked across the
  threshold with `JOHARNESS_STALL_MINUTES=0` rather than by waiting a day.)
- r4: (verifier, correctness) the threshold was ONE stall window, and that
  knob is p95 of the gap between commits on a LIVE branch. A branch at step 7
  pushes nothing while it waits for checks, so a legitimate sweep branch with
  an open pull request became litter 46 minutes after its last push — and
  that silently reversed PR225 r6. (fixed: 24 windows, with the reasoning on
  the line; a day is past anything waiting explains, and the litter this aims
  at measured 613 hours.)
- r5: (verifier, docs) `.agents/docs/orchestrated.md` still said RESPAWN on a
  leftover — for the plan's own example branch — and still carried the
  sentence the plan ordered rewritten ("From git that row cannot be told
  apart…"). (fixed: a `leftover` row in that table, and the paragraph now
  says the discriminator is the item and the control plane decides only what
  to do about the session.)
- r6: (verifier, dead code) the `STOPPED` verdict could never fire: once a
  leftover holds no slot, 0 slots means managers. I shipped it with a comment
  ADMITTING it was unreachable, which is PR225 r8 verbatim, one item later.
  (fixed: removed, with the reason kept where it was.)
- r7: (verifier, correctness) both leftover summaries asserted "their items
  already merged" over rows that name no item, and the `?` row in
  `orchestrate.md` sat above the leftover row, so a `?` leftover was routed
  to a row promising a slot it no longer holds. (fixed: the verdict counts
  the two kinds separately, the row says which it is, and the leftover row is
  read first.)
- r8: (verifier, residual) the item-PRESENT side never ages out, so a branch
  whose pull request was closed unmerged holds its slot forever. (wontfix
  here — the only signal that would expire it is push age, which this plan
  forbids for exactly this decision, and the item's presence is real evidence
  the merge has not landed. Recorded so the next reader has the case rather
  than rediscovering it.)
- r9: (verifier, docs) the function's contract comment still described two
  fields and claimed the slot is held either way. (fixed.)
- r10: (verifier, caveman) the consumer measurement written into four new
  places and none of them its owner — PR225 r9, same file, same rule, same
  count. (fixed: the code and the command file point at the plan and at Runs.)
- r11: (verifier, evidence) the record claimed a consumer-side run that had
  not happened: the clone was shallow, every merge base unreadable, and
  `dispatch` there reproduced nothing in either direction. (fixed by doing
  it — the clone is deepened for the six refs that matter and both builds are
  run in `gx`, above. Two of five branches are readable there, and the record
  says so rather than implying five.)
- r12: (verifier, output) leftover rows dropped the extra items a branch
  retired, where the in-flight row names them. (fixed.)
- r13: (verifier, output) the shallow-clone caveat printed under the
  `leftovers` header, where its two-space indent read as one more leftover.
  (fixed: it stays with the listing it belongs to.)
- r14: (verifier, docs) the `n_edge` verdict line still said the control
  plane decides whether the slot is real, contradicting the paragraph this
  change wrote one file over. (fixed: it now says the slot is held because
  the item is still on the base branch.)

## Consumer-side: `dispatch` run in the consumer, both builds

The plan's SHIPS bar is `./joharness.sh dispatch` in `chrsctl/gx`, not a
proxy for it. `gx` attached read-only, cloned, then deepened for `main` and
the five branches (`git fetch --depth=2000`) so merge bases are readable;
both builds run against that same checkout, 2026-09-07:

```bash
cp <this branch>/joharness.sh /home/user/gx/joh-new.sh
git -C <joharness> show origin/main:joharness.sh > /home/user/gx/joh-old.sh
cd /home/user/gx && JOHARNESS_MODE=orchestrated DISPATCH_FETCH=0 ./joh-old.sh dispatch
cd /home/user/gx && JOHARNESS_MODE=orchestrated DISPATCH_FETCH=0 ./joh-new.sh dispatch
```

| | pre-fix (`origin/main`) | post-fix (this branch) |
| --- | --- | --- |
| slots | `1 of 4 free` | **`3 of 4 free`** |
| `claude/continue-bzq5sk`, 621h, no item | `PR in flight, no claim file` — holds a slot | leftover, names no item, holds none |
| `claude/permission-system-…-0tke0t`, 78h | `PR in flight, no claim file` — holds a slot | leftover, its item gone from `main`, holds none |

Two of the plan's five, not five: this clone is deepened for six refs and
shallow for the rest, so 11 refs are unreadable and the listing says so. The
orchestrator that filed the plan read `0 of 4` on a full checkout. What is
shown here is the direction and the mechanism on the real branches — the two
that are readable both stop holding slots, and the two reasons print
separately.

The discriminator alone, checked against all five and not vacuous (52 plan
files on that branch, so `cat-file -e` finds one when it is there):

```bash
for i in eval-corpus-hardening permission-system-at-ten-thousand-seats \
         replay-age crm-change-review crm-revisions-ui; do
  git cat-file -e "refs/remotes/origin/main:docs/plans/${i}.md" 2>/dev/null &&
    echo "PRESENT (hold)" || echo "absent (leftover)"
done
```

**absent, all five.** What this does NOT show, because gx has zero open pull
requests: a genuine mid-merge branch there keeping its slot. That side is the
fixture's, asserted both ways.

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_retired_edges` — the `cat-file -e` and the three
  states it emits.
- `joharness.sh:cmd_dispatch` — the leftover rows, `n_leftover`, and the
  STOPPED verdict.
- `.claude/commands/orchestrate.md` — the health table's leftover row.
