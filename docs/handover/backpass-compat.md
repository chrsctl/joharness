---
workstream: backpass-compat
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: backpass-compat
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: Finish — delete plan + workstream files, open PR, merge
---

## Goal

Human asked: "Review usage https://github.com/kunchenguid/backpass", then
"Adapt". Review delivered in session (summary in Decisions). Adaptation =
shape this repo so backpass runs clean here and in consumers. Plan:
`docs/plans/backpass-compat.md`.

## Decisions

- Review verdict (from backpass source, v0.1.8): tool sound — zero runtime
  deps, 30 test files, mandatory verbatim-quote evidence, staged-diff edits,
  apply freshness gate. Three misfits for us: (1) no `@` import resolution,
  audits ONE file (`src/prompts/analysis.md` `{{MEMORY_PATH}}`); (2) reads
  local transcript stores only — remote-container sessions invisible; (3)
  default `skillsDir` `.agents/skills` collides with two-layer rule.
- Adapt repo, not tool: CLAUDE.md pure pointer (its `isPointerTo` strips HTML
  comments, then requires exactly `@AGENTS.md`), Handover summary into
  AGENTS.md Part 1. Fixes canonical + consumers via existing sync (CLAUDE.md
  synced whole, Part 1 spliced at marker).
- Handover summary lands in root AGENTS.md not `.agents/harness/AGENTS.md`:
  non-Claude harnesses load root AGENTS.md natively, resolve no imports —
  summary there reaches them; harness file already has own `## Handover`.

## Rejected

- `memoryFiles` pointing at `.agents/harness/AGENTS.md`: backpass optimizes
  only FIRST existing entry; root file then invisible, and consumers must not
  edit harness layer. Inverts the blindness, fixes nothing.
- Waiting on upstream import resolution: human said adapt, not wait.
- Syncing `.backpassrc.json` to consumers: per-repo file class
  (like `joharness.conf`); premature before canonical use proves config.

## Review

/code-review high, full branch diff vs main, 2026-08-28. Reviewer verified
pointer purity, splice-marker safety, sync propagation against backpass
source + sync script. Four doc-accuracy findings, no functional bugs:

- r1: backpass.md sends optimizable rules to root AGENTS.md without warning
  a consumer-side Part 1 edit breaks sync (AHEAD forever, updates stop).
  (fixed: consumer bullet — Part 2 only, Part 1 fixes land in joharness)
- r2: backpass.md described canonical's `.backpassrc.json` but file is not
  synced — consumer following doc gets colliding `.agents/skills` default.
  (fixed: consumer creates own rc file, stated in bullet)
- r3: "at most five edits per run" false over budget — backpass cap is
  adaptive, up to 20 in shrink plan. Written number, wrong in reachable
  case. (fixed: adaptive cap stated)
- r4: .gitignore comment said only `backpass init` writes
  `.git/info/exclude`; backpass writes it idempotently on every command.
  (fixed: comment reworded)

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — top comment block: what syncs whole
  (CLAUDE.md), what splices (AGENTS.md at `# Part 2 — project`).
- backpass `src/memory.js:isPointerTo` — the exact purity rule CLAUDE.md now
  satisfies.
