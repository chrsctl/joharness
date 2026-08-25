---
workstream: research-sweep
status: in-progress
branch: claude/research-sweep
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-25
next: Open PR — stacked on PR 63; all three Verification sections now filled
---

## Goal

Requester: research, using the new framework, similar approaches for
everything else in the queue. Four research files, each following the
shape `docs/plans/research-node.md` defines: three on queued plans where
external practice plausibly exists, and one on the harness's own
orchestration, added when the requester asked about it.

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

- r4: the citation pass refuted the central claim of
  `glossary-enforcement`. Controlled-vocabulary linting is mature and in
  production — Vale's `accept.txt` plus `Vale.Terms` is exactly the
  mechanism `harness-glossary` proposed to invent, running at Datadog and
  Elastic, and `textlint-rule-terminology` does the same for tech writing.
  A DDD Ubiquitous Language Verifier exists too. The file is rewritten and
  the plan's question changes from invent-or-not to adopt-or-build.
  (fixed)
- r5: `scorecard-without-gaming` quoted DORA for a sentence DORA never
  wrote. No DORA, Google Cloud or Accelerate source carries "individual
  metrics create competition while team metrics create collaboration";
  dora.dev's real text is about team-versus-team siloing, a narrower
  proposition. Replaced. This was the claim the file had itself flagged for
  checking, which is the flag working. (fixed)
- r6: the Goodhart one-liner is not Goodhart's. His 1975 wording is
  different; the popular sentence is Strathern (1997) citing Hoskin. Now
  used as "commonly stated as", with Austin cited as the academic anchor
  instead of an asserted literature consensus. (fixed)
- r7: "stale language" is not established DDD vocabulary. Retracted rather
  than reworded — presenting a coinage as a term of art is the same failure
  class as the DORA misquote. (fixed)
- r8: the 10% compaction figure was stated as best practice. It is
  LangChain's default; Inspect AI defaults to 0.8, and no source gives a
  measured optimum. The verifier also noted the original search summary
  restated the claim back rather than corroborating it — a search echoing
  your own phrasing is not a second source, and this branch treated one as
  such. (fixed)
- r9: one of six claims survived the pass fully intact. Recorded because
  the number is the argument for the Verification section existing at all,
  and a later session weighing whether to keep it should see the ratio.
  (fixed — no change needed beyond recording)

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

- r10: the orchestration file's two throughput figures both failed the
  citation pass — 6.7 tasks/second is one blog's `20 ÷ 3` thought
  experiment reprinted verbatim on a second site, and 950ms against 500ms
  is another blog's hedged estimate. Both dropped. Flagging them before
  publishing was right; the file would have read as quantified either way.
  (fixed)
- r11: "nine orchestrators tested, all use worktrees" is a vendor listicle
  with no methodology, and one of the nine lists worktrees as optional. The
  "all" was false. Dropped; the conclusion it supported survives on the
  file-isolation quote, which verified GROUNDED. (fixed)
- r12: the centralized-versus-peer trade was written as though it were
  settled literature. The verifier could not find the quoted phrasing in
  any source. Reworded as industry consensus. (fixed)
- r13: the verification found something the research missed entirely —
  Claude Code ships agent teams with three task states, self-claim and
  FILE LOCKING against claim races, storing the list at
  `~/.claude/tasks/{team-name}/`. joharness reimplements that on git. Named
  as an adopt-or-build question and deliberately not answered here: the
  built-in is experimental and keeps state outside the repo, against a
  harness whose doctrine is that git holds the state. (fixed — recorded,
  not decided)
- r14: across both passes on this branch, every number that arrived through
  a search summary was weaker than it read, and every claim that survived
  came from a primary source stating it directly. Recorded because it is a
  usable rule for the next researcher, not a one-off. (fixed)

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
- `docs/research/orchestration-shape.md` — the harness's own orchestration
  measured against its architecture class; verification pending.
- `docs/plans/research-node.md` — the shape all four follow.
