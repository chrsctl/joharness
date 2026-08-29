---
workstream: glossary-enforcement
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: glossary-enforcement
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Spawn the verifier, fold the round into ## Review, then retire and open the PR.
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

- **The graduation could not quote its own evidence, and that is the finding
  demonstrating itself.** Writing the measured drift into
  `.agents/docs/caveman.md` failed `ci`'s own `== glossary` stage, because the
  paragraph spelled the banned form. The recount one-liner now reads the ban
  out of `.agents/docs/glossary.md` instead of hard-coding it — no second copy
  of the thing, which is the glossary's own rule about rows.
- **Scope of the lint, checked rather than assumed.** `GLOSSARY_PATHS` covers
  `.agents/docs/*`, `.agents/harness/*`, `.agents/scripts/*`,
  `.agents/env/README.md`, `.claude/commands/*`, `.claude/skills/*`,
  `AGENTS.md`, `CLAUDE.md`, `joharness.sh`. Not `docs/`. So the research file
  quoting the banned form is legitimately out of scope and the graduation
  target is legitimately in it — which is why one passes and the other had to
  be rewritten.

## Rejected

- **Re-deriving the findings instead of re-running the sources.** The third
  pass fetched `docs.vale.sh` and `martinfowler.com` and kept the queries; a
  pass that reasoned to the same conclusions from memory would have produced
  a Method section as unreproducible as the one it replaced.
- **Graduating the file's own `## Consequence for the queue` as written.** It
  named a decision still to be made ("adopt or build") for a plan that had
  already shipped. Graduating it would have handed the next session a live
  question that is closed, which is the exact failure the protocol's
  Graduating section says the why-explanation exists to prevent.

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
