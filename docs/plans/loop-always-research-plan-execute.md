---
plan: loop-always-research-plan-execute
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: .agents/harness/AGENTS.md, .agents/docs/agent-selection.md, .agents/docs/plans/README.md
---

## Goal

Human ask, 2026-08-27: ensure loop always researches, plans, executes —
and always uses the optimal models. Loop today plans requirements but not
issues or direct asks, researches only inside the review-churn rule, and
matches a model only where a plan file already exists. Close three gaps as
doctrine: every unit of work decomposes into a plan before build; every
build starts with research; every plan's tier binds the session that
builds it.

## Scope

- `.agents/harness/AGENTS.md` — Loop step 2: nothing builds unplanned
  (issues and direct asks decompose like requirements); tier binds,
  below-tier session hands off. Step 4: research before code — anchors,
  claims-as-hypotheses, feedback. Agent selection section: every unit
  matched, no tier no build.
- `.agents/docs/agent-selection.md` — Selection rules gain the same two
  rules in full: universality, binding tier.
- `.agents/docs/plans/README.md` — same-session plan lifecycle: lives on
  work branch, dies in its PR; on `main` only when handed to the queue.

## Out of scope

- Research node type, template, queue listing, lint — `research-node`
  plan's scope, untouched.
- Any shell: hooks, `joharness.sh`, selftest. Doctrine only; a gate is its
  own plan if wanted.
- Unsupervised-mode source machinery.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- Loop step 2 states every entrypoint decomposes into a plan before build
  and the binding-tier rule. Step 4 states research before code.
- `.agents/docs/plans/README.md` says where a same-session plan lives and
  dies.

## Where to look

- `.agents/harness/AGENTS.md:Loop` — steps 2 and 4.
- `.agents/docs/agent-selection.md:Selection rules` — where tier rules live.
- `.agents/docs/plans/README.md:Lifecycle` — where plan lifecycle lives.

## Traps

- Caveman file loads every session — additions terse, reasoning goes to
  `.agents/docs/`.
- `research-node` plan scope names `.agents/harness/AGENTS.md` too — touch
  different lines, do not pre-implement its queue changes.
