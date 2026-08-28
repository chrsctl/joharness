---
workstream: review-verifier-subagent
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: review-verifier-subagent
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: record the acceptance replay result, then review, retire, PR
---

## Goal

Plan `docs/plans/review-verifier-subagent.md`: every review this repo has
recorded was written by the context that wrote the code. Coverage is not the
gap — PR54 shipped `cleanup`'s deletion bug through a 14-finding opus
self-review, and a session with no stake found it in one pass. Give the
review step one reader that did not write the diff.

## Decisions

- Taken over the backpass-derived rule plan I proposed first. That proposal
  failed its own test: all four false numbers this session produced were
  already formally compliant with the rule I wanted to strengthen — each
  carried a command or looked like pasted output, and each was invented.
  Every one was caught by someone RE-RUNNING the claim, never by rule text.
  `.agents/docs/feedback.md` says why: writing rules is stage 3, and stage 4
  is the only stage that changes an outcome.

## Rejected

- `model:` in the verifier definition's frontmatter. The plan says the tier
  follows the branch's own and the spawning session passes it, so pinning a
  model in the file would silently outrank `./joharness.sh review`.
- Withholding `Bash` to make "fixes nothing" airtight. A verifier that
  cannot re-run a claim is the failure this repo keeps paying for — four
  false numbers this session, every one formally compliant with the rule
  that governs them, every one caught by someone executing the command. The
  trade is recorded in the definition itself: Edit/Write/NotebookEdit are
  withheld so a patch is out of reach, Bash is present so a claim can be
  reproduced, and using Bash to edit is named there as a defect.

## Review

(in flight — the acceptance replay is running; findings land here before
their fixes and in the same commit, per step 5)

## Acceptance: the replay

PASS, on the plan's own criterion — the verifier was given PR54's diff
(`git diff 78d5243 be6cebe`, 6 files / 722 insertions / 145 deletions) and
nothing else, and returned:

> **`joharness.sh:1339-1341` — `git diff --name-only "$base" "$r"` returns
> deletions, so a branch that *deleted* a file reads as "still carries it",
> permanently. VERIFIED.** Branch `sweeper` does exactly what `--apply`
> produces — `git rm docs/handover/alpha.md`, commit, push, unmerged — and
> `cleanup` from `main` then prints `keep docs/handover/alpha.md — an
> unmerged branch still carries it`.

That is the escape, named at its line, with the deletion-counts-as-a-
difference explanation the plan asked for, and reproduced in a scratch repo
rather than argued. It also caught what the plan did not ask for: that the
selftest case covering it passes only because the fixture never pushes the
deletion.

Seven further findings came back, and TWO are already fixed on today's
`main` — which is the strongest evidence in the run, because it means an
independent reader re-derived defects this repo found the expensive way:

- The escape itself. `cl_inflight` now carries `--diff-filter=ACMRT` and a
  comment naming the exact failure (`joharness.sh:1745`).
- `base_ref()` falling back to `HEAD`, so `--apply` deletes the running
  session's own live claim. `cmd_cleanup` now calls `decide_ref()` and dies
  with an error that names that danger in words.

Four I have NOT checked against today's `main` — `status:` never read, a
failed `git rm` counted nowhere while the run reports success, the
detached-HEAD guard comparing against `rev-parse --abbrev-ref HEAD`, and the
plans section filtering on the working tree rather than the ref. They were
true of the 2026-08 diff. Whether they survived is a separate question and
its own plan; folding a `cleanup` audit into this PR would widen it past
the mechanism it exists to prove.

## Progress

Built and green, not yet reviewed:

- `.claude/agents/verifier.md` — the definition.
- `.agents/harness/AGENTS.md` step 5, `.agents/docs/agent-selection.md`
  review depth — the rule and its reasoning.
- `joharness.sh:review_report` — the step printed beside the depth.
- `.agents/scripts/sync-to-consumer.sh` `DIRS` — `.claude/agents` ships.
- `.agents/harness/selftest.sh` — four cases; 617 -> 621.

The sync entry turned 20 tests red on the first run, which is the mechanism
working: a `DIRS` entry with no directory behind it warns and exits
non-zero, and the two scratch canonical fixtures carried no
`.claude/agents`. Fixed in the fixtures, never by dropping the entry.

`./joharness.sh ci` — ci: pass, 621 passed / 0 failed.
`./joharness.sh verify` — 8 passed, 0 failed.

## Blockers

None.

## Where to look

- `docs/plans/review-verifier-subagent.md` — the plan, unusually specific.
- `joharness.sh:cmd_review` — where the verifier step gets printed.
- `.agents/scripts/sync-to-consumer.sh:DIRS` — `.claude/agents` must ship.
