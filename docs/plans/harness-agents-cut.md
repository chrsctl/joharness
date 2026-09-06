---
plan: harness-agents-cut
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
scope: .agents/harness/AGENTS.md, .agents/docs
---

## Goal

`.agents/harness/AGENTS.md` is loaded by every session, in every mode, at
every tier, before its first prompt. It opens by citing ETH AGENTbench (138
repos) for "long context file hurt agent, cost more", and it grew 770 words
on 2026-08-23 to 2129 on 2026-09-06 — 2.8x in 14 days. Counted with the
command in `.agents/docs/caveman.md`, "What it costs, counted"; recount it
before starting, because the number moves. Cut it back toward the size its
own first line argues for, without losing a rule.

## Scope

- `.agents/harness/AGENTS.md` — cut. Every sentence answers one question:
  does a session need this BEFORE its first prompt, or on demand when it
  reaches the work? On demand moves to the owning file under
  `.agents/docs/`, with a pointer only if the rule is unobvious enough that
  a session would not go looking.
- `.agents/docs/**` — receives what moves. A why-explanation there costs
  nothing until someone opens it.

## Out of scope

- Deleting a rule. This is a MOVE, not a repeal. A rule that no longer
  earns its place is a separate decision with a separate pull request, and
  it is the human's, not a session's.
- `AGENTS.md` Part 2 and `CLAUDE.md`. Part 2 is the repo's own half and a
  consumer edits it freely; 399 + 2454 bytes against 15005 is not where the
  cost is.
- The counter itself (`joharness.sh:ctx_report`). It is the instrument;
  changing it in the same diff that moves the number makes the before and
  after incomparable.
- Caveman-compressing prose to hit a number. `.agents/docs/caveman.md`,
  "Honest numbers": when compressed text loses a symptom, a number or a
  negation, verbose wins. The lever here is LOCATION, not compression.

## Acceptance

- `./joharness.sh context` — `instructions` subtotal lower than the number
  recorded in the workstream file at claim time, with both numbers written
  down in the same commit as the cut.
- `./joharness.sh ci` — pass. The glossary and graph lints read the moved
  text at its new path, so a move that breaks a cross-reference reds here.
- `.agents/harness/selftest.sh` — 0 failed.
- Every rule removed from the file is findable: for each, name the file it
  moved to in the workstream file's `## Decisions`, one line each.
- Plan `ci` calls SHIPS: `.agents/harness/` syncs to every consumer, so the
  bar is a consumer command — `./joharness.sh ci` green in a consumer
  fixture (`.agents/harness/selftest/bootstrap-consumer.sh`).

## Where to look

- `.agents/harness/AGENTS.md` — the file. Its first line is the argument
  for this plan.
- `.agents/docs/caveman.md`, "Where it applies" and "What it costs,
  counted" — the rule this serves, and how to recount.
- `joharness.sh:ctx_report` — the instrument. Run it before and after.
- `.agents/docs/feedback.md` — a rule that keeps drawing findings belongs
  in the always-loaded file; one that never does is a candidate to move.

## Traps

- opus at xhigh because wrong-but-plausible is the exact failure mode: a
  rule that reads as preserved but is now findable only by a session that
  already knew to look is a repeal wearing a move's clothes. Every moved
  rule gets its landing site named.
- The file is protocol text (`./joharness.sh protocol-paths`). SUPERVISED
  ONLY by construction; an unattended session must not claim this.
- Part 2: the harness layer names no specific environment. Nothing moved
  may acquire one.
