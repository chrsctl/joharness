---
plan: agents-chain-dedupe
urgency: normal
agent: opus
effort: high
needs: orchestrated-only-docs, issue-triager-role
requirement: none
scope: shared:.agents/harness/AGENTS.md, AGENTS.md, shared:.agents/docs/handover/README.md, shared:.agents/docs/product/README.md, shared:.agents/docs/agent-selection.md
---

## Goal

Requester, 2026-10-09, same ask as `role-command-trim`. Every session in
every mode loads `CLAUDE.md`, root `AGENTS.md` and
`.agents/harness/AGENTS.md` — 17,776 bytes, 2,490 words
(`./joharness.sh context`, 2026-10-09). The two AGENTS files say several
things twice: root `## Handover` restates harness `## Handover` and Loop
step 6; root and harness each carry an "environment rules are not here"
paragraph; the CI-runnable `verify` clause appears in root Part 2, harness
step 5 and step 7. Harness steps 7, 2, 5 hold 1,500 of its 2,080 words
and carry history (ratification dates, "six merged edges paid", the
`fin_strength` why) that belongs under `.agents/docs/`. State each fact
once (`.agents/docs/caveman.md`); move the why out.

## Scope

- Root `AGENTS.md` above `# Part 2 — project` — drop the `## Handover`
  bullets and the environment paragraph where the harness file already
  says the same; keep one pointer line each if the root file must still
  name the protocol file.
- Root `AGENTS.md` Part 2 — keep the verify block; cut the CI-runnable
  explanation down to a pointer at harness step 7 where step 7 already
  states it.
- `.agents/harness/AGENTS.md` steps 2, 5, 7 — move history and
  why-explanations to the doc each already cites (`.agents/docs/product/README.md`
  Branch flow, `.agents/docs/handover/README.md`,
  `.agents/docs/agent-selection.md`). Keep every rule, every command,
  every "NEVER".
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
- `grep -c 'CI-runnable' AGENTS.md .agents/harness/AGENTS.md` — total at
  most 2 (today 3).
- `grep -n '^## Handover' AGENTS.md` — no output, or the section is a
  single pointer line.
- `grep -q 'no commit to a core path' .agents/harness/AGENTS.md` — exit 0
  (pinned by `.agents/harness/selftest/handover-context-compact.sh:70`).
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
- `.agents/harness/selftest/handover-context-compact.sh:55,70` — pins on
  the harness file.
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
