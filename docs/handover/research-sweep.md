---
workstream: research-sweep
status: in-progress
branch: claude/research-sweep
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-25
next: Fill the three Verification sections from the citation pass, then open PR — stacked on PR 63
---

## Goal

Requester: research, using the new framework, similar approaches for
everything else in the queue. Three research files, each following the
shape `docs/plans/research-node.md` defines, on the three queued plans
where external practice plausibly exists.

## Decisions

- Stacked on `claude/research-capability` (PR 63), not cut from `main`.
  These files use a shape that PR 63 defines; cutting from `main` would
  have produced files describing a template no branch carried. Rebase when
  63 lands.
- Three of sixteen plans, chosen because literature could plausibly answer
  them. The environment plans (`k8s-136-validation`, `smoke-*`,
  `devenv-status-stall`) are local-sandbox questions no external source
  would know; the `unsupervised-*` family was researched earlier tonight.
  Coverage stated rather than implied — a sweep that does not say what it
  skipped reads as exhaustive.
- Every `Sweep` field says goal-directed, and each file says what it
  therefore did NOT look at. John's `sweep-strategy` makes this the field
  that decides whether "complete" is falsifiable.
- Verification left PENDING in all three rather than written as done. The
  framework says a finding no second context checked is not settled, and
  writing the section optimistically would have been the first violation of
  the rule this branch exists to test.

## Rejected

- Filing research for all sixteen plans. Most have no external answer, and
  a research file that concludes "no literature applies" costs a reader the
  same as one that found something.
- Editing the three plans this research bears on. The findings belong in
  the research files until verified; a plan changed on unverified research
  is worse than one changed on none, because it looks sourced.
- Writing Verification myself. Same context that produced the findings —
  precisely what the diamond rule and John's grounding-checker forbid.

## Review

- r1: the `compact-reorient` finding contradicts a plan already on `main`.
  Recorded in the research file's `Consequence for the queue` rather than
  by editing the plan, so the claim and its evidence travel together and a
  reader can weigh both. (fixed — deliberate placement)
- r2: `glossary-enforcement`'s central finding is a NEGATIVE — that no
  tooling prior art exists — reached from one goal-directed sweep. Absence
  from a narrow sweep is the weakest claim shape there is, so the file says
  so in its own Findings and the verification pass was asked specifically
  to try to refute it comprehensively. (fixed)
- r3: docs-only diff, so `verify` is out of scope. `ci` passes; the graph
  lint does not yet know `docs/research/`, which is `research-node`'s job,
  so these files are linted as ordinary docs today. (no change needed)

## Blockers

None, but not finishable: the three Verification sections stay PENDING
until the citation pass reports. Do not open the pull request before then —
the framework's own rule is that an unverified finding is not settled.

## Where to look

- `docs/research/compaction-what-survives.md` — the finding that
  `compact-reorient` names the wrong risk.
- `docs/research/scorecard-without-gaming.md` — Goodhart, and the two
  things `process-scorecard` does not say.
- `docs/research/glossary-enforcement.md` — the negative claim, and the
  Bounded Context finding that matters more than it.
- `docs/plans/research-node.md` — the shape all three follow.
