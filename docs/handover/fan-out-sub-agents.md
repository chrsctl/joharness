---
workstream: fan-out-sub-agents
status: in-progress
branch: claude/fan-out-sub-agents-fzirvs
pr: none
plan: none
session: https://claude.ai/code/session_01VnfQ6Zg1DFomKia7dHUnAb
agent: opus
updated: 2026-08-25
next: Hand docs/plans/review-verifier-subagent.md to a fresh session, or claim it here
---

## Goal

Requester asked: research possibility to fan out to sub agents. Research
only — no harness change made. Findings below, so the next session does not
re-measure.

## Decisions

- Two different mechanisms wear the name fan-out, and they are not
  interchangeable. SUBAGENT = `Agent` tool, runs inside this session, this
  container. SESSION = control-plane `create_session`, own container, own
  hooks. `docs/plans/unsupervised-fanout.md` means the second one
  throughout.
- A subagent CAN run a build. It has Bash and the full tool set; the repo
  already recorded that (`docs/handover/upkeep-off-session.md`, r9).
  `isolation: worktree` gives it a worktree branched from the DEFAULT
  branch, not the parent's HEAD — which is step 3's "cut branch from
  `main`" for free. Measured here 2026-08-25: `git worktree add` works and
  `git ls-remote origin` authenticates from inside the worktree, so the
  push path exists. `.git` is 2.0M, so a worktree per subagent is cheap.
- Subagent gets harness RULES, not harness STATE. The CLAUDE.md hierarchy
  loads, so `AGENTS.md` and `.agents/harness/AGENTS.md` — the whole Loop —
  reach it. The hook output does not: `SessionStart` does not fire for
  subagents, and `SubagentStart` cannot inject `additionalContext` at all
  (Claude Code hooks reference, read 2026-08-25). No hook can hand a
  subagent the queue, the handover state, the overlap warning, or the mode.
  Only the delegation prompt can. Same gap `pm-dispatch` recorded
  2026-08-21 from the session side: the spawner must NAME the plan.
- The `Stop` hook does not fire for a subagent either — `SubagentStop` is a
  separate event and this repo configures none. So
  `.agents/harness/handover-guard.sh` never restates the finishing ritual
  to a subagent. The one guard that catches an unpushed claim is absent
  exactly where context is thinnest.
- `/who` is blind to subagents. It reads control-plane `list_sessions`
  (`.claude/commands/who.md`); a subagent is not a session. Claim-by-push
  still works, because git is the substrate — but a fleet of ten subagents
  shows in `/who` as one session, so a second SESSION cannot see what they
  hold.
- Fleet lifetime = the parent's. Subagents die with the session that spawned
  them; spawned sessions do not. The requirement's "keeps going for hours"
  (`docs/product/unsupervised-mode.md`) is therefore not answerable by
  subagents, and `unsupervised-heartbeat`'s durable Routine stays needed
  either way.
- Neither spawn API carries `effort`. `Agent` and `create_session` both take
  a model (= tier) and nothing else from `.agents/docs/agent-selection.md`.
  A plan's `effort: xhigh` crosses as prose in the prompt or not at all.
  Tier transfers; effort does not.
