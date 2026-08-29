---
workstream: glossary-enforcement
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: glossary-enforcement
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Re-run the sweep with recorded queries, then graduate into caveman.md.
---

## Goal

Close `docs/research/glossary-enforcement.md`: is there established practice
for mechanically enforcing a controlled vocabulary in documentation, or was
`harness-glossary` inventing one? Answer graduates to
`.agents/docs/caveman.md`; the research file is deleted by the same pull
request.

## Decisions

- **The findings are already recorded and already verified from a second
  context.** The work left is the graduation, not the research. What this
  branch adds is a re-run with the queries kept — the protocol names this
  file as its one instance whose method "cannot be re-run as written", and a
  graduation resting on unreproducible findings inherits that.
- **The file's `## Consequence for the queue` is stale and must not be
  graduated as written.** It says the question is now "adopt or build" for
  `docs/plans/harness-glossary.md`. That plan is gone and the thing is
  BUILT: `.agents/docs/glossary.md` and `lint_glossary` are on `main`, and
  `ci` runs a `== glossary` stage. So the graduation records what was
  decided and why, not a choice still to make.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `docs/research/glossary-enforcement.md` — the question, findings and the
  verification pass this closes.
- `.agents/docs/research/README.md`, Graduating — the answer carries the
  why-explanation, not only a rule line, or the question comes back.
- `.agents/docs/glossary.md` and `joharness.sh:lint_glossary` — what was
  actually built.
