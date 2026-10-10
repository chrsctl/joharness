# Product hierarchy

Requirements above plans, plans above branches. Human adds requirements
ANY time, mid-flight fine; sessions decompose them into plans; plans run
the Loop. Every level = graph nodes ([`.agents/docs/graph.md`](../graph.md)),
files as nodes, delete-on-done as state.

```
docs/product/<requirement>.md   what product needs. Human writes — or a scout drafts
                                and a human merges (orchestrated.md, Bounds). Coarse.
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
  A planning pass ENDS in a tree change that silences the row, or blocked —
  never in "nothing left to plan" with the file standing. Four exits, below
  ("A requirement no plan can serve").
- **Satisfied** = last plan's PR deletes the requirement file with the
  plan file — or, when no plan was ever needed, the planning PR does
  (exit 3 below). Survives in history.
- **Retired unsatisfied** = the REQUESTER decides a condition is no longer
  this repo's to schedule — the work moved elsewhere, the goal changed, the
  evidence will come from somewhere the queue does not reach. Same deletion,
  with the plan, and one difference that is the whole point: the PR records
  in the right layer doc which conditions read true, which did not, and what
  closed. Never a session's call alone (Decide alone: product direction) and
  never inferred from a stale file — a requirement nobody has served is
  UNPLANNED, which is work, not a candidate for this. A decline the
  requester RECORDED, cited by link in the deleting PR, IS the requester
  deciding: the session writes it down, it does not decide it (exit 4
  below).
- Requirement with open plans = silent in hook; its plans speak.

**A deleted requirement does not say WHICH of the two it was**, and two
readers assume the first: `joharness.sh:lint_plans` warns `requirement '<r>'
gone from tree — satisfied while this plan is open?` and `curate`'s
DECLUTTER says `satisfied? confirm in merged history, then delete`. Both ask
rather than assert, and both send the reader to history — which is right, and
is why the layer-doc record above is the load-bearing half rather than a
courtesy. Deleting a requirement without it leaves the tree saying
`satisfied` and nothing saying otherwise.

### A requirement no plan can serve

The `UNPLANNED` test reads one field: the `requirement:` of every open plan
on the base branch. A requirement finished with planning but not satisfied —
every remaining clause already holds, is owned by a plan under ANOTHER
requirement, or was declined — would be offered again every pass, each pass
one fable manager at xhigh.

So a planning pass ends in these, and each changes the tree. They COMBINE
per clause — one requirement can need a plan, a verify plan and a decline
at once — and the requirement is deleted exactly ONCE, by the LAST PR: any
plan or verify plan still names the stem → that plan's PR deletes it, and
the satisfied and declined records ride in that plan's body until then.
Deleted early, an open plan names a missing requirement and
`lint_plans` warns `satisfied while this plan is open?`.

1. **Plans** naming the stem — the normal case.
2. **Verify plan.** A clause owned by a plan under another requirement: one
   small plan naming THIS stem, `needs:` the owner, whose work is to check
   the clause on `main` after the owner merges and, being last, delete the
   requirement. Existing machinery — `needs` holds it, `requirement:`
   silences the row. Not invented work: checking satisfied-when is the work
   the deleting PR owes anyway.
3. **Satisfied, measured.** Every clause reads true on `main` now: the
   planning PR deletes the requirement, and its deletion commit message
   records, per clause, the command or merged PR that shows it — history is
   the record, as for any satisfied requirement. Measuring is a session's job; the "never
   inferred from a stale file" clause above forbids inferring from quiet,
   not from a command's output.
4. **Declined, recorded.** Every clause not covered by 1–3 carries a
   requester decline the session can CITE (issue, PR thread, review): delete
   as Retired unsatisfied, the record naming each declined clause and its
   link. No citable decline = it is the requester's question: `status:
   blocked`, `next:` = the question, push, exit.

Rejected, so the question stays closed:

- **A `planned-out` marker on the requirement.** A status field on a node
  type that has none ([`../plans/README.md`](../plans/README.md), Lifecycle)
  — a stored copy that goes stale the day a clause is un-declined.
- **A clause-level decline vocabulary the test reads.** Largest change, and
  exit 4 already makes the decline legible: in the deletion record, where
  history keeps it.
- **Leave the row, bound the spend.** Every pass terminates normally, so a
  per-manager ceiling never fires; the cost is the count of passes, not any
  one of them.

**Gap still open, filed as plan `requirement-row-claim`:** a requirement
cannot be CLAIMED. Claim resolution offers only `docs/plans/` and
`docs/research/` (`joharness.sh`, `for cand in`; `lint_graph`), so a
planning branch whose workstream file names the requirement in `plan:` — as
`/manage` tells it to — appears in no dispatch row, holds no slot, and reds
`ci` (`plan '<r>' — no such plan or question`). Exits 1–4 end the loop at
the pass's merge; the claim is what stops a SECOND planner while one is in
flight, and what keeps a blocked exit-4 pass from being respawned.

**Intake rejections** (from a sweep of a published `intent.md` practice):

- **No author or status line in a requirement or a plan.** Provenance is
  commits ([`../graph.md`](../graph.md), Rules); neither node type carries a
  status field. A workstream file does carry `status:`, because a session
  claims with it.
- **No detector writes the requirement.** The human writes it, or merges a
  scout's draft ([`../orchestrated.md`](../orchestrated.md), Bounds).
  Convention, not mechanism: nothing gates it.

**Intake facts.** A requirement with NO frontmatter is scheduled anyway
(priority defaulted); a file named `README.md`, `TEMPLATE.md` or `VISION.md`
is never scheduled. A wrong `priority` VALUE reds `ci` on the base branch —
kept, because reading it as `normal` would silently downgrade an urgent
requirement. A mistyped KEY (`priorty: urgent`) has no guard and schedules
as `normal`: the two legal values are `normal` and `urgent`.

## Branch flow

- `main` = the only long-lived line. One branch per plan, cut from `main`.
  No long-lived integration branch: PR + `ci` + review-at-edge do that
  job. An epic branch buys stacking, one-commit rollback and one CI run, at
  the price of work invisible on `main` for the epic's life and an abandoned
  integration branch multiplying the abandoned-edge problem. Re-open only on
  a measurement.
- **Start** = Claim (Loop step 3): cut `claude/<plan>`, workstream file,
  push.
- **Finish** = PR green + reviewed, merge to `main`, PR deletes plan file
  (+ requirement file when last plan). The merging click is the session's
  own for its own PR (conditions in `.agents/harness/AGENTS.md` step 7),
  merge-commit method only (why: the filter note below). Human veto = revert. Rule syncs to consumers with the
  harness like every Loop rule; a consumer wanting human-click merges
  overrides in its own `AGENTS.md` Part 2. Merged branch may stand: the
  session-start hook filters branches merged into `main` out of the
  claims view, so deadwood is `git branch -r` noise, not fake in-flight
  work. Filter reads ancestry, so it rests on PRs merging by merge
  commit — GitHub's "Squash and merge" / "Rebase and merge" buttons hide
  ancestry, and branches merged that way would read as in-flight again.
  Prose, not a gate: one squash breaks the filter for every later session.
  The remedy is a forge setting — restrict the allowed merge methods.
  Deleting = optional hygiene, human-only, anytime: Delete-branch button
  on merged PR page, or repo setting "Automatically delete head
  branches". Sessions never `git push --delete` — deletion is the
  human's call. Abandoned UNMERGED branches are the deadwood the filter
  cannot hide: they read as in-flight until a human triages — salvage
  plans from their workstream files, then delete.
- `urgent` = same mechanics, jumps queue.
- Merge commits on shared branches, never rebase — history rewrite breaks
  other sessions' checkouts.
- **Conflict at finish** = local view of `main` is from session start; another
  session's PR may have merged since. Before opening or merging the PR,
  `git fetch origin main` and check ahead/behind — do not trust a stale
  clone. Behind = merge `main` into branch (not rebase), resolve, re-run
  `ci`, push. Conflict does not resolve clean (semantic, unclear intent) =
  do not force-merge through it — decide-alone exception (`.agents/harness/AGENTS.md`),
  stop, record in workstream file's `Blockers`, ask human. No merge queue:
  adopt one (the forge's own) only when a measurement shows sessions losing
  time to reconciles.
- **Long-running session** = re-check `git fetch origin main` ahead/behind
  periodically during Build too, not only at Finish — a conflict caught
  mid-build is cheap, one hit at finish after hours of work is not.

## Orchestration

One low-tier orchestrator sits over the queue
([`../orchestrated.md`](../orchestrated.md)): it spawns one manager per item
under a cap, holds back a plan whose scope overlaps work in flight, and kills
a stuck manager after its handover is written. Managers still merge their
own pull requests 0 behind `main`.

**The cost that scales with width is the reconcile.** About one merge in
four arrives only after its branch pulled `main` in (51 of 201 merges,
`origin/main` 2026-08-30). Count it by the reconcile merge's own subject,
never `--grep=reconcile`:

```bash
git log --oneline origin/main --grep='^Merge origin/main\|^Merge remote-tracking branch' | wc -l
git log --oneline --merges origin/main | wc -l
```

A plan that widens the fleet says what it expects to happen to that number.
Worktrees would not move it: they isolate files but the conflict still lands
at the pull request merge.

**The gap: claim-by-push only covers work that enters through the queue.** A
request typed at a running session enters nowhere. The mitigation is the
Loop's own rule: nothing builds unplanned, and a plan file is claimable.

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
