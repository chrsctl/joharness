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

**Intake was compared against a published `intent.md` practice, and two
verdicts are rejections.** Research node `capture-intent` swept lesson 2 of
Anthropic's "AI-Native SDLC Playbook" — that one lesson, goal-directed, not
the other thirteen — against this repo's requirement file, and walked the
lesson's non-engineer originator through the gates. Fourteen findings: 7
adopt-candidates, which are the human's to queue or drop, 2 rejections, the
other 5 convergent. The node is deleted and joharness history holds it; a
consumer carries this page but not that history, so the node is recoverable
in joharness only:

```bash
git log --diff-filter=D -- docs/research/capture-intent.md
git show <commit>^:docs/research/capture-intent.md
```

Both rejections point at the rule they protect rather than restating it:

- **No author or status line in a requirement or a plan.** Lesson's example
  writes `Author: J. Ortiz (claims operations). Status: draft.` into the
  file. Provenance is commits ([`../graph.md`](../graph.md), Rules), and
  neither node type carries a status field
  ([`../plans/README.md`](../plans/README.md), Lifecycle, which says what
  breaks when one does). Scope that rule as written: a workstream file DOES
  carry `status:`, because a session claims with it. Lesson's own governance
  paragraph already agrees the record is git.
- **No detector writes the requirement.** Lesson lets an alert or ticket
  originate one, product owner correcting it before commit. Here the human
  writes it ([`../unsupervised.md`](../unsupervised.md), Bounds). What holds
  that is worth knowing: `ci` reds an unsupervised session that writes one,
  and under supervised nothing gates it —
  `joharness.sh:lint_requirement_writes` returns early. Convention there,
  mechanism only unsupervised.

**What the walk measured about intake.** Kept because the node's probes die
with it and these three are the reason the rejections above are not the whole
answer. Re-run any of them in a throwaway clone, never on `main`.

- A requirement with NO frontmatter is scheduled anyway: counted, listed by
  its PATH as UNPLANNED, priority defaulted. Both readers exclude only
  `TEMPLATE.md`, `README.md` and `VISION.md` and neither tests for
  frontmatter (`joharness.sh:lint_nodes`, `.agents/harness/queue-context.sh`),
  so the TEMPLATE is a convenience for the decomposing session rather than a
  gate on intake — and a requester who names their file `README.md` gets
  silence instead of a queue entry.
- A wrong `priority` VALUE is the one measured defect: `lint_enum` reds an
  unknown value, so `priority: high`, written straight onto `main` by someone
  who never runs `ci`, reds the base branch — and `lint_nodes` walks the
  worktree rather than a diff, so later pull request runs go red for a file
  they never touched. Keep that red. Reading an unknown value as `normal`
  would silently downgrade an urgent requirement, which is what the malformed
  `issue:` guard already reds on purpose: "a claim that looks accepted and
  silently is not" (`joharness.sh`).
- A mistyped KEY has no guard at all. `priorty: urgent` passes — `ci: pass`,
  exit 0 — and the file schedules as `normal`, because `lint_enum` is only
  ever handed the value of a key it looked for. That IS the silent downgrade
  the value check exists to prevent, and it is open. The two legal values are
  named at the top of this section; nothing routes a requester here, and a
  guessed one costs the base branch.

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

**A lead above the fleet now exists, and the peer position stays the
default.** `JOHARNESS_MODE=orchestrated`
([`../orchestrated.md`](../orchestrated.md)) puts a low-tier orchestrator
over the queue: it spawns one manager per item under a cap, holds back a
plan whose scope overlaps work in flight, and kills a stuck manager after
its handover is written. It does not touch the reconcile mechanism —
managers still merge their own pull requests 0 behind `main` — so the
number above is what a run of it should move: fewer collisions taken, or
the hold rule bought nothing. Run 1 — 2026-09-06, counted in
[`../orchestrated.md`](../orchestrated.md), Runs — is the counted run, and
counting it is what discharged the beta label, 2026-09-11. The peer fleet
stays the default: what run 1 did not measure is which of the two empties a
queue faster, and no peer-fleet drain number exists to compare against.

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
