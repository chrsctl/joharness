---
plan: rules-apart-from-history
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/handover/README.md, shared:.agents/docs/orchestrated.md, .agents/docs/consumer-repos.md, .agents/docs/history/handover.md, .agents/docs/history/orchestrated.md, .agents/docs/history/consumer-repos.md, shared:.agents/harness/AGENTS.md, .agents/harness/selftest/reading-budget.sh
---

## Goal

A manager reads about 67 KB of rules before opening its plan (measured
2026-10-13, `wc -c`: `manage.md` 10.8 KB, `plans/README.md` 13.2 KB,
`handover/README.md` 22.2 KB, `agent-selection.md` 10.1 KB, `subagents.md`
5.4 KB, `verifier.md` 5.6 KB). The three largest rule documents —
`handover/README.md` 465 lines, `orchestrated.md` 498, `consumer-repos.md`
551 — interleave rule lines with the dated incidents that produced them, so
every reader pays for every past measurement. The caveman discipline keeps
`AGENTS.md` at 6.9 KB precisely so that a rule's "why" lives elsewhere; this
plan applies the same split one level down: rules stay, each incident
paragraph moves to an append-only history file the rule points at, and a
selftest bounds what each role must read.

## Scope

- `.agents/docs/history/<doc>.md` — one file per split document
  (`handover.md`, `orchestrated.md`, `consumer-repos.md`), append-only,
  holding every moved paragraph under a heading that names the rule it
  measured and the date. Nothing is deleted: `git log -p` of the source
  file and the history file together recover every sentence.
- `.agents/docs/handover/README.md`, `.agents/docs/orchestrated.md`,
  `.agents/docs/consumer-repos.md` — each rule keeps its one-line statement
  and gains `(why: history/<doc>.md § <heading>)`; paragraphs that are
  measurement, incident narrative or rejected alternatives move. The
  knob table in `orchestrated.md` stays whole (it is rules).
- `.agents/harness/AGENTS.md` — the line "Why lives in `.agents/docs/`"
  names `.agents/docs/history/` as where.
- `.agents/harness/selftest/reading-budget.sh` — for each role command,
  the bytes of the command plus every document it tells the role to read
  WHOLE, against a written bound per role: manager 40,000, orchestrator
  35,000, clerk 25,000, scout 25,000, curator and conduct 20,000 (from the
  67 KB measured for the manager; the numbers are written, the case
  prints the counted ones beside them). Over the bound = red, naming the
  largest file.

## Out of scope

- Rewording any rule. A rule line moves nowhere and changes nothing; only
  the prose around it moves.
- `agent-selection.md`, `feedback.md`, `plans/README.md`: measured, but
  under the bound once the three above are split; a later plan if not.
- The role commands themselves (`role-prelude-command` shortens those).
- Deleting history: append-only means append-only.

## Acceptance

- `wc -c .agents/docs/handover/README.md .agents/docs/orchestrated.md .agents/docs/consumer-repos.md`
  — each at most half its byte count on `origin/main` at the plan's start;
  quote both counts.
- `bash .agents/harness/selftest.sh` — `reading-budget.sh` passes with
  every role under its bound, printing the counted bytes; `./joharness.sh ci`
  — `ci: pass` (glossary lint over the moved text included).
- For three rules chosen by the verifier, `grep -n` the rule line in the
  README and the quoted paragraph in `history/`: both present, pointer
  resolves.
- Plan `ci` calls SHIPS (`.agents/docs` syncs): the consumer check is
  `bash .agents/harness/selftest.sh` on gx after sync, where the budget
  case counts gx's copy.

## Where to look

- `.agents/docs/caveman.md` — the style rule this plan extends downward.
- `.agents/harness/AGENTS.md` — "Why lives in `.agents/docs/`".
- `.agents/docs/handover/README.md:## Graduation` — a section that is mostly
  measurement, a worked example of what moves and what stays.
- `.agents/docs/orchestrated.md:## Start each run fresh` — rule plus
  incident in one paragraph; the shape to split.
- `joharness.sh:lint_glossary` — what the moved text must still satisfy.

## Traps

- Never blanket find-and-replace: move paragraphs by hand, re-read every
  pointer, and check each `(why: …)` resolves.
- A `.agents/docs/*.md` path is cited from `AGENTS.md`, role commands and
  the selftest: `grep -rn` every moved heading before moving it.
- Contested terms have one spelling: the history files are linted too.
