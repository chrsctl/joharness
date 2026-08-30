---
plan: dispatch-name-the-plan
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: .agents/docs/plans
---

## Goal

A claim exists only after the spawned session's first push, so two sessions
spawned at once against the same queue can both self-select the same plan.
The rule that avoids it — the controller NAMES the plan in each spawn
prompt, because queue self-selection is for a single session — is written
down **nowhere**. Checked 2026-08-30: `grep -rn "NAME the plan\|spawn
prompt\|self-selection" .agents/docs/` returns nothing.

Salvaged from `origin/claude/multi-agent-orchestration-pr-jyli0w`
(`docs/handover/pm-dispatch.md`, "Dispatch gap in #8"), recorded 2026-08-21
and never merged — its pull request 10 was closed unmerged on the same day.

Still true, and independently re-derived since: the fan-out live run on
2026-08-30 bound each of its two spawned sessions to one named plan for
exactly this reason, and that reasoning survives only in a merged pull
request body.

## Scope

- One rule in `.agents/docs/plans/README.md`, beside the existing claim
  rules: spawning sessions in parallel names each one's plan in its prompt;
  self-selection from the queue is for a single session, because a claim is
  only visible after a push.
- Caveman house style. It is read at the moment somebody is about to spawn.

## Out of scope

- A mechanism. A pre-push claim would need shared state the harness
  deliberately does not have — every measure here counts from git at read
  time and stores nothing.
- Changing how `/who` or the queue hook report claims. They are already
  correct about what they can see; the gap is that nobody is told what they
  cannot.

## Acceptance

```
./joharness.sh ci     # ci: pass
grep -rn "self-selection" .agents/docs/plans/README.md    # the rule is there
```

## Where to look

- `.agents/docs/plans/README.md` — the claim rules the new line joins.
- `.agents/harness/AGENTS.md` step 3 — "Push NOW — no push, no claim", the
  fact this rule is the consequence of.

## Traps

- The rule is about SPAWNING, not about the spawned session's own conduct.
  A session told to pick from the queue is behaving correctly; the caller
  is the one who must not tell two of them that.
