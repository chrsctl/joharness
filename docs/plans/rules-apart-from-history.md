---
plan: rules-apart-from-history
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/handover/README.md, .agents/docs/consumer-repos.md, .agents/docs/history/handover.md, .agents/docs/history/consumer-repos.md, shared:.agents/harness/AGENTS.md, .agents/harness/selftest/reading-budget.sh, shared:.agents/harness/selftest.sh
---

## Goal

A manager reads about 69 KB of rules before opening its plan (counted
2026-10-13 on `origin/main`, `wc -c`: `manage.md` 12,184, `plans/README.md`
13,310, `handover/README.md` 22,234, `agent-selection.md` 10,083,
`subagents.md` 5,376, `verifier.md` 5,586; 68,773 in all). The large rule
documents interleave rule lines with the dated incidents that produced them,
so every reader pays for every past measurement. The caveman discipline keeps
`AGENTS.md` small so that a rule's "why" lives elsewhere; this plan applies
the same split one level down for the two documents nothing else in flight
is editing: `handover/README.md` (22,234 bytes) and `consumer-repos.md`
(26,506 bytes). `orchestrated.md` (39,424 bytes) is the third candidate and
is left for a later plan: seven open plans edit it today.

## Scope

- `.agents/docs/history/handover.md` and `.agents/docs/history/consumer-repos.md`
  — append-only, each moved paragraph under a heading naming the rule it
  measured and the date. Nothing is deleted from history: `git log -p` of
  the source and the history file together recover every sentence.
- `.agents/docs/handover/README.md`, `.agents/docs/consumer-repos.md` — each
  rule keeps its one-line statement and gains `(why: history/<name>.md §
  <heading>)`, naming one of the two files above; paragraphs that are
  measurement, incident narrative or rejected alternatives move.
- `.agents/harness/AGENTS.md` — the line "Why lives in `.agents/docs/`"
  names `.agents/docs/history/` as where.
- `.agents/harness/selftest/reading-budget.sh`, registered in
  `SELFTEST_TOPICS` — counts the bytes of a listed set per role and compares
  to a written bound, printing both. The manager set is the six files
  above; bound 60,000 (68,773 today less half of `handover/README.md`,
  rounded up, so the case is red until this plan's split lands and green
  after). The sync set is `consumer-repos.md` alone; bound 14,000 (half of
  26,506). Over the bound = red, naming the largest file.

## Out of scope

- Rewording any rule. A rule line moves nowhere and changes nothing.
- `orchestrated.md`, `agent-selection.md`, `feedback.md`, `plans/README.md`:
  a later plan each, once the plans editing them have landed.
- The role commands (`role-prelude-command` shortens those).
- Deleting history: append-only means append-only.

## Acceptance

- `wc -c .agents/docs/handover/README.md .agents/docs/consumer-repos.md` —
  each at most half its byte count on `origin/main` at the plan's start;
  quote both counts.
- `bash .agents/harness/selftest.sh` — `reading-budget.sh` passes with both
  sets under their bounds, printing the counted bytes; `./joharness.sh ci` —
  `ci: pass` (glossary lint over the moved text included).
- Test for the fix must FAIL without it: on `origin/main` with only the new
  selftest part applied, `reading-budget.sh` is red (68,773 > 60,000);
  quote the line.
- For three rules the verifier picks, `grep -n` the rule line in the README
  and the quoted paragraph in `history/`: both present, pointer resolves.
- Plan `ci` calls SHIPS (`.agents/docs` syncs; the selftest does not): the
  consumer check is `wc -c .agents/docs/handover/README.md
  .agents/docs/consumer-repos.md` on gx after sync, the same two numbers.

## Where to look

- `.agents/docs/caveman.md` — the style rule this plan extends downward.
- `.agents/harness/AGENTS.md` — "Why lives in `.agents/docs/`".
- `.agents/docs/handover/README.md:## Graduation` — a section that is mostly
  measurement; a worked example of what moves and what stays.
- `.agents/docs/consumer-repos.md` — "Conflict at finish" and the migration
  section, incident-shaped.
- `joharness.sh:lint_glossary` — what the moved text must still satisfy.
- `.agents/harness/selftest.sh` — `SELFTEST_TOPICS`.

## Traps

- Never blanket find-and-replace: move paragraphs by hand, re-read every
  pointer, and check each `(why: …)` resolves.
- A `.agents/docs/*.md` heading is cited from `AGENTS.md`, role commands,
  `joharness.sh` and the selftest: `grep -rn` every heading before moving
  its paragraph; cited headings stay in the README.
- Contested terms have one spelling: the history files are linted too.
