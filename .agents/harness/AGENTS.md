# Harness

Caveman file. Short on purpose — ETH AGENTbench (138 repos): long context file
hurt agent, cost more. Keep only what code cannot tell you. Why-explanations
live in `.agents/docs/` — read there before fighting a rule.

House style for instructions and replies:
[`.agents/docs/caveman.md`](../../.agents/docs/caveman.md). Write new instruction text in it; never
let style eat a fact.

Environment rules are not here. Entrypoint injects them at session start from
the selected layer — as a read-first pointer by default, whole when md=eager
([`.agents/env/README.md`](../env/README.md)).

## Loop

1. **Orient.** Hook prints handover state before first prompt. Hook names
   workstream file for this branch? That is your job. Read whole file. Go to 4.
2. **Pick.** Queue = open GitHub issues, then unplanned requirements
   `docs/product/*.md` (decompose into plans = the work), then plan files
   `docs/plans/*.md` (shape + claim rules: `.agents/docs/plans/README.md`). Hook
   prints queue + wanted agent tier at session start. Oldest actionable
   first, urgent first if marked. No issue, no requirement, no plan: ask
   human. Not invent work. ONE exception, `JOHARNESS_MODE=unsupervised`
   (session start says so): edge = generate work, never ask. Boundary holds
   — no commit under `.agents/harness/`
   ([`docs/product/unsupervised-mode.md`](../../docs/product/unsupervised-mode.md)).
3. **Claim.** Cut branch from `main` (branch flow:
   `.agents/docs/product/README.md`). Write `docs/handover/<workstream>.md`. Push
   NOW — no push, no claim. Hook shows overlap? `/who`. Only `RUNNING`
   session means branch taken.
4. **Build.** Long-running? Re-check `git fetch origin main` ahead/behind
   periodically — another PR merging mid-build is cheap to catch now, one
   hit at step 7 after hours of work is not (`.agents/docs/product/README.md`
   Branch flow).
5. **Verify.** All green or not done. `./joharness.sh ci` runs exactly what
   GitHub CI runs — run it here, before the pull request, not after.
   `./joharness.sh verify` proves the selected environment. Trust counted
   numbers, never written numbers — including numbers in any instruction file.
   Edge to main = review, always; depth scales with the plan's tier
   (`.agents/docs/agent-selection.md`, review depth): haiku one pass, sonnet
   `/code-review` (high) on the full diff, opus adversarial with separate
   lenses. Findings land in the workstream file's `## Review`, one line
   each, BEFORE the fix and in the same commit as it. Fix them or record
   why not — never drop silent. `./joharness.sh review` prints depth for
   this branch and whether record exists; `JOHARNESS_REVIEW=on` in
   `joharness.conf` makes `ci` fail at the edge (PR open, or status
   review/done) without one — off by default, quiet mid-build. Clean pass
   records one line saying clean — empty section not clean pass.
   `review` names files in this diff that already cost other branches;
   `./joharness.sh feedback <path>` prints what they found. File keeps
   drawing findings = rule nobody wrote yet: graduate it
   (`.agents/docs/feedback.md`).
   Fix undoes earlier round's fix? Review churn: stop patching, research
   step at raised tier or effort first (`.agents/docs/agent-selection.md`, review
   churn rule). NEVER skip, disable, or quarantine a test to get green.
   NEVER kick CI: no empty commit, no close-reopen.
6. **Hand over.** Update workstream file in SAME commit as code. Before ending
   any unfinished turn, not only at session end. `/handover` writes it.
