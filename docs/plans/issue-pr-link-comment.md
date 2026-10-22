---
plan: issue-pr-link-comment
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/manage.md, .claude/commands/clerk.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

The repo owner wants every issue to show, as a comment, each pull request
that works on it (asked in session 2026-10-22: "always link the PRs in the
issues as comments"). Today the link exists only as GitHub's timeline
cross-reference from a `Closes #N` / `Refs #N` line in a pull request body,
which is easy to miss, and a clerk HOLDS verdict posts no comment at all
(`.claude/commands/clerk.md` §3). After this plan: the manager comments on
every issue its pull request body names, and the clerk's comments name the
plan-only pull request that carries the plan.

## Scope

- `.claude/commands/manage.md` — after the paragraph that starts "Plan
  names `issue: N`? Body carries `Closes #N`", add one paragraph **Link the
  issue**:
  - Right after the pull request opens: for EACH issue number the body names
    with `Closes #N` or `Refs #N` (the plan's issue, a human-remainder issue,
    any other), post ONE comment on that issue (`add_issue_comment`):
    `PR #<M> <what it does for this issue, one line>: <PR url>`, ending with
    the attribution footer the session's system prompt names.
  - One comment per issue per pull request. Never edit the issue's body or
    labels for it.
  - The comment fails: name the failed call in your final report line; do
    NOT block or retry, the `Closes`/`Refs` line still links it.
- `.claude/commands/clerk.md` §3 and §4:
  - §3: post the verdict comments AFTER the pull request opens (§4) when the
    pass writes any plan; a pass with no plan posts them as today.
  - §3 **HOLDS**: gains a comment, `clerk: HOLDS — plan <stem> in PR #<M>`.
    **NARROWER**: its existing comment also names `PR #<M>`.
  - Keep "One comment per issue per pass" true.
  - §4 report line also counts the link comments.
- `.agents/harness/selftest/orchestrated.sh` — `expect` cases on `$mgrtext`
  for the substrings `Link the issue` and `post ONE comment on that issue`;
  read `.claude/commands/clerk.md` from the checkout the same way `$mgrtext`
  is read and add `expect` cases for `clerk: HOLDS — plan` and
  `AFTER the pull request opens`. Each must FAIL on `main` before the
  command-file change.

## Out of scope

- Any `joharness.sh` code: posting is the session's GitHub tool call, not a
  harness command.
- Back-filling comments on closed or already-linked issues.
- Comments from scout, conduct, curate or orchestrator roles.
- Changing the clerk's skip rules (§2). A footed comment already does not
  count there, so the manager's link comment changes no clerk decision.
- Core paths (`./joharness.sh protocol-paths`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `grep -c "Link the issue" .claude/commands/manage.md` — `1`.
- `grep -c "clerk: HOLDS — plan" .claude/commands/clerk.md` — `1`.
- The new `expect` cases are red with the two command-file hunks reverted;
  record the red lines in the workstream file's `## Review`.
- This plan's own PR follows the new rule by hand: it names no issue, so it
  posts none — say so in the PR body.
- Plan `ci` calls SHIPS: both command files and the selftest reach every
  consumer at its next sync; the selftest runs in each consumer's `ci`.

## Where to look

- `.claude/commands/manage.md` "Plan names `issue: N`?" paragraph — where
  the body's `Closes`/`Refs` line is decided.
- `.claude/commands/manage.md` "A remainder only a human can build"
  paragraph — the remainder issue whose PR says `Refs #N`.
- `.claude/commands/clerk.md` §2 skip list — footed comments do not count;
  §3 verdict list; §4 pull request and report line.
- `.agents/harness/selftest/orchestrated.sh` — `mgrtext="$(cat "$mgrmd")"`
  and the `expect … "$mgrtext"` block.

## Traps

- Plan `manager-defect-issue` also edits `.claude/commands/manage.md` and
  `.agents/harness/selftest/orchestrated.sh`; whichever lands second merges
  `origin/main` in and keeps both paragraphs and both test blocks.
- NEVER skip, disable or quarantine a test; existing `$mgrtext` pins stay
  green.
- No issue-body or label edits (`.claude/commands/clerk.md` Never list).
- Docs state status quo: no dates or "previously" prose in the command
  files (`.agents/docs/caveman.md`).
