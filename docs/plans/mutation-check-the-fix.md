---
plan: mutation-check-the-fix
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest
---

## Goal

Loop step 5 already carries the rule that catches assertions which pass for
the wrong reason:

> Test written for a fix must FAIL without it: revert the fix, run the test,
> put it back. Green both ways = test pins nothing.

Nothing enforces it, nothing makes it cheap, and it is easy to run WRONGLY.
Three instances in three days, none caught by any mechanism:

- **2026-08-28**, `origin/claude/backpass-usage-review-sbew6t` v3: three
  `expect`s greping the whole `session-start` output, which echoes workstream
  `next:` lines and plan `scope:` paths. Satisfied by any repo-controlled
  text. Found by the verifier planting a decoy.
- **2026-08-30**, PR 151: `refute "work still building is not an edge"
  "EDGE: pull request #none"`. Vacuous from the day it was written. Found by
  forcing `rank_of` to return 2 and watching it stay green.
- **2026-08-30**, PR 153: the mutation itself went to the WRONG FUNCTION.
  `churn_top` and `selftest_inert_diff` carry a byte-identical guard line,
  and a replace-first-occurrence patched the one at line 792 instead of the
  one at 834. Two cases stayed green and were nearly reported as vacuous
  when they were correct. A test that fails to red is a hypothesis about the
  test AND about the mutation.

Make the mutation a command, so it is cheap to run and impossible to aim at
the wrong line by accident.

## A static detector was tried and does not work — do not rebuild it

`docs/plans/guard-vacuous-assertions.md` proposed finding these statically:
a `refute` whose needle appears in no haystack the suite ever looked at.
Built and measured on 2026-08-30, this repo, 186 refutes in the suite:

| Conditions | Flagged | True positives |
| --- | --- | --- |
| needle in no haystack | 64 | 0 |
| + not a literal in any harness source | 64 | 0 |
| + shares a 20-char run with source ("message-shaped") | 4 | **0** |

All four survivors are correct assertions naming a specific bad state that
does not occur — `FINISH BEFORE STARTING: origin/bblocked` is producible and
rightly absent. The other 60 are fixture-local strings the code is right
never to print.

Worse, it is backwards on the one case it can reach. It flags
`EDGE: pull request #none` against the source that assertion was WRITTEN
against, and misses it once the message is reworded — so it goes quiet at
exactly the moment the assertion drifts out of true. And it is blind to the
2026-08-28 shape entirely, which was three `expect`s, not a `refute`.

The class is behavioural. Absence of a string cannot distinguish
absent-because-correct from absent-because-impossible; only changing the code
and re-running can.

## Scope

- A way to run the suite with a named mutation applied and reverted: file,
  line, and the replacement, so the target is unambiguous rather than a
  first-occurrence match.
- Output that names WHICH cases redded, not just the count. The PR-153 near
  miss was a wrong reading of "one case failed"; a list of case labels would
  have shown a churn case where two hook cases were expected.
- It reverts on every exit path, including interrupt. A mutation left in the
  tree is worse than no tool.

## Out of scope

- Automatic mutation generation, or a mutation score. That is a research
  project; this is a hand tool for the rule already in step 5.
- Running it in `ci`. Mutation is per-fix, not per-branch, and a suite run
  per mutation is not a gate's budget.
- Rebuilding the static detector. See above; the numbers are recorded so it
  does not get re-litigated by feel.

## Acceptance

The tool must reproduce all three instances above, from their own commits:

```
# PR 151's vacuous refute: restore it, mutate rank_of to always return 2,
# and the assertion must stay GREEN — that is the defect being demonstrated.
# PR 153's near miss: mutating joharness.sh line 792 and line 834 must give
# visibly different case lists, and the tool must say which line it hit.
```

Plus the ordinary bar:

```
bash .agents/harness/selftest.sh    # 0 failed
./joharness.sh ci                   # ci: pass
git status --porcelain              # empty after every run, mutation reverted
```

## Where to look

- `.agents/harness/AGENTS.md` step 5 — the rule this serves.
- `.agents/harness/selftest.sh` — `expect`, `refute`, the topic loop.
- `joharness.sh:selftest_inert_diff` and `joharness.sh:churn_top` — the two
  byte-identical guard lines behind the PR-153 near miss.

## Traps

- The tool is itself code that must fail when broken. A mutation runner that
  silently applies nothing reports a green suite, which reads as "the test
  pins nothing" — the exact wrong conclusion, reached faster.
- Never leave the mutation in the tree. Verify with `git status --porcelain`
  in the tool's own acceptance.
