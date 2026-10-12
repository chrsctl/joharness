---
plan: human-review-label
urgency: normal
agent: sonnet
effort: xhigh
needs: none
requirement: none
issue: none
scope: shared:.agents/harness/AGENTS.md, shared:.claude/commands/manage.md, shared:.claude/commands/clerk.md, shared:.agents/docs/orchestrated.md, shared:.claude/skills/steward/SKILL.md
---

## Goal

The requester asked on 2026-10-12 for one GitHub label that marks an issue or
pull request as waiting on a human. Today a block shows only in a workstream
file's `status: blocked` on a branch, and nothing on GitHub tells a human
"this one needs you". A human has no way to hold an item either: they can
only veto after merge. The requester settled the design: label `human-review`,
used in both directions.
- An agent applies it when it blocks on a human.
- A human applies it to hold an item.
- While it is on an issue, the clerk does not plan that issue.
- While it is on a pull request, no session merges that pull request.
- Only a human removes it. No session removes it, under any circumstances.

## Scope

- **`.agents/harness/AGENTS.md` step 7.** Add one merge condition: the pull
  request does not carry the label `human-review` (read its labels at merge
  time, `pull_request_read` `get`). Under "Decide alone", the Block bullet
  gains: a block also applies `human-review` to the open pull request of this
  branch and to the plan's `issue:` when set; a session never removes the
  label. Caveman style, every line loads into every session. Keep the
  addition to at most 4 lines.
- **`.claude/commands/manage.md`.** In §3, the blocked bullet: before
  `status: blocked` is pushed, apply `human-review` with `issue_write`
  (method `update`, labels = existing labels plus `human-review`). Apply it to
  the branch's open pull request, if any, and to the plan's `issue: N`, if set.
  `issue_write` fails = say so in `next:` after the question, still push, still
  exit. In §4 Finish, add: the pull request carries `human-review` = do not
  merge. Set `status: blocked`, `next:` = `product: human-review label on PR
  #<n>`, push, exit. In `## Never`, add: remove `human-review` from any issue
  or pull request.
- **`.claude/commands/clerk.md`.**
  - §2 skip list: add an issue that carries the label `human-review`. It is
    skipped and does not count toward the batch. Its report line says
    `held: human-review`.
  - The HUMAN verdict, including the author-gate HUMAN: after the verdict
    comment, apply `human-review` to the issue.
  - `## Never`: the "edit an issue's labels" line gains a second carve-out:
    add `human-review` alongside a HUMAN verdict. Never remove it.
- **`.agents/docs/orchestrated.md` `## Bounds`.** Add one bullet defining the
  label. Name who applies it (an agent on a block, or a human to hold), what it
  stops (clerk planning an issue, any merge of a pull request), and that only a
  human removes it. This is the one definition; the other files point here.
- **`.claude/skills/steward/SKILL.md` `## At merge`.** Add one line: a pull
  request carrying `human-review` is not merged. This applies even when every
  step 7 condition holds. Point to `.agents/docs/orchestrated.md` Bounds.

## Out of scope

- Creating the label by a script, a workflow, or a labels file under
  `.github/`. `.github` is a core path. `issue_write` with an unknown label
  creates it on first use. A human may pre-create it with a colour.
- A `joharness.sh finish` or `dispatch` check that reads GitHub labels. Today
  `finish` reads no GitHub state (`joharness.sh:cmd_finish`). Adding a GitHub
  reader to it is its own plan.
- A glossary row. `human-review` has one spelling today, and
  `.agents/docs/glossary.md` holds contested terms only.
- Any change to the scout `approved` / `scout` labels (`scout-approval-gate`).
- Removing `human-review` anywhere, by any role.
- The orchestrator: it merges nothing and reads only `dispatch`, so it needs
  no rule.

## Acceptance

- `grep -c 'human-review' .agents/harness/AGENTS.md` — at least `2`.
- `grep -c 'human-review' .claude/commands/manage.md` — at least `3`.
- `awk '/^## Never/,0' .claude/commands/manage.md | grep -c 'human-review'` — at least `1`.
- `grep -c 'human-review' .claude/commands/clerk.md` — at least `3`.
- `awk '/^## Never/,0' .claude/commands/clerk.md | grep -c 'human-review'` — at least `1`.
- `awk '/^## Bounds/,/^### Bounds, orchestrator/' .agents/docs/orchestrated.md | grep -c 'human-review'` — at least `1`.
- `grep -c 'human-review' .claude/skills/steward/SKILL.md` — at least `1`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan `ci` calls SHIPS (`.claude/commands/`, `.agents/harness/`,
  `.agents/docs/`). After a consumer syncs, run
  `grep -l human-review .claude/commands/clerk.md .claude/commands/manage.md .agents/harness/AGENTS.md`
  on that consumer. It lists all three files.

## Where to look

- `.agents/harness/AGENTS.md` — Loop step 7 merge conditions list and
  `## Decide alone` Block bullet.
- `.claude/commands/manage.md` — `## 3. The contract with the orchestrator`
  (blocked bullet), `## 4. Finish`, `## Never`.
- `.claude/commands/clerk.md` — `## 2. Read` skip list, `## 3. Verify, then
  decide` HUMAN verdict, `## Never` labels line.
- `.agents/docs/orchestrated.md` — `## Bounds`.
- `.claude/skills/steward/SKILL.md` — `## At merge`.
- `docs/plans/scout-proposes-on-issues.md` — confirms `issue_write` with an
  unknown label creates it.

## Traps

- Edit no core path (`./joharness.sh protocol-paths`): no `.github/` labels
  file and no workflow.
- `.agents/harness/AGENTS.md` loads into every session. Caveman rules only,
  and the reason goes in `.agents/docs/orchestrated.md`
  (`.agents/docs/caveman.md`).
- One definition. The other files point to the Bounds bullet instead of
  restating it.
- A session never waits in session for the human to remove the label. Block,
  push, exit.
- Other plans touch the same files:
  - `.claude/commands/clerk.md`: `scout-approval-gate`,
    `clerk-cycle-reads-what-a-clerk-leaves`, `role-session-standard-lines`.
  - `.claude/commands/manage.md`: `scout-approval-gate`, `free-branch-plans`,
    `retired-stems-ledger`.
  - `.agents/docs/orchestrated.md`: most open plans.

  Every one marks these paths `shared:`, so expect a reconcile merge.
