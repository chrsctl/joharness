---
plan: role-session-standard-lines
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 427
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/clerk.md
---

## Goal

Role sessions (clerk, curator, scout) are spawned with the manager's
standard lines, including "Claim by pushing your workstream file before any
code… One item, then exit". clerk.md §1 says the clerk writes NO workstream
file, so each clerk has to choose between two instructions.

clerk.md's read list also allows "the source each issue cites" but forbids
"the design doc". When an issue cites the design doc (#251 cites
`.agents/docs/orchestrated.md`), the clerk must break one of the two
rules.

Finally, the 2026-10-12 clerk:
- chained `curate --apply; curate; ci` in one foreground call and hit the 120s timeout;
- was blocked on `sleep 100`;
- then ran a 55×`sleep 10` loop, the workaround the block forbids.

Remove the contradictions and say how to wait for `ci`.

## Scope

- `.claude/commands/orchestrate.md` §3: role-session spawns get their own
  standard lines. They are:
  - "Run ./joharness.sh protocol-paths and never commit under those paths."
  - "Push at every milestone. One pass, then exit."
  - The lead line, when a transport exists, unchanged.

  They carry no workstream-file claim line. Keep "the standard lines" as
  the manager's term, and name the role set with one new term. If the
  term is contested, add it to `.agents/docs/glossary.md`.
- `.claude/commands/clerk.md`, "What you read": add "the design doc only
  where an issue cites it, only the cited section, plus the files the plan
  you write names as anchors".
- `.claude/commands/clerk.md` §4: add one line. Run `./joharness.sh ci` (and
  `curate`) with the Bash tool's background mode, one command per call.
  Wait for its completion notification and never loop on `sleep`.

## Out of scope

- Prompts for `/curate` and `/scout` beyond the shared role lines. Their command files already say what they write.
- Making `ci` faster.
- Any `joharness.sh` change.

## Acceptance

- `grep -c "Claim by pushing your workstream file" .claude/commands/orchestrate.md` — the manager block still has it, and the role-session bullet no longer points at it.
- `grep -n "background" .claude/commands/clerk.md` — the new §4 line.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.claude/commands/orchestrate.md` §3, "Role sessions, at most ONE of each per run… prompt = the command + the standard lines", and the manager prompt block that defines "the standard lines".
- `.claude/commands/clerk.md`, "What you read", §1 and §4.
- `.agents/docs/glossary.md` — one spelling per contested term; `ci` lints it.

## Traps

- `ci` fails on a non-canonical spelling of a glossary term: run it.
- `#425` and `#426` also edit orchestrate.md, and `#424` and `#426` also edit clerk.md: reconcile expected at step 7.
