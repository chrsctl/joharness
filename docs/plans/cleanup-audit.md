---
plan: cleanup-audit
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh
---

## Goal

`.claude/agents/verifier.md`, given PR54's diff and no other context,
returned eight findings against `cleanup`. Two are already fixed on `main` —
the `--name-only` deletion bug (`cl_inflight` carries `--diff-filter=ACMRT`
now) and `base_ref` falling back to `HEAD` (`cmd_cleanup` calls
`decide_ref()` and dies). **Four were never checked against today's tree.**
They were true of the 2026-08 diff; whether they survived is unknown, and
`cleanup --apply` is the one mutating subcommand in the entrypoint.

Recorded but not carried: PR #110 left them in a workstream file that step 7
retired, where `feedback` cannot reach them because no fix commit exists.
This plan is that carry.

## The four, as the verifier reported them

Each is a hypothesis until re-run against `main` — that is the work.

1. **`status:` is never read.** A live `in-progress` workstream file on the
   base branch is reported stale and `--apply` stages its deletion. The
   reported sequence: PR 1 of a multi-PR workstream merges, the session cuts
   part 2 and has not pushed, `cleanup --apply` stages the deletion of the
   file it is actively writing.
2. **A failed `git rm` is counted nowhere.** With local modifications on the
   leftover — the state the command's own advice invites — git errors, the
   run warns, then prints "none — the ritual ran" and exits 0.
3. **The base-branch guard compares `git rev-parse --abbrev-ref HEAD`**,
   which prints `HEAD` when detached, so the warning is skipped in exactly
   the checkout CI produces.
4. **The plans section filters on the working tree**, not the ref: it tests
   `[ -f "${ROOT}/docs/plans/${p}.md" ]` while reporting "plans on <ref>".
   Same tree-vs-diff class `.agents/docs/feedback.md` graduated.

## Scope

- Re-run each of the four against `main`, in a scratch repo, and record
  which reproduce. A finding that no longer reproduces is closed with the
  commit that fixed it named.
- Fix the ones that do, smallest change each, in `joharness.sh`.
- `.agents/harness/selftest.sh` — a regression case per reproduced finding,
  each failing without its fix (revert it, run it, put it back).

## Out of scope

- Redesigning `cleanup`. Four specific defects, four specific fixes.
- The `--apply` semantics, the base-branch warning's wording, or which ref
  it measures against. Those are decided and tested.
- Findings 1 and 2 from that replay, already fixed on `main`. Named in the
  Goal so nobody re-finds them.

## Acceptance

- Each of the four: reproduced with the concrete input, or closed with the
  commit that fixed it. State which, per finding. Four verdicts, no
  silence.
- Every fix has a test that fails without it — reverted, run, restored.
- `./joharness.sh ci` — `ci: pass`, selftest count higher by the tests
  added.
- `./joharness.sh verify` — 0 failed. Required: the diff touches
  `joharness.sh`.

## Where to look

- `joharness.sh:cmd_cleanup`, `cl_inflight`, `decide_ref` — the subcommand
  and the two helpers the fixed findings landed in.
- `.agents/docs/handover/README.md`, the `status:` values — what a live
  workstream file looks like, which finding 1 turns on.
- PR #110's workstream record, for the replay in full:
  `git log --all --full-history --diff-filter=D --oneline --
  docs/handover/review-verifier-subagent.md`

## Traps

- `--apply` deletes files. Every reproduction goes in a scratch repo, never
  this checkout.
- A finding that does not reproduce is a finding to CLOSE with evidence, not
  to quietly drop — the replay is the record that it was once true.
- Do not widen `cl_inflight`'s filter to serve a new question; PR60 paid for
  that filter and the tree-vs-diff rule graduated out of it.
