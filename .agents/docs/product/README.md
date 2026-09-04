# Product hierarchy

Requirements above plans, plans above branches. Human adds requirements
ANY time, mid-flight fine; sessions decompose them into plans; plans run
the Loop. Every level = graph nodes ([`.agents/docs/graph.md`](../graph.md)),
files as nodes, delete-on-done as state.

```
docs/product/<requirement>.md   what product needs. Human writes. Coarse.
docs/plans/<plan>.md            how, machine-executable. Sessions write.
claude/<plan> branch + PR       execution. One per plan.
```

## Requirements

One file per requirement, shape: [`TEMPLATE.md`](TEMPLATE.md). Frontmatter
`requirement`, `priority` (`normal` | `urgent`). Body: goal + satisfied-when,
requester's words. Coarse is fine — decomposition is session work, not
human work.

- **Add** = write file on `main` (direct or PR — human's call). Hook picks
  it up next session start.
- **Unplanned** (no open plan's `requirement:` names it) = hook flags it.
  Planning = queue work: session decomposes into plans via PR, plans carry
  the `requirement:` edge. Plan queue rules: [`../plans/README.md`](../plans/README.md).
- **Satisfied** = last plan's PR deletes the requirement file with the
  plan file. Survives in history.
- Requirement with open plans = silent in hook; its plans speak.

## Branch flow

- `main` = the only long-lived line. One branch per plan, cut from `main`.
  No long-lived integration branch: PR + `ci` + review-at-edge do that
  job; a second line rots against a fleet of short sessions. The shape is
  not worthless and the rejection is not a reflex — grouping an epic's
  children on a shared branch and landing it as one commit buys three real
  things: children build on each other, rollback is one commit, CI runs
  once on the combined work. All three are priced in what this repo
  optimizes hardest against. Work stays invisible on `main` for the epic's
  whole life, and an abandoned integration branch is the abandoned-edge
  problem multiplied by its child count. Re-open on a measurement that
  serializing costs more than that, never on the appeal of the shape.
- **Start** = Claim (Loop step 3): cut `claude/<plan>`, workstream file,
  push.
- **Finish** = PR green + reviewed, merge to `main`, PR deletes plan file
  (+ requirement file when last plan). The merging click is the session's
  own for its own PR (ratified 2026-08-23; conditions in
  `.agents/harness/AGENTS.md` step 7), merge-commit method only (why: the filter
  note below). Human veto = revert. Rule syncs to consumers with the
  harness like every Loop rule; a consumer wanting human-click merges
  overrides in its own `AGENTS.md` Part 2. Merged branch may stand: the
  session-start hook filters branches merged into `main` out of the
  claims view, so deadwood is `git branch -r` noise, not fake in-flight
  work. Filter reads ancestry, so it rests on PRs merging by merge
  commit — GitHub's "Squash and merge" / "Rebase and merge" buttons hide
  ancestry, and branches merged that way would read as in-flight again.
  Prose, not a gate: nothing in this repo can enforce the method, and one
  session squashing once breaks the filter for every session after it. An
  instruction is the weakest place to put a rule a tool could hold. The
  remedy is a forge setting rather than code — restrict the allowed merge
  methods on the repository — and until someone sets it, this bullet is
  all there is.
  Deleting = optional hygiene, human-only, anytime: Delete-branch button
  on merged PR page, or repo setting "Automatically delete head
  branches". Sessions never `git push --delete` — deletion is the
  human's call. Abandoned UNMERGED branches are the deadwood the filter
  cannot hide: they read as in-flight until a human triages — salvage
  plans from their workstream files, then delete (three recovered
  exactly that way, 2026-08-21).
- `urgent` = same mechanics, jumps queue.
- Merge commits on shared branches, never rebase — history rewrite breaks
  other sessions' checkouts.
- **Conflict at finish** = local view of `main` is from session start; another
  session's PR may have merged since. Before opening or merging the PR,
  `git fetch origin main` and check ahead/behind — do not trust a stale
  clone. Behind = merge `main` into branch (not rebase), resolve, re-run
  `ci`, push. Conflict does not resolve clean (semantic, unclear intent) =
  do not force-merge through it — decide-alone exception (`.agents/harness/AGENTS.md`),
  stop, record in workstream file's `Blockers`, ask human. A merge queue
  would remove this reconcile entirely. Not built: the failure this repo
  measured is starvation, not merge contention — the count and the command
  that produced it are in `.agents/harness/AGENTS.md`, `/drain` paragraph.
  Adopt one only when a measurement shows sessions losing time to
  reconciles, and prefer the forge's own to building one.
- **Long-running session** = re-check `git fetch origin main` ahead/behind
  periodically during Build too, not only at Finish — a conflict caught
  mid-build is cheap, one hit at finish after hours of work is not.

## Orchestration: peers, no lead, and what that costs

The architecture class is **decentralized peer**, and it is a considered
position rather than an accident. There is no orchestrator anywhere: each
session cuts a branch from `main`, claims by pushing a workstream file, and
merges its own pull request. Parallel safety comes from `scope:` prefixes the
queue hook proves disjoint.

**The costs this avoids are real in kind and unquantified in degree.** An
orchestrator is a single point of failure, a context-window bottleneck holding
every worker's result, and a throughput ceiling. Those are qualitative claims
worth believing; the figures that circulate for them are blog arithmetic and do
not survive checking, so no number for them appears here.

**The cost it does pay is measurable, and it is the reconcile.** About one merge
in four arrives only after its branch pulled `main` in first:

```bash
git log --oneline origin/main --grep='^Merge origin/main\|^Merge remote-tracking branch' | wc -l
git log --oneline --merges origin/main | wc -l
```

51 of 201 merges all-time (25.4%), and 14 of 60 (23.3%) over the most recent
window, on `origin/main` 2026-08-30 in a full clone. Stable across both, which
is what makes it usable as a baseline: fan-out raises session count, and
contention at the merge stage is the cost that scales with it. A plan that
widens the fleet should carry this number and say what it expects to happen to
it, rather than treating width as free.

**Do not measure this with `--grep=reconcile`.** That counts commits whose
message *discusses* reconciling, which a session working on the reconcile rules
produces many of. Match the reconcile merge's own subject, as above.

**Worktrees would not help, and this is the best-sourced finding.** They provide
file isolation without removing conflicts when agents touch the same
functionality; the conflict moves to the pull request merge stage "where they
surface as visible git conflicts instead of silent runtime overwrites". That is
exactly where this repo's reconciles already land, so adopting them would move
nothing.

**Claude Code ships the mechanism this repo hand-builds.** Agent teams
(experimental) give tasks pending/in-progress/completed states with self-claim,
and "task claiming uses file locking to prevent race conditions". The queue plus
claim-by-push is the same mechanism built on git instead. Adopt-or-build is a
live question and is NOT answered here: the built-in is experimental and stores
state outside the repo, against a doctrine that git holds the state.

**A lead with subagents does beat one agent at breadth-first work** — 3-5
subagents in parallel, a separate citation pass, and a multi-agent setup
outperforming the single-agent baseline "by 90.2% on our internal research
eval". Anthropic-internal, model-specific: attributable, not independently
reproduced. It argues for fan-out *within* a unit of work, not for a lead over
the fleet.

**The gap none of this closes: claim-by-push only covers work that enters
through the queue.** A request typed at a running session enters nowhere, and
two sessions once answered the same one two minutes apart, producing competing
designs for one problem. Neither more isolation nor a lead fixes that — the
queue is the shared document, and a mid-session request never reaches it. The
mitigation available today is the Loop's own rule that nothing builds unplanned:
a request decomposed into a plan file enters the queue and becomes claimable.

## Reconciliation

Consumer repos carry harness copies. One rule keeps them reconcilable: a
fix born ANYWHERE lands in joharness `main` first, then syncs out to
every consumer from there. Never consumer-to-consumer, never
consumer-only — one canonical line reconciles all copies. The sync tool
enforces it: a consumer copy whose content canonical history does not know
is never overwritten.

New consumer starts via `.agents/scripts/bootstrap-consumer.sh`, never by using a
raw joharness clone as-is: a raw clone carries joharness's live plan
queue, workstream files and canonical marker, so its sessions work
joharness's workstream instead of the child's.

Routes, tokens, exit codes, `AHEAD` handling:
[`../consumer-repos.md`](../consumer-repos.md).
