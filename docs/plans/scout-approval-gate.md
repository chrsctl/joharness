---
plan: scout-approval-gate
urgency: normal
agent: opus
effort: xhigh
needs: scout-backlog-clock
requirement: scout-market-research
issue: none
scope: shared:.claude/commands/clerk.md, shared:.claude/commands/manage.md, shared:.agents/docs/orchestrated.md
---

## Goal

A scout proposal reaches plans ONLY after a human applies the label
`approved` to its issue, and everything that comes from it is marked apart
at a glance (`docs/product/scout-market-research.md`: Approval gate, After
approval, Distinguishable, Constraints). The existing path into plans is the
clerk, which today takes any open issue by a maintainer. This plan adds the
gate to the clerk, and the `scout:` title prefix plus `scout` label to the
plan-only pull request and to every build pull request a manager opens for
such a plan.

## Scope

- `.claude/commands/clerk.md` — §2, a new gate before the author gate, "The scout gate": an issue carrying the label `scout` is a scout proposal (title `scout:`) or a research request (no prefix). A request is never taken. A proposal is taken only when ALL hold, else skipped and not counted toward the batch, with the reason in the report:
  1. its labels include `approved` (`issue_read`, `get_labels`);
  2. the issue's event log shows `approved` applied by the login `./joharness.sh scout` prints on its `reviewer  :` line, and that event is newer than the proposal's last revision — the scout's last comment on the issue (`issue_read`, `get_comments`; every revision ends in one comment, `scout-proposes-on-issues` §5). The issue's `updated_at` is never the marker: the label event itself bumps it;
  3. the event log is readable. Readers, in order: a GitHub MCP tool whose schema offers the issue timeline or events (none on 2026-10-12: `issue_read` methods are get, get_comments, get_sub_issues, get_parent, get_labels); else `gh api repos/<owner>/<repo>/issues/<n>/timeline --paginate` when `gh auth status` succeeds. Neither = `APPROVAL UNREADABLE`: take no scout proposal this pass, say which reader was missing, and nothing else; never fall back to "the label is there".
  A `reviewer  : none` line = no scout proposal is taken, the report says the conf names no reviewer. The gate sits before the footer rule and the author gate of §2 as merged on 2026-10-12 (footed comments do not count; a maintainer's own comment reopens): the scout's comments carry the attribution footer, so they never reopen a clerk verdict, and the gate reads them only as the revision marker above.
  §3: a taken proposal's plan carries `issue: <N>` as any plan; the clerk's verdict comment still opens `clerk: <VERDICT>`. §4: a pull request whose plans include one from a scout proposal has title `scout: plan <stems>` and the label `scout` (`issue_write` update on the pull request number, labels). A closed scout issue is declined: the clerk never plans it, whatever its labels. `## Never` gains one line: apply, remove or ask to skip `approved` on any issue.
- `.claude/commands/manage.md` — §4 Finish, beside the `Closes #N` rule: the plan names `issue: N` and that issue's labels (`issue_read`, `get_labels`) include `scout` = the pull request title starts `scout: ` and carries the label `scout`; a follow-up plan-only pull request for such work too. One read, at pull request time; nothing in the plan file marks it.
- `.agents/docs/orchestrated.md` — "Bounds": "Nothing is invented at the edge" gains the sentence: a scout proposal enters as an issue and becomes a plan only through the clerk after the reviewer's `approved` label event; closing the issue declines it. The clerk row of Roles: "never plans a scout issue without the reviewer's approval event".

## Out of scope

- The scout role (`.claude/commands/scout.md`) — `scout-proposes-on-issues`; this plan and that one run in parallel, disjoint files.
- A reader of the event log inside `joharness.sh`: the harness reads git only.
- A new plan frontmatter key marking scout origin. The issue's label is the one mark; every pull request derives from it at open time.
- Applying, removing or creating the `approved` label anywhere. A session that does has invented work.
- Approval by comment, by reaction, by the issue author's write access, or by any identity check: the label event after the last revision is the gate, nothing weaker.

## Acceptance

- `grep -n 'APPROVAL UNREADABLE' .claude/commands/clerk.md | wc -l` — at least `1`.
- `grep -n -E 'timeline|event log' .claude/commands/clerk.md | wc -l` — at least `2`.
- `grep -n 'scout: plan' .claude/commands/clerk.md | wc -l` — at least `1`.
- `grep -n -E "scout: |label .scout." .claude/commands/manage.md | wc -l` — at least `2`.
- `awk '/^## Never/,0' .claude/commands/clerk.md | grep -c 'approved'` — at least `1` (the Never list names the label).
- `./joharness.sh ci` — `ci: pass`. `./joharness.sh verify` — `0 failed`.
- SHIPS (`.claude/commands/`, `.agents/docs/`): on a consumer after sync, a clerk pass with a `scout`-labelled open issue and no timeline reader reports `APPROVAL UNREADABLE` and writes no plan for it; its report line is grep-able in the pull request body or the session's report.

## Where to look

- `.claude/commands/clerk.md` — §2 Read (the author gate's shape and the skip list), §3 HOLDS, §4 Pull request.
- `.claude/commands/manage.md` — §4 Finish, the `Closes #N` / `Refs #N` rule.
- `.agents/docs/orchestrated.md` — Bounds, "Nothing is invented at the edge"; Roles, the clerk row.
- `joharness.sh:scout_reviewer` — the reviewer line the clerk reads (added by `scout-backlog-clock`).
- `joharness.sh:scout_automerge` — why a key is read from the base branch, not the working tree.

## Traps

- The scout may post under the reviewer's own identity: a login match proves nothing; only the `labeled` event by the reviewer after the last revision does.
- Fail closed: unreadable event log = nothing planned, said once in the report. A silent pass invents nothing; a pass that plans on a label alone does.
- Never apply, remove or ask to skip `approved`; never close or reopen a scout issue.
- Core paths untouched (`./joharness.sh protocol-paths`); `JOHARNESS_SCOUT_REVIEWER` is set by the human in conf.
- `.claude/commands/clerk.md` and `manage.md` are `shared:` with open plans (`clerk-cycle-reads-what-a-clerk-leaves`, `role-session-standard-lines`, `retired-stems-ledger`, `free-branch-plans`): merge `origin/main` in before the pull request; keep their edits, add yours.
- Command files ship to consumers: no name of this repository, no `gx` in the rule text.
