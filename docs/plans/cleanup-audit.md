---
plan: cleanup-audit
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest/cleanup.sh
---

## Goal

`.claude/agents/verifier.md`, given PR54's diff and no other context,
returned eight findings against `cleanup`. All eight, accounted for:

- **Two already fixed on `main`**: the `--name-only` deletion bug, fixed by
  `853f551` (`cl_inflight` carries `--diff-filter=ACMRT`), and `base_ref`
  falling back to `HEAD`, fixed by `cmd_cleanup` calling `decide_ref()` and
  dying. Named by defect, not by their number in the replay — the list
  below renumbers.
- **Two that are not `cleanup` defects at all**: PR54's own workstream file
  wrote six findings as `r8 (cleanup):`, which the fix map cannot key on,
  and gave two different findings the same `r8`. That is the finding-format
  class, and `docs/plans/finding-id-lint.md` owns it. Out of scope here.
- **Four never checked against today's tree** — this plan.

**The four were never checked against today's tree.**
They were true of the 2026-08 diff; whether they survived is unknown.
`cleanup --apply` is the subcommand that DELETES TRACKED FILES — `env` and
`setup` mutate too (`joharness.conf`, the provisioned layer) and `upgrade`
rewrites harness files, so this is not the only mutating one, but it is the
one whose mistake removes a live claim.

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
- The `--name-only` deletion bug and the `base_ref`/`HEAD` fallback, both
  already fixed. Named by defect in the Goal so nobody re-finds them, and
  never by replay number — the Goal's list renumbers.
- The two finding-format defects in PR54's own record. `finding-id-lint`
  owns that class.

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
- PR #110's workstream record, for the replay in full. Two commands: the
  first finds the retire commit, the second prints the file
  (`.agents/docs/handover/README.md`, Survives PR).

  ```bash
  git log --all --full-history --diff-filter=D --oneline -- docs/handover/review-verifier-subagent.md
  git show ddc33b3^:docs/handover/review-verifier-subagent.md
  ```

## Traps

- `--apply` deletes files. Every reproduction goes in a scratch repo, never
  this checkout.
- A finding that does not reproduce is a finding to CLOSE with evidence, not
  to quietly drop — the replay is the record that it was once true.
- Do not widen `cl_inflight`'s filter to serve a new question. `853f551`
  paid for it ("Stop cleanup protecting the file the finishing ritual
  deleted") and the tree-vs-diff rule graduated out of that class. Cited by
  commit, not by pull request number — an earlier draft of this Trap said
  PR60, which is the OTHER already-fixed finding, and a Trap is precisely
  what a literal reader goes and reads.
