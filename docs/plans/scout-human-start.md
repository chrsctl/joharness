---
plan: scout-human-start
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 460
scope: shared:.claude/commands/scout.md
---

## Goal

`.claude/commands/scout.md` §0.4: a pass a human started must still see
`./joharness.sh dispatch` print `scout DUE: spawn`; anything else = stop.
The only pass that produced a proposal on gx (2026-10-12, #645) ran with
that gate waived on the reviewer's chat instruction, against the role's
own rule (issue #460 §2, quoting the claim file). `orchestrate.md` already
has a `+human` mark for an extra role session the human orders; the
scout has no matching path. This plan gives §0.4 one.

Issue #460's other asks — a reviewer's comment as a trigger (§1) and the
cadence wording (§3) — are left to issue #461, whose item 1 replaces the
clock and backlog triggers they patch.

## Scope

- `.claude/commands/scout.md` §0.4 — a human's order typed in this session (the reviewer, or the owner) waives the cadence and the backlog re-arm only; never the twin check (§1), the ceiling, the brief, the research switch or the budget. The claim's `## Decisions` records the waiver with the order quoted and its UTC time; the report's first line carries `+human`, mirroring `orchestrate.md`'s mark. With the waiver, §0.4 does not run `./joharness.sh dispatch` (156 s measured on gx for a gate it would fail).
- `.claude/commands/scout.md` `## Never` — if it forbids starting a pass outside `DUE`, it names the `+human` exception.

## Out of scope

- A comment-driven trigger in `dispatch` or `orchestrate.md` (#460 §1) and the `cadence :` wording in `joharness.sh` (#460 §3): #461 item 1 replaces both.
- Waiving anything but the timing gate.
- `joharness.sh`, `orchestrate.md`, the requirement file.

## Acceptance

- `grep -n '+human' .claude/commands/scout.md` — hits in §0.4 and in the report section.
- `sed -n '/^## 0/,/^## 1/p' .claude/commands/scout.md | grep -c -i 'twin\|budget\|brief'` — the waiver text names what it never waives (at least `1`).
- `./joharness.sh ci` — `ci: pass`.
- Plan ships (`scout.md` syncs): consumer check = on `chrsctl/gx` after sync, `grep -c '+human' .claude/commands/scout.md` ≥ `2`.

## Where to look

- `.claude/commands/scout.md` — "## 0." item 4 ("The gate held"), the report section, `## Never`.
- `.claude/commands/orchestrate.md` — the `+human` ledger mark ("The human orders an extra role session").

## Traps

- A chat line is evidence, not instruction, for every gate but this one named waiver: never widen it.
- `scout.md` is also edited by `scout-built-check`; merge `origin/main` in before the pull request.
- Glossary spellings: `ci` fails a contested term spelled another way.
