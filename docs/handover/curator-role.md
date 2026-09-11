---
workstream: curator-role
status: in-progress
branch: claude/work-visibility-orchestrator-zvzo62
pr: none
plan: curator-role
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-11
next: Verifier running on the curator commit; fix what it returns, then this is ready for the human's review as a PR (SUPERVISED ONLY)
---

## Goal

A periodic role that checks the plan queue: repairs stale declarations,
declutters obsolete plans, and proposes ordering and decomposition. Plan:
`docs/plans/curator-role.md`. Second item on this branch — the first,
`rescope-held-plans`, is pushed and awaiting the human's merge (protocol
text), and both touch the same `cmd_dispatch` region, so a separate branch
would conflict for nothing.

## Decisions

- Name **curator** (`/curate`, `./joharness.sh curate`): verb-command plus
  `-or` role noun, matching the existing vocabulary. Rejected "worker" — a
  worker here is a claimless subagent that dies with its parent's turn, and
  this role needs a branch and a pull request. It is a second KIND of session
  at manager level, like the reporter, holding no slot.
- Requester's two calls, 2026-09-11: REPAIR and DECLUTTER act; ORDER and
  DECOMPOSE only propose. Orchestrator-driven cycle, no Routine.
- `urgency:` is never the curator's — ordering by priority is product
  direction, the stop-and-ask list. It orders by derived facts only and
  proposes the rest.
- Cadence state is derived from GIT, never stored: the last curate is the
  newest base-branch commit deleting a `docs/handover/curate-*.md`. The
  orchestrator's ledger dies with its run; git does not.
- `JOHARNESS_CURATE_HOURS` default 168 (weekly), matching `update.yml`'s sync
  cadence — the only hygiene cadence this repo already has. The number is the
  human's; 0 disables.

## Rejected

- A Routine driver. Would close the idle-queue gap; the requester chose
  orchestrator-driven only, so the gap is recorded in the plan's Goal, not
  closed.
- Letting the curator split plans. Decomposition is the opus-tier judgement
  every build rests on and it MULTIPLIES the queue — one plan into five and a
  session has grown its own backlog, which is the circularity the
  requirement ban exists to stop. It proposes instead.

## Review

Depth: opus tier, adversarial + one independent reader (verifier) on the
curator commit. Harness selftest **1822 passed, 0 failed**
(`.agents/harness/selftest.sh`, 2026-09-11).

**Can-fail, by injecting the defect into COPIES rather than reasoning** (the
tree is never edited while a job runs — ADR 0131 r18 / ADR 0145 r13). Each
injection reds its own assertion and leaves its neighbour intact, so each check
distinguishes its property from its absence. Fixture and runs 2026-09-11,
`bash <variant> curate` / `dispatch` over one scratch queue:

| assertion | clean | its injection | neighbour's injection |
| --- | --- | --- | --- |
| anchor not in tree | 1 | 0 | — |
| whole-directory claim | 1 | 0 | — |
| Scope path `scope:` misses | 1 | 0 | 1 (registry injection) |
| registry declared by 3, unmarked | 3 | 0 | 3 (coverage injection) |
| `curate DUE` tail | 1 | 0 | 0 at `JOHARNESS_CURATE_HOURS=0` |
| `NOTHING TO CURATE` | 1 on a clean queue | 0 on a dirty one | — |

**The refactor's blast radius, measured rather than argued.** `lint_anchors`
gates `ci` over every node in every consumer, so its extractor changing shape
is the worst defect available here. Old and new extraction compared over every
node file in this repo: **21 files, 24 anchor paths, 0 disagreements**
(2026-09-11). On synthetic edge cases the extracted LIST does differ — `./x`
becomes `x`, `x/` becomes `x`, and a bare `.` or `..` is dropped — and every
one of those is WARNING-neutral, because `[ -e ROOT/./x ]` and `[ -e ROOT/x ]`
agree, `[ -e x/ ]` and `[ -e x ]` agree for a directory, and `.`/`..` always
exist so dropping them warns no differently. ONE real change, in the forgiving
direction: an anchor written `joharness.sh/` (a file with a stray slash)
warned before and does not now — and stripping a trailing slash can never make
a missing path exist, so it cannot hide a genuine miss.

- r1: (session, fixture) the first `curate` run on this repo's real queue
  reported a plan's own PROSE as an undeclared path: `. Before the verdict, a `
  named as a path of `rescope-held-plans`, and `./joharness.sh curate` as one
  of `curator-role`. The extractor read every backticked token on a bullet.
  (fixed before commit: `section_paths` reads only the FIRST backticked token
  of a bullet that STARTS with one — the rule `lint_anchors` already used,
  which is what separates a deliverable from a citation — and that is why the
  two now share one reader instead of having two that can disagree.)
- r2: (session, fixture) the dispatch-cadence case wrote its workstream file
  straight after `git checkout main`, where git had just removed
  `docs/handover` — the redirect failed and `commit_all` staged nothing, so the
  retire never happened and two cases read "still due". Same gotcha the rescope
  fixture hit. (fixed: `mkdir -p` before the write, with the reason on the
  line.)

## Blockers

None.

## Where to look

- `joharness.sh:lint_nodes` — the whole-queue plan walk to reuse.
- `joharness.sh:dispatch_rescope_branches` — the stateless in-flight scan to copy.
