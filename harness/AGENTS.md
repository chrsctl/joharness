# Harness

Caveman file. Short on purpose — ETH AGENTbench (138 repos): long context file
hurt agent, cost more. Keep only what code cannot tell you. Why-explanations
live in `docs/` — read there before fighting a rule.

House style for instructions and replies:
[`docs/caveman.md`](docs/caveman.md). Write new instruction text in it; never
let style eat a fact.

Environment rules are not here. Entrypoint injects them at session start from
the selected layer — as a read-first pointer by default, whole when md=eager
([`env/README.md`](env/README.md)).

## Loop

1. **Orient.** Hook prints handover state before first prompt. Hook names
   workstream file for this branch? That is your job. Read whole file. Go to 4.
2. **Pick.** Queue = open GitHub issues, then unplanned requirements
   `docs/product/*.md` (decompose into plans = the work), then plan files
   `docs/plans/*.md` (shape + claim rules: `docs/plans/README.md`). Hook
   prints queue + wanted agent tier at session start. Oldest actionable
   first, urgent first if marked. No issue, no requirement, no plan: ask
   human. Not invent work.
3. **Claim.** Cut branch from `main` (branch flow:
   `docs/product/README.md`). Write `docs/handover/<workstream>.md`. Push
   NOW — no push, no claim. Hook shows overlap? `/who`. Only `RUNNING`
   session means branch taken.
4. **Build.** Long-running? Re-check `git fetch origin main` ahead/behind
   periodically — another PR merging mid-build is cheap to catch now, one
   hit at step 7 after hours of work is not (`docs/product/README.md`
   Branch flow).
5. **Verify.** All green or not done. `./joharness.sh ci` runs exactly what
   GitHub CI runs — run it here, before the pull request, not after.
   `./joharness.sh verify` proves the selected environment. Trust counted
   numbers, never written numbers — including numbers in any instruction file.
   Edge to main = review, always; depth scales with the plan's tier
   (`docs/agent-selection.md`, review depth): haiku one pass, sonnet
   `/code-review` (high) on the full diff, opus adversarial with separate
   lenses. Findings land in the workstream file's `## Review`, one line
   each, BEFORE the fix and in the same commit as it. Fix them or record
   why not — never drop silent.
   Fix undoes earlier round's fix? Review churn: stop patching, research
   step at raised tier or effort first (`docs/agent-selection.md`, review
   churn rule). NEVER skip, disable, or quarantine a test to get green.
   NEVER kick CI: no empty commit, no close-reopen.
6. **Hand over.** Update workstream file in SAME commit as code. Before ending
   any unfinished turn, not only at session end. `/handover` writes it.
7. **Finish.** PR, merge to `main` — every step merges, no long-lived
   integration branch. Session merges its OWN pull request itself, no
   waiting on human (ratified 2026-08-23), when ALL hold: GitHub checks
   green on head; `./joharness.sh verify` green when the diff touches any
   shell script (`joharness.sh`, `harness/`, `env/`, `scripts/`) — CI
   cannot run it (needs the sandbox); edge review recorded (step 5); no
   unresolved human review thread; merges clean. Anything less stays
   open. Merge-commit
   method ONLY — squash/rebase merge breaks the merged-branch ancestry
   filter (`docs/product/README.md` Branch flow). Never merge another
   author's PR. Human veto = revert.
   Branch conflicts with `main` (another PR merged
   first)? Reconcile, do not force through — `docs/product/README.md`
   Branch flow, "Conflict at finish". Merged branch left standing =
   cosmetic, ignore: hook filters merged branches from claims view.
   Deleting = optional hygiene, human-only (mechanics:
   `docs/product/README.md` Branch flow). Session NEVER
   `git push --delete`. PR's final
   state deletes workstream file + done plan file (+ requirement file when
   last plan). Still-useful bits go to the right layer's `AGENTS.md` or
   `docs/` first.

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
`docs/agent-selection.md`.

## Handover

- One file per workstream under `docs/handover/`, lives on work branch.
  Shape: `docs/handover/TEMPLATE.md`.
- Write only what git cannot tell next session: goal, decisions, rejected
  paths, blockers, next step. Git knows rest.
- Same commit as code. Push early — unpushed work invisible to other sessions.
- Push time not liveness. Wrong both directions. `/who` = truth.
- Copy or sync task (initial harness copy, sync from joharness): NO
  workstream file. Diff self-describing. See protocol "When NOT to write
  one".
- Full protocol + why: [`docs/handover/README.md`](docs/handover/README.md).
