---
plan: defect-block-resumes
urgency: normal
agent: opus
effort: high
needs: none
requirement: defect-to-fix-loop
issue: none
scope: shared:joharness.sh, .claude/commands/manage.md, shared:.claude/commands/clerk.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/orchestrate-reference.md
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 1. Today a manager whose
blocker is agent-fixable work outside its plan's scope has only the human
reasons of manage.md §3. In gx, `ui-adapt-verify` blocked
`product: … audit.mjs red on main (issue #806)`, labelled #806
`human-review` (manage.md §3 says to), and the clerk then skipped #806
(clerk §2, `held: human-review`). The fix waited on a human typing "can we
fix". The block was valid by the rules and wrong by the requirement.

## Scope

- **A new block reason, `defect:`** — `next:` = `defect: #<issue>: <one
  line>`. Added to `joharness.sh:block_reason_ok` and every list that
  spells the reasons (manage.md §3, orchestrated.md "The one stop",
  glossary if it names them). Unlike the others it names agent work: the
  manager files the issue (`issue_write` create; title `defect: <what is
  red>`, body = the failing command, its output, the commit it reproduced
  on), applies NO `human-review`, pushes `status: blocked`, exits.
- **manage.md §3**: when to use `defect:`, and that `product:` is not for
  a defect. One rule line names the test: "a session with this repo's
  tools could fix it, and your plan's Out of scope forbids it".
- **dispatch**: a `defect:` block is listed as `WAITING #<n>`, not BLOCKED.
  It is not pushed to the human (no `PushNotification`, no `notified=`) and
  holds no slot. Dispatch prints `RESUME <item>` once a plan whose
  `issue:` is `<n>` has existed on the base branch and is gone from it
  (retired). That is a git-only read: harness commands never call GitHub.
  The orchestrator spawns a manager for a RESUME item as for a STALL
  respawn: same branch, `next:` read from git, counted. A defect issue no
  plan names after the clerk's next pass is still `WAITING`, and dispatch
  says so.
- **clerk.md §3**: an issue titled `defect:` is planned `urgency: urgent`.
  Its author gate, scout gate and `human-review` skip are unchanged.
- **Tests** in the harness selftest: `block_reason_ok` accepts `defect:`;
  dispatch prints WAITING for a `defect:` block whose issue no plan names,
  and RESUME after a plan with that `issue:` is added and retired. Each test
  must fail without the change.

## Out of scope

- Fixing the defect from the blocked manager's own session (one item per
  session).
- Any GitHub API read from a harness command (closed-issue polling).
- The escape analysis inside the fix plan (`defect-escape-acceptance`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`, the new selftests listed.
- `./joharness.sh verify` — `0 failed`.
- A fixture branch with `status: blocked`, `next: defect: #9: x`: `dispatch`
  prints `WAITING #9`, no `INVALID BLOCK?`, and no notify line. After a
  commit adding then deleting `docs/plans/fix-9.md` with `issue: 9`, it
  prints `RESUME`.
- Consumer side, after the sync reaches chrsctl/gx: `./joharness.sh
  dispatch` there parses a `defect:` block as `WAITING`, and gx's
  `run-all.sh` and `./joharness.sh ci` stay green.

## Where to look

- `joharness.sh:block_reason_ok`, `joharness.sh:cmd_dispatch` (the
  BLOCKED / STALL? rows), `joharness.sh:dispatch_branch_plans`.
- `.claude/commands/manage.md` §3, `.claude/commands/clerk.md` §2–§3.
- `.agents/docs/orchestrated.md` "The one stop", the respawn table.

## Traps

- A `defect:` block must never carry `human-review`: that label stops the
  clerk, which is the defect this plan exists for.
- RESUME reads a retirement, not an issue state: a plan deleted unmerged on
  a branch is not a retirement on the base branch.
