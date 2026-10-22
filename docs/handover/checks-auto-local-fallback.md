---
workstream: checks-auto-local-fallback
status: in-progress
branch: claude/checks-auto-local-fallback
pr: none
plan: checks-auto-local-fallback
issue: none
session: https://claude.ai/code/session_014wCvWi56XbqMaLKk8xdBds
agent: opus
updated: 2026-10-22
next: Run ci + verify on this head, file the ci.yml human-remainder issue, retire, open the PR
---

## Goal

Repository variable `JOHARNESS_CHECKS=local` alone switches a child repo to
the local gate: `finish` reads the head's `lint` check run; skipped = run
`ci` + `verify` here.

## Decisions

- Every `lint` run on the head must be `completed`/`skipped`, not only the
  highest id (plan said highest id): `check_name=lint` also returns a
  consumer workflow's own job named `lint`, and a skipped one of those must
  not switch the gate. The plan's re-run case still holds (fails closed).
- `CHECKS_LINT_SAID` (global, beside the function) keeps why: finish prints
  one line for `unread` and `none`, so "could not read" never looks like a
  read. The function's return contract is the plan's, unchanged.
- jq reads with `-s` and needs exactly one document with an array
  `check_runs`; anything else is `unread`.
- Conf-ignored warning stays when lint skipped; only its "This finish is
  github mode" clause goes.
- Human remainder: ci.yml `lint` comment "SET THE SESSION ENVIRONMENT TOO"
  paragraph goes stale; one `human-review` issue, `Refs` in the PR body.

## Rejected

- Highest-id `lint` run alone (plan text): r3 below.

## Review

- r1: (verifier) unreadable GitHub answer was silent: finish printed plain github mode, a skipped lint then read green with nothing checked (fixed: `unread` line, selftest)
- r2: (verifier) finish before Actions creates the lint run read the same silent way (fixed: `none` line, selftest)
- r3: (verifier) a consumer job named `lint` that skipped, with a higher id than the harness lint that passed, switched the gate (fixed: every lint run must say skipped; selftest `collide`)
- r4: (verifier) consumer-repos.md "A red base branch" said finish never reads a check run (fixed)
- r5: (verifier) github-mode text still said "does not read them (no network, no token)" and pass line "(not read here)" (fixed: both reworded, selftest needle updated)
- r6: (verifier) local-gate headers named the environment switch when lint skip fired it (fixed: `checks_local_why`, selftest)
- r7: (verifier) conf-ignored warning suppressed whole under lint skip, contradicting the doc (fixed: warning kept, github-mode clause dropped; selftest)
- r8: (verifier) `status == "completed"` clause untested (fixed: `queued` fixture; mutant 3 failed)
- r9: (verifier) slug validation untested (fixed: `/extra` origin case; mutant 4 failed)
- r10: (verifier) concatenated documents, object `check_runs` read as skipped (fixed: `jq -s`, one document, array; fixtures; mutants 3 and 1 failed)
- r11: (verifier) no `timeout` binary leaves `gh api` unbounded (wontfix: plan bounds it "when `timeout` exists"; curl carries --max-time)
- r12: (verifier) workstream file not updated with the code (fixed: this commit)
- r13: mutants on the checks topic alone, scratch worktree (`for _t in checks` in selftest.sh), 2026-10-22: base 142 passed; `checks_lint_skipped() { return 1;` 13 failed; `{ CHECKS_LINT_SAID=skipped; return 0;` 46; `all(...)` -> `any(.conclusion == "skipped")` 9 (drops the status clause too); `.status == "completed" and ` removed 3; slug-check line removed 4; `length == 1 and ` removed 3; type check -> `true` 1; unread line off 2; none line off 1 (no change)
- r14: (verifier) ssh-origin case passed with the ssh branch deleted: the container's GIT_CONFIG_COUNT insteadOf rewrote `git@github.com:` to https (fixed: `kc_gh` unsets GIT_CONFIG_COUNT; mutant 2 failed)
- r15: (verifier) r13's `any` count did not reproduce (fixed: r13 names each mutant's edit; `all(` -> `any(` alone, 2026-10-22, 7 failed)
- r16: (verifier) origin with a token (`https://x-access-token:t@github.com/o/r`) or a trailing slash read as not GitHub, silently (fixed: both accepted, user part may hold no `/`; selftest; mutants 3 and 3 failed)
- r17: (verifier) only a consumer job named `lint` exists yet and it skipped: gate goes local before the harness lint run exists (wontfix: the plan's highest-id rule shares it; telling the two apart needs the check suite or workflow, outside the plan's read)
- r18: (verifier) unread line's remedy wrong when the head is not pushed (fixed: names "head not pushed? private repo with no gh login?")
- r19: (verifier) lint-skip "NOT run" header untested (fixed: red-finish case on kcskip; reverting the header, 1 failed)
- r20: (verifier) usage header and github-mode line did not name the repository variable (fixed; KNOBS row describes the environment knob and stays)
- r21: (verifier) 60 requests/hour, unauthenticated 200, `filter=latest` and skipped-job check runs are GitHub behaviour unread here (no change: the plan measured the 200; the rest fail closed either way)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — where `is_local` is decided.
- `joharness.sh:checks_lint_skipped` — the GitHub read; fails closed.