7. **Finish.** PR, merge to `main` — every step merges, no long-lived
   integration branch. Session merges its OWN pull request itself, no
   waiting on human (ratified 2026-08-23). Own = opened by this session,
   or the human handed it to this session to drive; never any other PR.
   Merge when ALL hold: GitHub checks green on head; branch 0 behind
   fresh-fetched `origin/main` (behind = "Conflict at finish" reconcile
   first — checks do NOT re-run when `main` moves); `./joharness.sh
   verify` green when the diff touches any non-`*.md` file under
   `joharness.sh`, `.agents/harness/`, `.agents/env/`, `scripts/` — CI cannot run it
   (needs the sandbox); **`./joharness.sh finish` green** — the only guard
   here that fires while the fix is still a commit; edge review recorded
   (step 5); no unresolved human review thread. Anything less stays open. Merge-commit
   method ONLY — squash/rebase merge breaks the merged-branch ancestry
   filter (`.agents/docs/product/README.md` Branch flow). Human veto = revert.
   Branch conflicts with `main` (another PR merged
   first)? Reconcile, do not force through — `.agents/docs/product/README.md`
   Branch flow, "Conflict at finish". Merged branch left standing =
   cosmetic, ignore: hook filters merged branches from claims view.
   Deleting the BRANCH = optional hygiene, human-only (mechanics:
   `.agents/docs/product/README.md` Branch flow). Session NEVER
   `git push --delete`.
   Deleting the FILES is not optional and is yours: PR's final state
   deletes workstream file + done plan file (+ requirement file when last
   plan). Still-useful bits go to the right layer's `AGENTS.md` or `docs/`
   first. Skip it and the base branch accretes finished workstreams that
   later sessions read as current — measured at 23 in one consumer repo,
   thirteen merges adding six and removing none, because "optional,
   human-only" one sentence up reads as covering this one too.
   Do it as the LAST COMMIT BEFORE the pull request opens, never after the
   merge. `./joharness.sh finish` says what merging now would leave and is red
   when that is anything; every other guard fires after the merge and bills
   the next session. Measured, one session, eight pull requests: the three
   that deferred the deletion each turned the base branch red within seconds,
   and the two that did not were the two that retired first.
   `./joharness.sh cleanup` counts what earlier merges left; `--apply`
   stages the workstream-file deletions. Branches it only counts.

## Harness upkeep

Consumer repo: harness upkeep does NOT run in a session holding product
work. Context belongs to the claimed plan. Sync goes to `update.yml`
(weekly cron, `workflow_dispatch` for now), else a subagent where the
runtime offers one — it clones, syncs and pushes, only its summary returns
— else a session of its own. The session mid-plan reviews the resulting
pull request and nothing more.
Routes, preference order:
[`.agents/docs/consumer-repos.md`](../../.agents/docs/consumer-repos.md).

Canonical repo (`JOHARNESS_CANONICAL=1` in `joharness.conf`): rule does not
apply. Harness IS the product here — upkeep is the work, and `upgrade`
refuses to run anyway.

## Decide alone

- Implementation yours. Interface signatures not yours.
- Scope change too big to ratify alone? Decide, write down, flag for human.
  Do not stop.
- Stop and ask ONLY for: money, credentials, hardware, product direction,
  merge conflict into `main` that does not resolve clean.

## Agent selection

Plans get matched to agents: each plan's frontmatter names `agent` tier
(`haiku` | `sonnet` | `opus`) and `effort`. Implementing session may
escalate tier or effort, never downgrade. Write plans for literal reader:
scope AND out-of-scope explicit. Lineup + selection rules:
`.agents/docs/agent-selection.md`.

## Handover

- One file per workstream under `docs/handover/`, lives on work branch.
  Shape: `.agents/docs/handover/TEMPLATE.md`.
- Write only what git cannot tell next session: goal, decisions, rejected
  paths, blockers, next step. Git knows rest.
- Same commit as code. Push early — unpushed work invisible to other sessions.
- Push time not liveness. Wrong both directions. `/who` = truth.
- Copy or sync task (initial harness copy, sync from joharness): NO
  workstream file. Diff self-describing. See protocol "When NOT to write
  one". How to run one: `.agents/docs/consumer-repos.md`.
- Full protocol + why: [`.agents/docs/handover/README.md`](../../.agents/docs/handover/README.md).
