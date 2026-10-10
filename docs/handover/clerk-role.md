---
workstream: clerk-role
status: in-progress
branch: claude/clerk-role
pr: none
plan: clerk-role
issue: none
session: https://claude.ai/code/session_01EnrJYs6CDGv3bypoHRvf5w
agent: opus
updated: 2026-10-10
next: Answer verifier findings in ## Review, then retire plan + this file, PR, merge
---

## Goal

Requester, 2026-10-08: "we need roles which convert issues to docs/plans".
Build the CLERK cadence role per `docs/plans/clerk-role.md`.

## Decisions

- Cycle identity = the SCOUT's, not the janitor's frontmatter key the plan
  pointed at: path `docs/handover/clerk-<digit>*` decides, read by
  `scout_walk clerk` / `scout_retired_ts clerk` (parameterised by kind, not
  copied). Scout's six review passes found every content filter fails open;
  a second clerk would plan the same issues twice. `cycle_landed_sha clerk`
  uses the scout's `-m` reader too — a new cycle owes no reader compat.
- Clerk is orthogonal to the verdict (plan: "exactly like curate"), but
  takes the scout's fetch-failed hold, same reason as above. Scout's gate
  now also waits for a clerk due or in flight: issues about to become plans
  mean the queue is not drained.
- No command file = cycle off (scout's r6), so dispatch fixtures in other
  topics print `clerk : off` and spawn nothing.
- PLANNED / CLAIMED = one `git grep '^issue:'` over base tip (+ every
  unmerged tip for CLAIMED). Line match, fails closed (body line reads as
  taken). grep error = `?` = UNREADABLE, never empty.
- One validator `issue_verdict` for workstream lint, plan lint and the clerk
  lists; `lint_issue` wraps it. handover-context.sh:issue_num stays the
  lockstep twin (cannot source joharness.sh).
- clerk.md adds a skip the plan did not name: an issue whose NEWEST comment
  is a `clerk: <VERDICT>` comment. Without it every pass re-reads and
  re-comments every DOES NOT HOLD / HUMAN / NARROWER issue, since none of
  those leaves a plan or a claim behind.

## Rejected

- None yet.

## Review

- r1: (session) first selftest, 2026-10-10, `bash .agents/harness/selftest.sh`: 3 failed — `clerk_issue_nums` stripped the inline comment BEFORE the blanks after the key, so `issue: #13` read as one comment and both lists came back empty (fails OPEN: a claimed issue reads free); and the lint case ran before ci-graph-lint built `lwork`. (fixed — gr_fields' trim order; clerk topic listed after ci-graph-lint. Re-run: 2437 passed, 0 failed. The failing run IS the without-fix run for both list cases.)
- r2: (verifier) `clerk_issue_nums` fails OPEN under `grep.lineNumber`/`grep.column` in user config: lines read `1:issue: #230`, prefix strip misses, `claimed : none` (reproduced with GIT_CONFIG_COUNT). (fixed — pinned off with `-c`, plus `grep.fullName`; case `grep.lineNumber and grep.column change nothing`)
- r3: (verifier) clerk.md "re-run each cited command" runs issue-supplied commands, and stranger COMMENTS on a maintainer issue count as claims. (fixed — read-only commands only, never pipe-to-shell or foreign hosts; only gated authors' comments are issue content)
- r4: (verifier) "a maintainer adopts it by commenting" undoes the author gate — the clerk's own HUMAN comment may come from a write identity. (fixed — adoption = maintainer re-files; a comment adopts nothing)
- r5: (verifier) scout-gate case pinned nothing: fixture had no scout.md and a NOT DRAINED verdict. (fixed — case at DRAINED with scout.md, clerk off spawns / clerk due suppresses)
- r6: (verifier) UNREADABLE path untested. (fixed — copied fixture with a removed tree object)
- r7: (verifier) clerk PR that never merges → 24h later a second clerk re-plans the same issues (PLANNED read base only). (fixed — PLANNED reads every unmerged tip too; clerk.md: red gate = leave PR open, report, exit)
- r8: (verifier) anyone can mute an issue by commenting `clerk: …`. (fixed — only a verdict by the clerk's own login counts; a stranger's comment reopens nothing)
- r9: (verifier) manage.md concurrent sibling plans both write `Refs #N`, issue never closes; `\b` is GNU. (fixed `\b` → `([^0-9]|$)`; race wontfix — the next clerk re-verifies the issue against source, finds it landed, comments DOES NOT HOLD with evidence, human closes)
- r10: (verifier) NUL byte → `Binary file … matches`, issue dropped. (fixed — `--text`)
- r11: (verifier) scout may spawn between a clerk's retire and its PR merge. (wontfix — window is one merge's latency; a scout proposal waits for a human by default, and the scout's own plans never collide with issue plans by number)
- r12: (verifier) diff edits `.agents/harness/selftest/scout.sh`, outside `scope:`. (no change — one expected string the shared dispatch line re-spelled; named in the PR body)
- r13: (verifier) orchestrated.md said "dated like the janitor"; `cycle_landed_sha` comment said `-m` scout only. (fixed — both)
- r14: (verifier) branch 6 behind origin/main. (fixed — reconcile merge before finish)
- r15: (session) mutation, scratch worktree 2026-10-10, r2+r5+r6 fixes reverted together: `bash .agents/harness/selftest.sh` 2438 passed, 5 failed — exactly the five new cases; restored 2443 passed, 0 failed. (no change)

## Blockers

None.

## Where to look

- `docs/plans/clerk-role.md` — the plan, whole.
