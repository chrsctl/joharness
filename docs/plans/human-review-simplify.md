---
plan: human-review-simplify
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: .claude/commands/manage.md, .claude/commands/clerk.md, .agents/harness/AGENTS.md, .agents/harness/handover-context.sh, .agents/docs/plans/README.md, .agents/docs/orchestrated.md, joharness.sh, .agents/harness/selftest/orchestrated.sh
---

## Goal

The repo owner asked in session 2026-10-22 to simplify the human review
process. This plan makes two changes:

1. **Core-path remainder becomes a ready PR.** Today a manager files a
   `human: <stem>: …` issue describing a core-path edit. The human then
   writes or orders the pull request, and merges it: two objects, two steps.
   After this plan the manager opens that pull request itself, ready to
   merge, with the `human-review` label; the human only reviews and merges.
   Bounds already allows this: the guarantee is that a human reviews and
   merges, not who typed the diff (`.agents/docs/plans/README.md`, "A human
   remainder"; done by hand as PR #520 for issue #515).
2. **Clerk questions take a number.** Today a clerk HUMAN verdict asks an
   open question and the human writes an answer by hand. After this plan
   the comment lists numbered options with the recommendation marked, and a
   hand-typed reply holding just the number answers it.

## Scope

- `.claude/commands/manage.md`, paragraph "A remainder only a human can
  build" — replace the issue with a pull request:
  - Before the retire commit, from a separate worktree (`git worktree add
    ../<repo>-human human/<stem> origin/main`, fresh-fetched), never
    checked out in the session's own tree: commit ONLY the core-path edit,
    run `./joharness.sh ci` there, push `human/<stem>`.
  - Open the pull request: title `human: <stem>: <edit, one line>`, body =
    the plan's reason, the `ci` result, and "merge is the human's"; label
    `human-review`. Never merge it, never push to it again unless the human
    asks.
  - Own pull request body says `Refs #<core PR>`.
  - `create_pull_request` fails = `status: blocked`, `next:` = `github:
    human PR not opened: <error, 40 chars>`, push, exit (same shape as the
    current filing failure).
  - Remove `worktree` afterwards (`git worktree remove`).
  - Update the "Before the retire commit" bullet that says "a human
    remainder's issue filed (§2)" to say the pull request.
- `.claude/commands/clerk.md` §3 HUMAN — the comment lists 2 to 4 numbered
  options, each one line, the recommended one marked `(recommended)`, and
  ends: "reply by hand with the number; a Claude-posted answer is not
  read". §2 "What counts as the issue": a counting maintainer comment whose
  first token is a number `N` selects option `N` of the newest `clerk:
  HUMAN` comment posted by the clerk identity; that option's text is read as
  the maintainer's answer. Any other reply is read as today.
- `.agents/harness/AGENTS.md` Loop step 2 — keep the exact substring `no
  commit to a core path` and append `outside a human/<stem> branch whose
  pull request a human merges`.
- `.agents/harness/handover-context.sh` — the `keeps:` line: same append,
  keeping `no commit to a core path`.
- `joharness.sh` session-start banner (`printf 'Protocol text is yours to
  edit and merge. NEVER edit the core\n'` and the lines after it) — keep
  `NEVER edit the core` and add one line: the one exception is a
  `human/<stem>` pull request labelled `human-review`, which a human merges.
- `.agents/docs/plans/README.md` "A human remainder" and
  `.agents/docs/orchestrated.md` Bounds — status quo: the home is a
  `human/<stem>` pull request labelled `human-review`, never merged by a
  session.
- `.agents/harness/selftest/orchestrated.sh` — `expect` cases on
  `$mgrtext` for `human/<stem>` and `never merge it`; read
  `.claude/commands/clerk.md` as `$mgrtext` is read and pin `reply by hand
  with the number` and `(recommended)`. Each must FAIL on `main` first.

## Out of scope

- The Stop guard (`handover-guard.sh`): the worktree keeps the core commit
  off the session's own branch, so the guard's "touches core file(s)" fact
  stays correct as is.
- Any change to who merges: a session still never merges a pull request
  carrying `human-review` (`.claude/skills/steward/SKILL.md`, At merge).
- The clerk writing core-path pull requests; the clerk still writes plans
  only.
- Letting a session post an answer for the human. The hand-typed rule
  stays.
- `joharness.conf`, `.claude/settings.json`, `.github` themselves.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Existing pins still pass: `selftest/handover-context-compact.sh`
  (`no commit to a core path`), `selftest/autonomy-mode.sh` and
  `selftest/orchestrated.sh` (`NEVER edit the core`).
- New `expect` cases red with the command-file hunks reverted; record the
  red lines in the workstream file's `## Review`.
- `grep -c "human/<stem>" .claude/commands/manage.md` — `1` or more.
- Plan `ci` calls SHIPS: command files, `AGENTS.md`, the banner and the
  selftest reach every consumer at its next sync.

## Where to look

- `.claude/commands/manage.md` "A remainder only a human can build" and the
  "Before the retire commit" bullet.
- `.claude/commands/clerk.md` §2 "What counts as the issue", §3 HUMAN, the
  footer rule.
- `.agents/docs/plans/README.md` "A human remainder" — why the home moved
  off plans; the sentence "the guarantee is code-owner review, not who typed
  the diff".
- `.agents/docs/orchestrated.md` Bounds — core paths, CODEOWNERS.
- `joharness.sh` banner near `printf 'Protocol text is yours to edit and
  merge. NEVER edit the core\n'`; `.agents/harness/handover-context.sh`
  `keeps:` line.
- PR #520 / issue #515 — the by-hand run of change 1.

## Traps

- Merge-gate and boundary territory (`.agents/docs/orchestrated.md`,
  Bounds): never let a session merge, approve or relabel a `human/` pull
  request.
- No commit to a core path on the session's own branch; only in the
  `human/<stem>` worktree.
- NEVER skip, disable or quarantine a test; the three existing pins stay
  green with their substrings unchanged.
- Plans `manager-defect-issue` and `issue-pr-link-comment` also edit
  `.claude/commands/manage.md`, `.claude/commands/clerk.md` and
  `selftest/orchestrated.sh`; whichever lands later merges `origin/main` in
  and keeps every paragraph and test block.
- Docs state status quo (`.agents/docs/caveman.md`).
