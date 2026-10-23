---
plan: simplify-queue-docs
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/plans/README.md, .agents/docs/product/README.md, .agents/docs/research/README.md, .agents/docs/graph.md, .agents/docs/handover/README.md
---

## Goal

The user asked to simplify the protocol. The queue docs (plans, product,
research, graph, handover) contradict the code on what session start
prints and what dispatch reads. They omit the `fable` tier, restate AGENTS.md
step 7 and the fast lane, and carry stories the Status quo rule bans. Make
them match the code and say each rule once.

## Scope

- Contradictions to fix against the code:
  - **Session start no longer prints the queue** (`HANDOVER_SCOPE=branch`;
    `joharness.sh` session-start prints "no queue"). Fix the claims that it
    does in `plans/README.md` (the "Session-start hook prints the queue"
    paragraph), `product/README.md` ("Hook picks it up next session start")
    and `graph.md` (§ Serving). In `handover/README.md`, the "every remote
    branch" claim goes; that file already says "branch only" elsewhere.
  - **Issues are not in the queue**: `plans/README.md`'s opening "Queue
    order … open GitHub issues first" goes. dispatch reads `docs/plans/`
    and issues enter through the clerk (`.agents/docs/orchestrated.md`).
  - **Agent tiers**: the frontmatter list in `plans/README.md` adds `fable`.
  - `handover/README.md`:
    - "no subagents, no orchestration" gets a qualifier or goes;
    - "contains only those six" becomes the real section list (the
      template has `## Where to look`);
    - the review-gate condition must include the `(verifier)` tag, or point
      to `.agents/docs/agent-selection.md`.
  - `graph.md`: "cannot watch, nudge, queue or schedule" needs the qualifier
    that the orchestrator and heartbeat do.
  - `research/README.md`: "`dispatch` lists them" goes to the queue hook
    (`.agents/harness/queue-context.sh`).
  - `handover/README.md`: "`manage.md`, rescope" goes to "R. Surveyor".
- History to delete:
  - `plans/README.md`: the pull request #457 and `chrsctl/gx` story (keep
    the `human/<stem>` rule); "A ledger file … was rejected"; "issue #297";
    "nobody has measured".
  - `research/README.md`: "An earlier draft"; "measured once: 13 documents";
    "An earlier rule … PR 140 shape"; "Issue #267 is the instance"; the
    "unrecorded method" story.
  - `product/README.md`: "Rejected, so the question stays closed"; "Intake
    rejections"; "51 of 201 merges, 2026-08-30".
  - `handover/README.md`: "GitHub's own agent-memory work converged…".
- Duplicates to cut to pointers:
  - `handover/README.md`: retire and recovery-command text that repeats
    AGENTS.md step 7; Compaction (repeats step 1); Graduation (repeats
    step 7); the fast-lane paragraph (home: `plans/README.md` § Fast lane);
    the `JOHARNESS_REVIEW` gate (home: `agent-selection.md`).
  - `product/README.md`: the merge-commit, no-rebase and conflict-at-finish
    text, except the "Conflict at finish" section AGENTS.md step 7 cites by
    name. Keep that heading.
  - `product/README.md`: the direction rule becomes a one-line pointer to
    `consumer-repos.md`.

## Assumptions

- A1: Session start prints no queue — evidence: `grep -n 'no queue' joharness.sh` — confidence: high.
- A2: dispatch reads no GitHub — evidence: `grep -n 'reads no GitHub' joharness.sh` — confidence: high.
- A3: `selftest/reading-budget.sh` sets a byte ceiling, upper only, on `handover/README.md`. It also fails on `(why: history/` — evidence: `cat .agents/harness/selftest/reading-budget.sh` — confidence: high.
- A4: `selftest/review.sh` needs `outside this checkout` in research/README.md — evidence: `grep -n 'outside this checkout' .agents/harness/selftest/review.sh` — confidence: high.

## Out of scope

- `.agents/harness/AGENTS.md`: plan simplify-role-commands owns it. Point
  to it; never edit it here.
- Changing what session start prints. The docs follow the code.
- `consumer-repos.md`, `feedback.md`, `caveman.md`, `glossary.md`: plan
  simplify-consumer-docs owns them.

## Acceptance

- `git grep -nE '#457|#297|#267|PR 140|chrsctl/gx|2026-08-30' .agents/docs/plans/README.md .agents/docs/product/README.md .agents/docs/research/README.md .agents/docs/handover/README.md`: no output.
- `grep -n 'fable' .agents/docs/plans/README.md`: at least one hit, in the frontmatter tier list.
- `cat .agents/docs/{plans,product,research,handover}/README.md .agents/docs/graph.md | wc -l`: at most 1050 (1257 today).
- `./joharness.sh ci`: `ci: pass`.
- Consumer-side check: the same `./joharness.sh ci` runs in every consumer after sync and lints these files (glossary, anchors).
- `./joharness.sh verify`: `0 failed`.

## Where to look

- `joharness.sh:cmd_dispatch`: what dispatch reads.
- `.agents/harness/queue-context.sh:stem`: the queue hook.
- `.agents/docs/handover/TEMPLATE.md`: the real section list.
- `.agents/harness/selftest/reading-budget.sh`: the byte ceilings.

## Traps

- AGENTS.md step 7 cites `.agents/docs/product/README.md`, "Conflict at
  finish", by name. Keep that heading.
- `ci` lint_glossary bans `handover file`, `model tier`, `env layer`,
  `rescope manager` and `bare role title`. The handover docs are where this
  bites.
- Sibling plan simplify-consumer-docs is the home of the direction rule.
  Point to `consumer-repos.md` without editing it.
