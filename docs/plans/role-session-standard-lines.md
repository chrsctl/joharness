---
plan: role-session-standard-lines
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 427
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/clerk.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/glossary.md
---

## Goal

Three contradictions confused the clerk sessions of 2026-10-12.

1. **Clerk, curator and scout sessions get the manager's standard lines.** These include "Claim by pushing your workstream file before any code… One item, then exit". But clerk.md §1 says the clerk writes NO workstream file, so each clerk has to choose between two instructions.
2. **Two read rules exclude each other.**
   - clerk.md allows "the source each issue cites" and forbids "the design doc".
   - orchestrated.md's role-reads table says the clerk never opens "this doc".
   - #251 cites `.agents/docs/orchestrated.md`, so the clerk had to break one of the two rules.
3. **No rule says how to wait for `ci`.** A clerk chained `curate --apply; curate; ci` in one foreground call and hit the 120s timeout. It was then blocked on `sleep 100`, and finally ran a 55×`sleep 10` loop, the workaround the block forbids.

Remove the contradictions and say how to wait for `ci`.

## Scope

- **`.claude/commands/orchestrate.md` §3.** Define "the role lines" for clerk, curator and scout spawns:
  - "Run ./joharness.sh protocol-paths and never commit under those paths."
  - "Push at every milestone. One pass, then exit."
  - The lead line, when a transport exists, unchanged.

  There is no workstream-file claim line. The surveyor (`/manage rescope`) keeps "the standard lines", because it runs the manager command. The role-session bullet and table say which set each row gets. "The standard lines" stays the manager's term.
- **`.agents/docs/glossary.md`.** Add "the role lines" as one spelling, if `ci`'s glossary lint needs it. Run `ci` to find out.
- **`.claude/commands/clerk.md`, "What you read".** Add: "the design doc only where an issue cites it, only the cited section, and the files the plan you write names as anchors".
- **`.agents/docs/orchestrated.md`, the clerk row of "What each role reads".** Make the same carve-out, so the two files agree.
- **`.claude/commands/clerk.md` §4.** Add one line: run `./joharness.sh curate` and `./joharness.sh ci` as separate calls in the Bash tool's background mode, bounded by `timeout` (AGENTS.md step 5: a background command must be able to finish). Wait for the completion notification, and never loop on `sleep`.

## Out of scope

- The `/curate` and `/scout` command files beyond the role lines. Their files already say what they write.
- Making `ci` faster.
- Any `joharness.sh` change.

## Acceptance

- `grep -n "the role lines" .claude/commands/orchestrate.md`: at least the definition and the role-session bullet. There is no such hit today.
- `grep -n "only the cited section" .claude/commands/clerk.md .agents/docs/orchestrated.md`: one hit in each.
- `grep -n "never loop on" .claude/commands/clerk.md`: the new §4 line.
- `./joharness.sh ci`: `ci: pass`, glossary lint included. Consumers run the same lint at their next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `.claude/commands/orchestrate.md` §3: "Role sessions, at most ONE of each per run… prompt = the command + the standard lines", the role table, and the manager prompt block that defines "the standard lines".
- `.claude/commands/clerk.md`: "What you read", §1 and §4.
- `.agents/docs/orchestrated.md`: the role table (curator, surveyor, clerk, scout) and "What each role reads".
- `.agents/docs/glossary.md`: one spelling per contested term, which `ci` lints.

## Traps

- `ci` fails on a non-canonical spelling of a glossary term, so run it.
- `orchestrator-human-ordered-extras` (#425) reads this plan's term (`needs`). Do not rename it after merge.
- `orchestrator-human-ordered-extras`, `relayed-answer-is-quoted`, `drained-names-a-due-role` and `fresh-orchestrator-per-run` also edit orchestrate.md. `clerk-cycle-reads-what-a-clerk-leaves`, `orchestrator-human-ordered-extras` and `relayed-answer-is-quoted` also edit clerk.md. Reconcile expected at step 7.
