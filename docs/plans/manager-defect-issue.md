---
plan: manager-defect-issue
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 512
scope: .claude/commands/manage.md, .agents/harness/selftest/orchestrated.sh, .agents/docs/feedback.md
---

## Goal

A manager that finds a defect outside its own item (a failing test, a broken
command) today can only write it in its pull request body
(`.claude/commands/manage.md`, "A LEAD" paragraph). Nobody reads a merged
pull request body, so the defect is lost (issue #512: chrsctl/gx PR #795
found a failure on `origin/main`, and it was fixed only because a second
session ran into it). The repo owner's direction on #512: the PR body alone
does not count. Decided in session 2026-10-22, on the owner's instruction
("write"), taking the recommendation the owner was given: the manager files
ONE GitHub issue on its own repository, labelled `human-review`, at most one
per session. The label holds it from the clerk (`.claude/commands/clerk.md`
skip list, `held: human-review`) until the owner reads it and removes the
label; the clerk then plans it like any other issue. No defect becomes a
build without a human step.

## Scope

- `.claude/commands/manage.md` — after the "A LEAD" paragraph, add a
  paragraph **A DEFECT outside your item** saying, in this order:
  1. When: you found a failure that is not your item's, AND it reproduces on
     fresh-fetched `origin/main` (run the same command on a checkout of it;
     no reproduction = it is your branch's, fix it in your item).
  2. Search the repository's open issues for the same failing command or
     test name first. Found = do not file; name that issue in your pull
     request body (`Refs #N`).
  3. Otherwise ONE issue per session (`issue_write` `create`) on this
     repository, before the retire commit: title
     `defect: <test or command>: <symptom, one line>`; body = the command,
     at most 20 lines of its output, the `origin/main` sha it reproduced on,
     and your branch name; labels `human-review`. Pull request body says
     `Refs #N`, never `Closes #N`.
  4. A second defect in the same session: pull request body only, one line
     each.
  5. `issue_write` fails: put the issue text in the pull request body under
     a line `defect not filed: <error, 40 chars>`. Do NOT block or delay the
     item for it.
  6. Not for: harness defects found in a consumer (those go to canonical,
     `.agents/docs/feedback.md` §4) and core-path edits (the human-remainder
     paragraph above).
  - Change the "A LEAD" paragraph's fallback sentence so a stem-less lead
    that is a DEFECT points to the new paragraph; a stem-less lead that is
    not a defect still goes in the pull request body. Keep the exact
    substring `goes in your pull request body` (pinned by the selftest).
- `.agents/harness/selftest/orchestrated.sh` — next to the existing
  `expect "and where a lead with no stem goes instead"` case, add `expect`
  cases on `$mgrtext` for: `defect: <test or command>`, `labels
  \`human-review\``, `ONE issue per session`, and `reproduces on`. Each must
  FAIL on `main` before the manage.md change.
- `.agents/docs/feedback.md` "Where a consumer's OWN findings go" — keep the
  counting result, add: a defect found OUTSIDE the edge's own change has no
  fix path in that edge; it goes to a `defect:` issue on the consumer's repo
  (`.claude/commands/manage.md`, "A DEFECT"), held by `human-review` until
  the owner releases it to the clerk. Status quo only, no history
  (`.agents/docs/caveman.md`).

## Out of scope

- Any change to `.claude/commands/clerk.md`. The clerk already holds
  `human-review` issues and plans released ones; adding a `defect:` special
  case there is a second copy of the rule.
- Removing `human-review` automatically, or any session removing it. Only
  the owner does (`.agents/docs/orchestrated.md`, Bounds).
- A `joharness.sh` command or knob for the cap. One per session is prose,
  like the canonical-issue cap in `.agents/docs/feedback.md` §4.
- Filing defects on any repository but the session's own.
- Editing core paths (`./joharness.sh protocol-paths`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `grep -c "A DEFECT" .claude/commands/manage.md` — `1` or more.
- `grep -c "goes in your pull request body" .claude/commands/manage.md` —
  `1` or more (existing selftest pin still holds).
- The new `expect` cases fail with the manage.md hunk reverted
  (`git stash` the manage.md change, run the selftest topic, see them red,
  restore).
- PR body says `Closes #512`.
- Plan `ci` calls SHIPS: `.claude/commands/manage.md` and the selftest reach
  every consumer at its next sync, and the selftest runs in each consumer's
  `ci`.

## Where to look

- `.claude/commands/manage.md` "A LEAD, when you have one." paragraph — the
  current fallback sentence ("A lead with no such stem … goes in your pull
  request body instead").
- `.claude/commands/manage.md` "A remainder only a human can build"
  paragraph — the issue shape (title prefix, `human-review`, `Refs #N`) to
  mirror.
- `.claude/commands/clerk.md` §1 skip list — `held: human-review`; the
  author gate (an issue filed through the owner's login passes it).
- `.agents/harness/selftest/orchestrated.sh` — the `$mgrtext` `expect`
  block ending with `"goes in your pull request body"`.
- `.agents/docs/feedback.md` §4 "Inline or routed" — the canonical-issue
  cap this mirrors; "Where a consumer's OWN findings go".
- Issue #512 and its two comments — the original report and the clerk's
  questions this plan answers.

## Traps

- NEVER skip, disable or quarantine a test; the existing pin
  `goes in your pull request body` stays green.
- No edit to core paths; no edit to `.claude/commands/clerk.md`.
- Docs state status quo: no incident dates or "previously" prose in
  manage.md or feedback.md (`.agents/docs/caveman.md`, Status quo).
- One spelling per term (`.agents/docs/glossary.md`); `ci` fails on others.
