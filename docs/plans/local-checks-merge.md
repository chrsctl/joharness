---
plan: local-checks-merge
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/AGENTS.md, .agents/harness/selftest.sh, .agents/harness/selftest/checks.sh, joharness.conf
---

## Goal

Step 7 merges on "GitHub checks green on head". Every session pays the round
trip: push, wait for Actions, read the run, merge. Requester wants opt-out —
skip wait, run same checks here instead. Knob per repo, default unchanged.
Local run only counts if it ran on the head that merges, so the command that
skips wait is the command that runs the checks itself.

## Scope

- `joharness.sh` — `JOHARNESS_CHECKS` reader (`github` default, `local`),
  fail-closed like `review_on`. `cmd_finish` under `local`: refuse to certify
  a head that is not what merges (uncommitted tracked changes, or HEAD not
  equal to its pushed remote tip), then run `ci`, then `verify` when the diff
  touches a non-`*.md` file under the four gated paths. Red on any failure.
  Name what a local run cannot cover. Under `github`: one line saying GitHub
  checks are the gate and this command does not read them. Usage header row.
  `cmd_session_start` announces `local`, like the review gate.
- `.agents/harness/AGENTS.md` — step 7 merge condition names the knob, one
  clause. Step 5's "read the run" clause gets the same.
- `joharness.conf` — knob with its reasoning, `github` selected.
- `.agents/harness/selftest/checks.sh` — new topic.
- `.agents/harness/selftest.sh` — `checks` in `SELFTEST_TOPICS`.

## Out of scope

- Reading GitHub. No API call, no `gh`, no token. The knob decides whether a
  session waits, never what a run said.
- Caching a green. Harness counts from git at read time and stores nothing;
  a stored "ci passed at sha X" is state that rots exactly once.
- Branch protection. A repo with required checks blocks the merge button
  whatever this knob says. Named in output, never worked around.
- Running `.agents/scripts/ci-verify-layers.sh` from `finish`. `verify` on
  the selected layer is the stronger check and already required.
- `cmd_ci`. It gains nothing here: `ci` is one of the things `finish` runs.

## Acceptance

- `./joharness.sh finish` on this branch — green, and prints
  `checks: github` plus the line saying GitHub checks are the gate.
- `JOHARNESS_CHECKS=local ./joharness.sh finish` on a dirty tree — red,
  naming the uncommitted file.
- `JOHARNESS_CHECKS=bogus ./joharness.sh finish` — warns, stays `github`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.
- Plan SHIPS: `joharness.sh` and `.agents/harness/AGENTS.md` reach every
  consumer. Consumer-runnable check: `JOHARNESS_CHECKS=local ./joharness.sh
  finish` in a repo carrying no selftest still runs that repo's `ci` and
  `verify` and reds on their exit code.

## Where to look

- `joharness.sh:cmd_finish` — the step 7 gate this extends.
- `joharness.sh:review_on` — fail-closed knob shape to copy.
- `joharness.sh:cmd_verify` — a layer with no smoke test passes; a `local`
  gate must not read that as proof of a layer that has one.
- `joharness.sh:decide_ref` — a command that acts on an answer refuses when
  it has no answer.
- `.agents/harness/selftest/ci-churn.sh` — scratch-repo fixture pattern:
  copy `joharness.sh`, stub `selftest.sh`, push to a bare origin.

## Traps

- Trust counted numbers, never written numbers. A local green is counted only
  on the tree that merges — hence the refusals before the run.
- Background command must be able to finish. `ci` and `verify` run in the
  foreground here, bounded by their own suites.
- Never skip, disable or quarantine a test to get green.
- `.agents/harness/` names no environment layer. The gated-path list is
  already in `AGENTS.md` step 7 and names directories, not layers.
