---
plan: guard-docs-only-branch
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: .agents/harness/handover-guard.sh, .agents/harness/selftest.sh
---

## Goal

The handover guard's comment and its filter disagree, and a consumer run
hit it. The comment says:

    # Only when the branch actually changes code (protocol dirs excluded,
    # same split as the churn measure): copy/sync tasks legitimately carry
    # no file, and a docs-only branch is its own record.

The filter is `grep -vE '^docs/(handover|plans|product)/'`, so the root
`AGENTS.md` counts as code. Measured 2026-08-25 in `chrsctl/redocted`: a
branch whose entire diff was

    AGENTS.md
    docs/product/full-pipeline.md

tripped the guard at every stop. That branch was documentation only — it
corrected two files that described finished work as open — and the guard's
own sentence says such a branch is its own record.

Two defensible answers, and the plan is to CHOOSE one and make the code
and the comment agree, not to assume which:

1. **`AGENTS.md` is documentation.** Exclude root `*.md` from the code
   filter. Cheap, matches the comment, and a session changing a rule still
   writes a workstream file when it is doing rule WORK — because that work
   touches `.agents/` too.
2. **`AGENTS.md` is protocol.** A branch rewriting the rules the next
   session obeys should hand over. Then the comment is wrong and must say
   so: "docs-only" means `docs/`, and the root instruction files count.

Answer (2) is the safer default and (1) is what the comment promises.
Whichever wins, the defect is that a reader cannot tell which the guard
means.

## Scope

- `.agents/harness/handover-guard.sh` — the filter and its comment, made
  to agree.
- `.agents/harness/selftest.sh` — a branch touching only root `AGENTS.md`
  asserts the chosen behaviour by name, so the next reader sees a decision
  rather than an accident.

## Out of scope

- **The churn measure's filter.** It shares this split deliberately
  ("same split as the churn measure"). If the two must diverge, that is a
  separate plan with its own reasoning; silently forking them here would
  break the sentence that ties them together.
- **Any other guard fact** (uncommitted changes, unpushed commits).

## Acceptance

- A fixture branch whose only change is root `AGENTS.md`: the guard's
  output matches the chosen answer, asserted by a named selftest.
- A fixture branch touching `.agents/harness/*.sh` still trips the guard,
  whichever answer is chosen — that case must not regress.
- A fixture branch touching only `docs/plans/` still passes.
- `./joharness.sh ci` — `ci: pass`. Prove the new test goes red.

## Where to look

- `.agents/harness/handover-guard.sh`, the `code_changed` filter and the
  comment block above it.
- The churn measure in `joharness.sh`, which the comment ties this to.

## Traps

- The guard fires at Stop, when a session is least attentive. A guard that
  cries wolf on documentation is one a session learns to dismiss — which
  is the same failure mode as an unenforced gate.
