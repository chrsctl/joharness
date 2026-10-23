---
plan: role-file-diet
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrate-reference.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

The owner asked (session 2026-10-23) to cut token usage. Measured that day:
each session loads only about 2,000 tokens of always-on rules (the
`AGENTS.md` chain, 7.8 KB) plus a 1.7 KB banner, but every orchestrator
loads `.claude/commands/orchestrate.md` whole (609 lines, 41.5 KB, about
10,000 tokens). It also re-reads the file whole on the pass after any change
to it ("Pass entry"). Its largest sections are "2. Health pass" (10.6 KB),
"3. Spawn" (7.3 KB), "4. Schedule" (6.4 KB) and "0. Start" (6.1 KB, once per
session). Most of that text covers rare branches: degraded tools, recovery,
heartbeat repair. Cut what every pass loads to 22 KB or less, without
changing any behaviour.

## Scope

- `.claude/commands/orchestrate.md` — keep every rule a normal pass runs:
  - the decision rows;
  - the spawn and schedule steps;
  - the report;
  - Never.

  Move rare branches into a new `.agents/docs/orchestrate-reference.md`,
  one `##` section per branch: degradation tables, recovery and repair
  paths, worked examples, and the rationale paragraphs. At each cut point,
  leave one line saying when to read which section of the reference ("tool
  X fails → read `orchestrate-reference.md` § X").
- `.agents/docs/orchestrate-reference.md` — the moved text, verbatim. No
  rewording, so no rule changes meaning.
- `.agents/harness/selftest/orchestrated.sh` and any other selftest that pins
  `orchestrate.md` text (`grep -rln "orchestrate.md" .agents/harness/selftest`,
  24 references) — a pin whose text moved now reads the reference file. Add
  pins for the pointer lines, so every moved section is reachable from
  `orchestrate.md`.

## Out of scope

- `.claude/commands/manage.md` (16 KB) and `clerk.md` (14 KB): a separate
  decision after this one is measured.
- Changing any rule, threshold or step order.
- The "Pass entry" re-read rule itself.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `wc -c .claude/commands/orchestrate.md` — 22,000 or less.
- `cat .claude/commands/orchestrate.md .agents/docs/orchestrate-reference.md
  | wc -c` — within 5% of the original 41,573 bytes, and no rule text was
  dropped. In `## Review`, list each moved section and the pointer that
  reaches it.
- Every selftest pin still passes, none removed.
- Plan `ci` calls SHIPS: both files and the selftest reach every consumer.

## Where to look

- `.claude/commands/orchestrate.md` sections `## 0. Start`, `## 2. Health
  pass`, `## 3. Spawn`, `## 4. Schedule`, `## Report, every pass`.
- `.claude/commands/keeper.md` — how the keeper split was done (same
  pattern).
- `.agents/docs/caveman.md` — style for the pointer lines.

## Traps

- A rule the orchestrator needs on a normal pass must not move: when unsure,
  keep it in `orchestrate.md`.
- NEVER skip, disable or quarantine a test.
- Docs state status quo: move rationale verbatim, add no history.
- No core paths.
