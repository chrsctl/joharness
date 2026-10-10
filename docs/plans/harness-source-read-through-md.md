---
plan: harness-source-read-through-md
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 390
scope: shared:.agents/harness/AGENTS.md, shared:joharness.sh, shared:.agents/docs/consumer-repos.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

Product session in a consumer (manager and workers, clerk, curator, an
orchestrator running janitor) learns harness only from its `.md` docs and
`./joharness.sh <command>` output. Opening `joharness.sh` (5554 lines on
`298b9ac`) to learn what a command does spends context on harness internals
instead of item. Commands print verdicts and remedies; `.md` docs carry the
why. Write the rule down where every session reads it.

## Scope

- `.agents/harness/AGENTS.md` — Loop step 4 (Build): one rule line. Consumer
  session on product work opens no non-`.md` file under `joharness.sh`,
  `.agents/harness/`, `.agents/scripts/`, `.agents/env/`; reads `.md` docs
  and command output instead. A plan anchor pointing into those files =
  anchor wrong, not reader. Exempt: canonical (`JOHARNESS_CANONICAL=1`), a
  sync or upgrade task, verifier on a diff touching those files. Caveman
  file: every line loads every session, keep it to the fewest lines.
- `joharness.sh` — `cmd_session_start` orchestrated banner: after "Each role
  reads its own documents and no others", one line saying harness source is
  read through its `.md` docs and command output, printed only when
  `JOHARNESS_CANONICAL=1` is absent from conf.
- `.agents/docs/consumer-repos.md` — beside "Context rule": the why
  (context cost, commands print their remedies), the exemptions, and that
  a product diff touching those files is harness work, routed per the
  Direction rule (so step 7's `verify` clause never meets a product diff).
- `.agents/harness/selftest/orchestrated.sh` — consumer conf: banner
  carries the new line; canonical conf: banner does not.

## Out of scope

- A measured signal (feedback on a session that `Read`s `joharness.sh`).
  Needs a `Read` matcher in `.claude/settings.json`, a core path. Settled
  here: sentence only. Flag for human in PR body if wanted.
- Rewording any role command's "What you read" line. AGENTS.md step 4 is
  the one place; a second copy rots.
- Step 7 merge gate text. Unchanged: a product diff on those paths is
  harness work, exemption covers it.

## Acceptance

- `grep -c '\.agents/scripts/' .agents/harness/AGENTS.md` — `2` (was `1`:
  step 7 only; new hit in step 4).
- `bash .agents/harness/selftest.sh` — new orchestrated assertions pass;
  revert the `joharness.sh` change, the consumer-conf assertion FAILS.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS. Selftest does not ship (`sync-to-consumer.sh`
  `CANONICAL_ONLY` / `CANONICAL_ONLY_DIRS`). Consumer check: in a consumer
  after sync, orchestrated mode, `./joharness.sh session-start </dev/null`
  — banner prints the new line; `grep -c '\.agents/scripts/'
  .agents/harness/AGENTS.md` — `2`.

## Where to look

- `joharness.sh:cmd_session_start` — banner `printf` "Each role reads its
  own documents and no others".
- `.agents/harness/AGENTS.md` — Loop step 4 "Build".
- `.agents/docs/consumer-repos.md` — "Context rule" paragraph.
- `.agents/harness/selftest/orchestrated.sh` — `expect "the banner names
  the boundary"` block.
- `joharness.sh:cmd_upstream` — how a command tests `JOHARNESS_CANONICAL=1`.

## Traps

- `.agents/harness/` names no specific environment; rule names paths, not
  layers.
- Glossary spellings only: workstream file, agent tier, environment layer.
- Never skip, disable or quarantine a test to get green.
- No commit under `./joharness.sh protocol-paths`.
