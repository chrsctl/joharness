---
workstream: local-checks-merge
status: in-progress
branch: claude/skip-github-actions-wait-jdd3bn
pr: none
plan: local-checks-merge
issue: none
session: https://claude.ai/code/session_018BqX6Ux5hvSAm5AQ725mDe
agent: opus
updated: 2026-09-10
next: Run ci and verify green, then retire this file and the plan (step 7).
---

## Goal

Requester: "Add skip waiting for GitHub actions/just run locally." Step 7
merges on GitHub checks green, so every session pushes and then waits on
Actions. Opt-out wanted: run the same checks here, merge without the wait.

## Decisions

- Knob `JOHARNESS_CHECKS=github|local` in `joharness.conf`, env override for
  one command. Same fail-closed shape as `JOHARNESS_REVIEW`: only the named
  value switches it, anything else warns and stays on the default.
- `local` does not merely permit skipping the wait — `./joharness.sh finish`
  RUNS `ci`, and `verify` when the diff touches harness code. Step 7 already
  names `finish` as the guard that fires while the fix is still a commit, so
  the command that answers "mergeable now" is the one that must have run the
  checks. Nothing else can: a session's own earlier `ci` proves an earlier
  tree.
- Refusals come before the run: uncommitted tracked changes, or HEAD not
  equal to the pushed remote tip, mean the local green would be about a tree
  that is not what merges. Same doctrine as `decide_ref` — a command that
  acts on an answer refuses when it has no answer.
- Default stays `github`, and under it `finish` keeps its current runtime and
  output plus one line naming who the gate is. A repo that does not opt in
  pays nothing, in seconds or context.
- Announced at session start when `local`, like the review gate. A session
  that learns at step 7 has already waited on Actions once.
- Behind the base branch is a red under `local` only. Under `github` a pull
  request run tests a MERGE of head and base, so the tip is not the whole
  story there and step 7's own 0-behind rule already covers it; under `local`
  nothing ever sees that merge, so the tip is the entire evidence.
- The suites run LAST and only when the rest of `finish` is green. A head
  still carrying its own workstream file is not the head that merges, so a
  run there would spend minutes on a question whose answer cannot change the
  verdict. The skip is printed, never silent.

## Rejected

- Caching "ci passed at sha X" so `finish` can skip a re-run. Every measure
  in this harness counts from git at read time and stores nothing; a stored
  verdict is a written number that goes stale in the one case that matters.
- A separate `./joharness.sh checks` subcommand. Two commands to run before a
  merge is one command too many, and step 7 already names `finish`.
- Having `finish` read GitHub (API or `gh`) to decide whether the wait is
  worth it. The ask is to not need GitHub; a gate needing a token is a gate
  a consumer without one cannot run.

## Review

Depth: opus adversarial (`./joharness.sh review`), plus `.claude/agents/verifier.md`
at opus on the committed diff. Mutation column below is
`bash <runner> one.sh`, a runner built from `selftest.sh` lines 1-519 plus a
source of this topic, run 2026-09-10 in this checkout; the topic alone is
80 passed, 0 failed.

- r1: (session, correctness) the summary line printed `0 behind <ref>`
  unconditionally, including when `rev-list` returned nothing — a written
  number in the one place a reader takes as proof the count was taken.
  (fixed: the line prints what was established, `behind not measurable`
  otherwise; `the head line claims no count it could not take` pins it.)
- r2: (session, correctness) a shallow clone has no visible common history,
  so `rev-list --count HEAD..origin/main` returns the base branch's whole
  depth and every branch reads as behind — a false red, with `git fetch
  origin main` as a remedy that does not unshallow. (fixed: the count goes
  through a merge-base and says `not measurable` without one; mutation on
  that line reds 4 cases.)
- r3: (verifier, correctness) `0 behind` was counted off a LOCAL ref with no
  fetch, while step 7 says fresh-fetched. Reproduced: two clones, a push to
  `main` from one, the other reports `0 behind origin/main`, `ci: pass`,
  rc 0. (fixed: a bounded fetch first, `HANDOVER_FETCH=0` to skip it, and the
  count carries `fetched just now` or `as of the last fetch`; mutation on the
  fetch reds 1 case.)
- r4: (verifier, correctness) detached HEAD asked the pushed question of
  `origin/HEAD`, which resolves in any normal clone — so a detached checkout
  at the base branch read as pushed, clean and 0 behind and was certified.
  (fixed: a DETACHED refusal; mutation reds 1 case.)
- r5: (verifier, correctness) `git diff --name-only` C-QUOTES a non-ASCII
  path, and `".agents/harness/w\303\251ird.sh"` matches no prefix — so the
  one shape that must ask for `verify` was the one that skipped it. (fixed:
  `-z`, as `checks_tree_extra` already did; mutation reds 3 cases.)
- r6: (verifier, correctness) `ci` returns 0 with shellcheck SKIPPED off a
  runner, and the gate reprinted that as a plain `ci: pass` — merging code
  the workflow it stands in for reds for. (fixed: a green `ci` with the tool
  still missing is red here, said in full; a PATH farm without shellcheck
  pins both halves, mutation reds 2 cases.)
- r7: (verifier, correctness) `@{upstream}` was preferred over
  `origin/<branch>`, and `git checkout -b feat origin/main` — the documented
  cut — sets that upstream to the BASE branch, so a pushed branch was refused
  as unpushed with a remedy that never cleared it. (fixed: `origin/<branch>`
  first, the upstream only when it names this branch; mutation reds 2 cases.)
- r8: (verifier, test) nothing pinned the headline claim. `if "$0" ci || true`
  left the whole topic green. (fixed: a fixture branch carrying a script that
  does not parse; mutation reds 2 cases.)
- r9: (verifier, test) the `*.md` exclusion, stated in four documents, was
  pinned by zero cases — the docs-only case passes on the path, not the
  suffix. (fixed: a branch whose only change is markdown UNDER a gated path;
  mutation on the suffix test reds 1 case.)
- r10: (verifier, rules) `.agents/scripts/conf-keys.sh` was not updated, so
  the key would reach no consumer bootstrapped before it — the failure that
  file's own header records for `JOHARNESS_MODE`. (fixed: a row there and the
  matching line in the bootstrap's seeded conf, which the selftest compares.)
- r11: (verifier, docs) step 7's `verify` clause says "read the run", and
  under `local` there is no run to read. (fixed: the clause says `finish`
  runs `verify` ITSELF and there is no run to read then.)
- r12: (verifier, docs) the four gated paths were spelled a fourth and fifth
  time in `joharness.conf` and the usage header. (fixed: both point at step 7
  and at `CHECKS_VERIFY_PATHS`, which is the one copy.)
- r13: (verifier, correctness) `checks_tree_extra` discarded `git status`'s
  exit status, so a git failure would read as a clean tree. (fixed: it
  returns non-zero and the gate prints UNREADABLE and refuses. The read goes
  through a file, not `$( )`, which drops the NUL bytes `-z` output is made
  of. NOT pinned by a case: every way to break `git status` for this process
  needs a permission the container runs above, so it stays reasoned — the
  same disposition the verifier gave it.)
- r14: (verifier, clean) no unquoted expansions, no `grep -q` SIGPIPE, no
  lost `PIPESTATUS`, no `set -u` trap, no function-name collision with the
  runner. Recorded because a clean pass is a finding too.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — the gate being extended.
- `joharness.sh:review_on` — knob shape copied.
- `.agents/harness/selftest/ci-churn.sh` — fixture pattern for the new topic.
