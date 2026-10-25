---
plan: c1-at-the-gates
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: .claude/agents/verifier.md, .claude/agents/plan-checker.md
---

## Goal

A plan whose acceptance criterion expects the behaviour its Goal says must
be refused reaches `main` today unless a sampled conduct run happens to
read it weeks later. Catch it before merge instead. The plan-checker
(opus and fable plans) and the verifier (every branch) both ask conduct's
question C1, as prevention. Conduct keeps C1 as the audit of whether they
do (plan conduct-audits-the-gates).

## Scope

- `.claude/agents/plan-checker.md`, `## What you check`: one new numbered
  item. No `## Acceptance` item expects the behaviour the `## Goal` says
  must be refused (passes, succeeds, prints OK, is allowed).
- `.claude/agents/verifier.md`, `## Did the branch do what it was for`: one
  line. An Acceptance item that asserts what the Goal says must be refused
  is a finding, whatever its COVERED status.
- Wording follows conduct's C1 (`.claude/commands/conduct.md`, "C1
  criterion") so the three readers ask one question. Keep the phrase
  "must be refused" whole: Acceptance greps for it.

## Assumptions

- A1: verifier.md is under its reading budget with room for one line —
  evidence: `wc -c .claude/agents/verifier.md` (5577) against
  `.agents/harness/selftest/reading-budget.sh:rb_bound` (6211 + 10%) —
  confidence: high.
- A2: No selftest needle pins the plan-checker's numbered list text —
  evidence: `grep -rn 'plan-checker' .agents/harness/selftest` — confidence:
  medium.

## Out of scope

- `.claude/commands/conduct.md`, and anything in plan conduct-recent-sample
  or research conduct-c2-design, or plan retro-audit-and-trace.
- Making the plan-checker run on sonnet or haiku plans.

## Acceptance

```bash
for f in .claude/agents/plan-checker.md .claude/agents/verifier.md; do tr -s ' \n' '  ' < "$f" | grep -c 'must be refused'; done   # each prints 1 (line wraps folded); 0 = not done
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- Consumer side (SHIPS): after its next sync a consumer runs
  `./joharness.sh ci` → `ci: pass`.

## Where to look

- `.claude/agents/plan-checker.md:What you check`: the numbered list.
- `.claude/agents/verifier.md:Did the branch do what it was for`: the
  Goal/Acceptance lens.
- `.claude/commands/conduct.md:C1 criterion`: C1's wording.

## Traps

- verifier.md needles in `.agents/harness/selftest/review.sh` are matched
  per line: leave the lines they pin intact.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope
  manager`, `bare role title`.
