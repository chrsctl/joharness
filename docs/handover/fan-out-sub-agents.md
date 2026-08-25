---
workstream: fan-out-sub-agents
status: in-progress
branch: claude/fan-out-sub-agents-fzirvs
pr: none
plan: none
session: https://claude.ai/code/session_01VnfQ6Zg1DFomKia7dHUnAb
agent: opus
updated: 2026-08-25
next: Human picks which of the three subagent jobs becomes a plan; review lenses is the recommendation
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

## Rejected

- Subagents as the mechanism for `unsupervised-fanout`. Loses endurance (dies
  with parent), loses `/who` visibility, loses queue injection. The plan's
  choice of sessions is correct and this research does not disturb it.
- A `SubagentStart` hook that injects the queue the way `SessionStart` does.
  Impossible, not merely awkward: that event cannot return
  `additionalContext` and its stderr goes to the subagent's transcript only.
- A `.claude/agents/joharness-worker.md` definition carrying the state. Agent
  frontmatter carries rules, skills, memory, permission mode and its own
  PreToolUse/PostToolUse hooks — all static. The queue changes every run;
  static frontmatter cannot hold it.

## Review

- r1: research turn, no code changed. Read-back check on the two claims that
  would be expensive if wrong — hook events and subagent context — done
  against the Claude Code docs rather than memory, both cited above with the
  date read. Worktree and remote-auth claims measured in this container, not
  assumed. Clean.

## Blockers

None. Next step is a human choice, not work.

## Where to look

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
