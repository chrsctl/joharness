---
plan: harness-rules-field-review
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/AGENTS.md, .agents/docs/handover/README.md
---

## Goal

A measured field review of consumer `chrsctl/redocted` — one working day,
24 merged pull requests, four concurrent session branches, range
`3936d49..c79dc82` — found four defects in the rules themselves. Zero
commits in that range touched any harness surface, and every harness file
there is byte-identical to this repo's, so all four are defects in the
CURRENT canonical rules, not in a stale copy. Fix the rule text.

## Scope

Four edits, each named with what it answers.

**1. The documented way to recover a review record does not work.**
Loop step 7 says the PR's final state deletes the workstream file. The
handover README's `Survives PR` bullet says the reasoning is "recoverable
forever at `git show <merge>:docs/handover/<workstream>.md`". Both cannot
hold: the file is deleted as the branch's last commit, so no merge commit
contains it. Verified against three merged PRs from two different sessions — all
`fatal: path ... does not exist`. And because the file lives and dies on a
side branch, git's default history simplification prunes it from path
queries too: `git log -- <path>` from `main` returns empty. `--full-history`
is the part that recovers it. `git log --all` also finds it for as long as
the branch ref survives — but step 7 makes deleting the branch optional and
human-only, so that is luck, not a retrieval method. Counted in that range:
47 retired workstream files carrying 106 review findings, none reachable by
any documented command.

Replace the retrieval line with the two-step that works (verified):

    git log --all --full-history --oneline -- docs/handover/<name>.md
    git show <retire-commit>^:docs/handover/<name>.md

and add one line to Loop step 7: the PR body carries that command for its
own workstream file, so the record is findable from the merged artifact
rather than from a guess.

**2. Nothing says infrastructure state expires.** For several hours the
consumer had no Actions runner: every check failed unassigned, on `main`
too. A session concluded self-merge was structurally impossible, wrote
that into a PR body, and merged it. A runner was live 30 minutes later; 23
further PRs merged on green checks that day. A check-in that session had
scheduled fired afterwards carrying the dead conclusion as an instruction.
Nothing in `.agents/harness/` or `.agents/docs/` mentions runners or any
repo state that is true this hour and false the next. Add to step 7: an
infrastructure reading is re-derived at every check, never inherited; and
a scheduled check-in states what to RE-CHECK, never what is true.

**3. Nothing requires a test to fail without its fix.** Step 5 says all
green or not done, and never skip or quarantine a test to get green — both
about tests that fail. Neither catches the test that passes for the wrong
reason. One shipped in that range: an end-to-end test whose fixture made
the case vacuous passed identically with the fix deleted, and was caught
only by disabling the change by hand. Add one line to step 5: a test
written for a fix must FAIL without it — disable the fix, run the test,
restore; green on both sides means the test pins nothing.

**4. A counted number with no fixture cannot be re-counted.** "Trust
counted numbers, never written numbers" caught two stale figures in that
range. Neither recorded what produced it, so re-measuring needed an
invented fixture and the new number is not comparable to the old. Add a
clause where the rule already lives: a measured number carries what
produced it, in the same sentence.

## Out of scope

- `.agents/docs/caveman.md` and the house style. These edits obey it; they
  do not change it.
- Any change to WHERE the workstream file lives or when it is deleted.
  Edit 1 fixes the retrieval sentence and adds a pointer; the lifecycle
  stays as designed.
- The queue's scope and wave semantics (`queue-shared-scope`) and `ci`
  timing (`ci-scope-selftest`). Same review, different plans, different
  files.
- Consumer `AGENTS.md` Part 2 files. Not this repo's to edit; they receive
  the harness, not the reverse.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed.
- The retrieval command in the handover README, run against a real
  retired workstream file in this repo's history, prints the file.
- `.agents/harness/AGENTS.md` grows by no more than ~10 lines total. Every
  session loads it before its first prompt; four rules must not cost a page.
  Measure it (`wc -c`) at the commit you start from rather than trusting a
  figure written here — it was 5,617 bytes when this plan was drafted, 5,949
  by the time the plan merged, 6,500 at queue cleanup (2026-08-24).

## Where to look

- `.agents/docs/handover/README.md`, `Survives PR` bullet — the retrieval
  sentence to replace.
- `.agents/harness/AGENTS.md`, Loop step 5 — where the mutation line goes.
- `.agents/harness/AGENTS.md`, Loop step 5's `NEVER skip, disable, or
  quarantine a test` line — the nearest neighbour in intent.
- `.agents/harness/AGENTS.md`, Loop step 7 — for the PR-body pointer and
  the infrastructure-state line.
- `.agents/docs/handover/README.md` "Survives PR" bullet — the claim that
  edit 1 makes true.

## Traps

- Caveman style: short, only what code cannot tell you. Four rules, four
  lines where possible; the reasoning goes to `.agents/docs/`.
- Trust counted numbers. The counts above were measured in the consumer at
  `c79dc82`; re-run them there rather than repeating them if a number ends
  up in the rule text.
- The harness must never name a specific environment. None of these four
  come near that, and none may be written in a way that does.