- Width here is CPU-bound, not quota-bound. `nproc` = 4 on this container.
  Subagent cap is 20 (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`), spawn depth 3,
  but four cores back all of them; the `Workflow` tool's own cap computes to
  min(16, cores - 2) = 2 here. Spawned sessions each get their own
  container, so session fan-out's width belongs to the control plane, not to
  this box.
- Return channel is asymmetric, and it decides the fit. A subagent returns
  its final text to the parent — result in hand, paid for in parent context.
  A spawned session returns nothing: `SendMessage` reaches it one-way and it
  cannot answer, so the parent reads git and GitHub instead. The harness
  already reads git and GitHub for everything (`.agents/docs/graph.md`), so
  session fan-out needs no new channel and subagent fan-out is the one that
  costs context.
- Recommendation, three jobs where a subagent is the right tool:
  1. REVIEW LENSES. `.agents/docs/agent-selection.md` already demands
     independent passes for an opus plan, and `.agents/docs/graph.md` states
     the diamond rule — verify outside the context that wrote the code. A
     review run inline in the writing session satisfies neither. One
     subagent per lens is the only mechanism that buys real context
     independence without a second session. Highest value, smallest change.
  2. HARNESS UPKEEP. Already ratified as route 2
     (`.agents/docs/consumer-repos.md`); nothing to decide, just unused.
  3. RESEARCH SWEEPS. Read many files, return the conclusion only. What
     `Explore` exists for.
- Not recommended: a subagent claiming and running a plan end to end. It
  gets no hook state, no handover guard, no `/who` entry, dies with the
  parent, and step 7 merge authority is a session's ("own = opened by this
  session") — a subagent's pull request is the parent's, so the parent must
  stay alive to merge it. That is the width limit again, wearing a
  different hat.

## Measured — which job is best (2026-08-25)

Scored against this repo's own rule, not taste: recurrence is the score,
volume is not (`.agents/docs/feedback.md`, Scoring). Every number below from
`./joharness.sh feedback`, re-derivable.

- Detection is NOT the gap. Coverage since the review ledger (PR31) is 18/19
  edges recording a review. The scorecard's headline 18/38 is diluted by 19
  pre-ledger edges that all recorded zero — reading it as decay is wrong.
- Independence IS the gap, and one escape proves it. `joharness.sh cleanup`
  shipped in PR54 — 14 findings, opus, the deepest review in this repo's
  history — carrying `git diff --name-only "$base" "$r" -- docs/handover`,
  which counts a DELETION as presence. So a branch that ran the finishing
  ritual read as still carrying its workstream file, and the file was
  protected from cleanup forever: the feature refused to remove exactly what
  it exists to remove. Fixed in PR59 by a different session, after the
  symptom recurred four times in one night. Self-review at maximum depth did
  not see it; a fresh context saw it immediately.
- Recurrence 27/46 (58%), up from 7/19 (36%) on 2026-08-24. Confounded, and
  the doc says so: measured on paths, and `.agents/harness/selftest.sh` (9
  edges) is touched by nearly every branch by design. Treat as a
  direction, not a rate.
- 9 of the 28 post-ledger edges carry no workstream file, so record no
  review, and `JOHARNESS_REVIEW` is blind there by construction — it prints
  that it checked nothing rather than passing quietly. PR54's escape was
  found on one such edge, not by a gate.
- Price of a reviewer pass: median edge is ~300 changed lines, largest 1267
  (last 12 edges). One diff-only pass is cheap against a session that ran
  for hours.

Verdict: ONE independent verifier subagent per edge — fresh context, the
diff and the rules, not the author's reasoning. Not three lenses: lens
labels already appear on in-context findings (`security/correctness`,
`does-it-reproduce` in PR51, PR56), so lenses are not what is missing, and
tripling cost buys volume, which this repo already established is no signal.

Runner-up, and worth doing regardless: nothing about fan-out fixes the 9
unreviewed edges. `JOHARNESS_REVIEW=on` is one line in `joharness.conf` and
covers the edges that DO carry a workstream file.

Written up as `docs/plans/review-verifier-subagent.md` (opus, high). Its
acceptance replays PR54's diff at the verifier and passes only if the escape
comes back named — the bug that motivated the plan is the plan's own
regression test.

## Rejected

- Subagents as the mechanism for `unsupervised-fanout`. Loses endurance (dies
  with parent), loses `/who` visibility, loses queue injection. The plan's
  choice of sessions is correct and this research does not disturb it.
- A `SubagentStart` hook that injects the queue the way `SessionStart` does.
  Impossible, not merely awkward: that event cannot return
  `additionalContext` and its stderr goes to the subagent's transcript only.
- Three lens subagents per edge, which is what round one recommended.
  Withdrawn on the measurement above: coverage is 95% and lens labels
  already appear in recorded findings, so the missing property is a context
  that did not write the code, and one such reader has it. Volume is not a
  score.
- The upkeep-subagent job, in THIS repo. `JOHARNESS_CANONICAL=1`, so the
  context rule does not apply and `upgrade` refuses to run
  (`.agents/docs/consumer-repos.md`). It pays in consumers only.
- A `.claude/agents/joharness-worker.md` definition carrying the state. Agent
  frontmatter carries rules, skills, memory, permission mode and its own
  PreToolUse/PostToolUse hooks — all static. The queue changes every run;
  static frontmatter cannot hold it.

## Review

- r2: round one recommended three lens subagents from doctrine
  (`agent-selection.md`, `graph.md`) without checking the repo's own
  scorecard, which had already weighed and rejected exactly that on
  2026-08-24 ("coverage is already 8/8. Buys nothing the numbers show
  missing"). Re-derived the numbers, found the recommendation half wrong:
  independence survives the evidence, three-lens volume does not.
  (fixed — narrowed to one verifier)
- r1: research turn, no code changed. Read-back check on the two claims that
  would be expensive if wrong — hook events and subagent context — done
  against the Claude Code docs rather than memory, both cited above with the
  date read. Worktree and remote-auth claims measured in this container, not
  assumed. Clean.

## Blockers

None. Next step is a human choice, not work.

## Where to look

- `.agents/docs/feedback.md`, Scoring — recurrence is the score, volume is
  not. The rule that decided this.
- `./joharness.sh feedback` and `feedback <path>` — where every number above
  comes from.
- PR54 vs PR59 on `cl_inflight` — the escape, and the argument for a reader
  that did not write the code.
- `docs/plans/unsupervised-fanout.md` — session fan-out, blocked on
  `unsupervised-heartbeat`. Untouched by this research.
- `.agents/docs/agent-selection.md`, review depth — the opus recipe that
  wants independent lenses.
- `.agents/docs/graph.md`, Rules — the diamond rule, the reason lens
  subagents are worth more than width.
- `.agents/docs/consumer-repos.md`, Pick route — subagent as route 2, the
  one endorsed use today.
- `.claude/settings.json` — SessionStart and Stop are the only hooks
  configured, and neither fires for a subagent.
