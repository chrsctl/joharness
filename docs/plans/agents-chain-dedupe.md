---
plan: agents-chain-dedupe
urgency: normal
agent: opus
effort: high
needs: orchestrated-only-docs, issue-triager-role
requirement: none
scope: shared:.agents/harness/AGENTS.md, AGENTS.md, shared:.agents/docs/handover/README.md, shared:.agents/docs/product/README.md, shared:.agents/docs/agent-selection.md, shared:.agents/docs/feedback.md, docs/handover/agents-chain-dedupe.md
---

## Goal

Requester, 2026-10-09, same ask as `role-command-trim`. Every session in
every mode loads `CLAUDE.md`, root `AGENTS.md` and
`.agents/harness/AGENTS.md` — 17,776 bytes, 2,490 words
(`./joharness.sh context`, 2026-10-09). The two AGENTS files say several
things twice: harness `## Handover` restates root `## Handover` and Loop
step 6; root and harness each carry an "environment rules are not here"
paragraph; the CI-runnable `verify` clause appears in root Part 2, harness
step 5 and step 7. Root keeps its copies on purpose: a harness reading
`AGENTS.md` natively resolves no `@` imports, so root is the only text it
sees (`.agents/docs/handover/README.md` "How a session finds this", layer
1). The harness-side copy is the duplicate. Harness steps 2, 4, 5, 7 carry
history (ratification dates, "six merged edges paid" in step 4, the
`fin_strength` why) that belongs under `.agents/docs/`. State each fact
once (`.agents/docs/caveman.md`); move the why out.

## Scope

- Root `AGENTS.md` above `# Part 2 — project` — unchanged. Its
  `## Handover` section and environment paragraph are the only protocol
  text a non-Claude reader sees.
- `.agents/harness/AGENTS.md` `## Handover` and its environment paragraph
  — drop sentences root `AGENTS.md` or Loop step 6 already state; keep
  what only the harness file says.
- CI-runnable `verify` clause — keep it once in harness step 7 and once in
  root Part 2 (non-Claude readers); cut step 5's copy to a pointer at
  step 7.
- `.agents/harness/AGENTS.md` steps 2, 4, 5, 7 — move history and
  why-explanations to the doc the sentence already cites, ONLY if that doc
  is one of: `.agents/docs/product/README.md`,
  `.agents/docs/handover/README.md`, `.agents/docs/agent-selection.md`,
  `.agents/docs/feedback.md`. Cites another doc? Leave it in place and say
  so in the ledger. Keep every rule, every command, every "NEVER".
- `docs/handover/agents-chain-dedupe.md` `## Review` — ledger, one line
  per removed block: `moved to <file>:<heading>` or
  `duplicate of <file>:<line>`.

## Out of scope

- Mode text in steps 2 and 7 (unsupervised/orchestrated). Plan
  `orchestrated-only-docs` owns it; this plan reads its result.
- Rewording kept rules. Moving, not editing.
- Command files — plan `role-command-trim`.
- `CLAUDE.md` (56 words, one import).
- A size gate (`.agents/docs/caveman.md`: reports, never gates).

## Acceptance

- `./joharness.sh context` — `instructions` row lower than the merge base;
  record before/after words with the command in the workstream file.
- `cat AGENTS.md .agents/harness/AGENTS.md | grep -c 'CI-runnable'` — at
  most 2 (today 3).
- `diff <(git show origin/main:AGENTS.md | sed '/^# Part 2 — project$/q') <(sed '/^# Part 2 — project$/q' AGENTS.md)`
  — no output (root Part 1 untouched).
- `grep -q 'no commit to a core path' .agents/harness/AGENTS.md` — exit 0
  (pinned by `.agents/harness/selftest/handover-context-compact.sh`, case
  "THE BOUNDARY THE MODE KEEPS").
- `grep -c '^# Part 2 — project$' AGENTS.md` — `1`.
- Verifier reads the ledger against the diff; finding tagged
  `(verifier)` in `## Review`.
- `./joharness.sh ci` — `ci: pass`. `./joharness.sh verify` — 0 failed.
- Plan `ci` calls SHIPS: root `AGENTS.md` Part 1 and the harness file
  sync to every consumer; `./joharness.sh ci` in a consumer checkout is
  the check.

## Where to look

- `joharness.sh:ctx_report` — the counted chain.
- `.agents/scripts/sync-to-consumer.sh:MARKER` — splice on
  `# Part 2 — project`; Part 1 edits travel, the marker must stay exact.
- `.agents/harness/selftest/handover-context-compact.sh` — cases "points
  at the Loop by file" and "THE BOUNDARY THE MODE KEEPS" pin the harness
  file.
- `.agents/docs/handover/README.md` "How a session finds this", layer 1 —
  why root `## Handover` exists and must stay.
- `.agents/harness/selftest/bootstrap-consumer.sh`,
  `.agents/harness/selftest/ci-promote.sh` — fixtures write the harness
  file; read before assuming nothing reads its text.
- `.agents/docs/consumer-repos.md` "2026-09-11 cutting" — the last trim of
  this file and the fact it nearly lost.

## Traps

- `orchestrated-only-docs` and `issue-triager-role` both edit
  `.agents/harness/AGENTS.md` (`needs:`). Start from their merged text.
- Pointer to a file a consumer lacks = lost fact; destinations must sync
  (`.agents/docs/`).
- Moving the why out must not move a rule out. A sentence with NEVER,
  only, not, or a command stays.
- Glossary spellings unchanged; `ci` reds banned ones.
- NEVER edit core paths (`./joharness.sh protocol-paths`).
