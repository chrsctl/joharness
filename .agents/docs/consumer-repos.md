# Consumer repos

Consumer repo = child repo = any repo running a copy of this harness.
joharness is canonical, consumers receive. Everything about creating and
updating one starts here.

Direction rule (doctrine + why:
[`product/README.md`](product/README.md) Reconciliation): a fix born
ANYWHERE lands in joharness `main` first, then syncs out. Never
consumer-to-consumer, never consumer-only. An issue filed in a consumer
about harness behaviour goes there through the clerk's UPSTREAM verdict (`.claude/commands/clerk.md`).

That is where a fix goes. How a consumer session gets it there — deciding
whether the harness is actually wrong, carrying the measurement canonical
cannot reproduce, and why the loop closes at the sync rather than the merge —
is [`feedback.md`](feedback.md) § *When the consumer is the detector*.

Context rule and Source rule: `.agents/harness/AGENTS.md`, "Decide alone"
(the "Consumer repo:" bullet) and step 4. A product diff touching the files
step 4 names is harness work, routed per the direction rule, so the merge
gate's `verify` clause never meets a product diff. Sync routes: [Pick
route](#pick-route). A session holding product work reviews the resulting
pull request and nothing more.

In CANONICAL (`JOHARNESS_CANONICAL=1` in `joharness.conf`) the context rule
does not apply: the harness IS the product here, `upgrade` refuses to run,
and the sync goes outward.

## Pick route

Routes below in preference order for a consumer. Reach past a row only when
the rows above it cannot answer.

| Situation | Route |
| --- | --- |
| Repo has no harness yet | [New consumer](#new-consumer) |
| Routine update, `update.yml` present | [Consumer CI](#update-consumer-ci) — no checkout, no session context |
| CI cannot reach canonical, or none seeded | Subagent — it clones and syncs; only its summary returns |
| Sync conflicted, or no subagent available | [Upgrade](#update-upgrade-from-the-consumer) — one command, in a session of its own |
| Canonical checkout in reach | [By hand](#update-by-hand) |
| Agent session sits in the consumer | [Agent](#update-agent-in-the-consumer) |
| Sync reported `AHEAD` | [Ahead](#ahead) — do not overwrite |
| The sync branch is pushed and the run ended red | [Drive it to merged](#the-sync-pull-request-drive-it-to-merged) |

An update pull request with no checks on it is not a green one: see
[Consumer CI](#update-consumer-ci) for the token.

## New consumer

```bash
.agents/scripts/bootstrap-consumer.sh --env <layer> <dir>   # --dry-run first, it reports
```

Places the harness set, seeds consumer-own stubs (`joharness.conf`,
`ci.yml`, `update.yml`, `README.md`, AGENTS.md Part 2), strips joharness's
live workstream files, plans and canonical marker. Script prints the
remaining steps; follow them.

`--env <layer>` picks the environment layer, and only that layer ships
([Layers](#layers)). Omit it for `none`; the repo can select one later.

Every switch the child runs under is ASKED at first contact, when a terminal
is there to answer on. Each has a flag that answers it instead, and the
interview asks only what no flag answered:

| Question | Flag | Default |
| --- | --- | --- |
| environment layer | `--env <layer>` | `none` |
| provision it when | `--env-setup <lazy\|eager>` | `lazy` |
| inject its rules when | `--env-md <lazy\|eager>` | `lazy` |
| gate the review record | `--review <off\|on>` | `off` |

The two layer-shaped questions are skipped when the selected layer is `none`.
Enter takes the value in brackets, either word takes itself, and `y`/`n` take
the second and first. A run with no terminal asks nothing: a conf seeded here
gets the defaults above, a conf that already exists keeps its own values.

A question offers the value ALREADY IN FORCE as its default, so Enter never
strips a selection; a key is written into an existing conf only when a flag
gave it or the interview answered it.

Never bootstrap onto a repo already running the harness: the script refuses,
its purge eats live `docs/plans|product|handover`. Never hand-copy a raw
joharness clone: it carries joharness's queue and marker.

## What a consumer carries

The harness a consumer receives is the part it runs:

| Ships | Why |
| --- | --- |
| `joharness.sh`, `.agents/harness/*.sh` hooks | every session runs them |
| `.agents/harness/AGENTS.md`, `.agents/docs/` | the protocol itself |
| `.agents/env/README.md` + the selected layer | [Layers](#layers) |
| `.claude/` settings, commands, skills | Claude Code reads them from the tree |
| `CLAUDE.md`, `AGENTS.md`, `.gitattributes` | loaded every session |
| `.agents/LICENSE`, `.agents/NOTICE` | the grant the copy travels under (MIT's one condition); the consumer's root `LICENSE` stays its own |

Canonical-only, never shipped:

| Stays behind | Why |
| --- | --- |
| `.agents/scripts/` | both tools refuse to run outside canonical |
| `.agents/harness/selftest.sh` | tests harness code a consumer does not edit |

 `ci` in a consumer says `not here (canonical-only)` for the selftest and
runs the rest.

A consumer still carrying them: every sync reports them, removals never
travel, so the delete is a human's:
`git rm -r .agents/scripts .agents/harness/selftest.sh`.

## Update: upgrade from the consumer

```bash
./joharness.sh upgrade --dry-run    # reports, writes nothing
./joharness.sh upgrade              # fetches canonical, syncs this repo forward
```

Clones the canonical named by `CANONICAL_REPO` in the consumer's own
`.github/workflows/update.yml` and runs ITS sync engine here — the engine
this repo no longer carries and could not run anyway. Then review the diff,
`./joharness.sh ci`, commit.

Refused in canonical: there, syncing out is
[by hand](#update-by-hand).

## Settings a child does not answer

First contact asks about every switch. Update asks about the ones that did not
exist yet. **Changing one later is the third route, below.**

The conf is consumer-own and the sync never touches it, so a key added after
bootstrap has no line and takes the fail-closed default in silence. Every
sync names the declared keys the conf does not answer, each with its default
and meaning, and:

- **reports always**, `update.yml` included: in the pull request body when the
  run changes files, in the Actions log otherwise;
- **asks only with a terminal**;
- **writes only what was answered.** Enter or `n` leaves the file alone. A key
  the conf already answers is not named, asked about, or touched.

The default applies whether or not the line exists. Keys are declared once in
`.agents/scripts/conf-keys.sh`, canonical-only.

## Name no consumer

Harness text names no consumer repository, in the canonical-only files
either. Cite the measurement, never the repository: the command, the
commit, the counts, the date. The same goes for a consumer's plan and item
names. The canonical repository's own name, commit hashes and pull request
numbers are not covered. Not gated. The edge review catches it.

## Settings a child wants to CHANGE

The sync answers "this key is absent"; it never re-opens one already
answered. Re-ask every switch instead, from canonical, naming the child:

```bash
.agents/scripts/bootstrap-consumer.sh --reconfigure <consumer-dir>
```

`joharness.conf` never syncs, so a consumer keeps the comments it was seeded
with. An instruction file must not point at a conf comment for a fact a
session NEEDS; point at a command's own output, which ships.

Same questions as first contact, each offering the value in force in THAT
child's conf; answers go to its `joharness.conf`. No sync, no seeding, no
purge.

- **Flags answer without asking**, the same ones first contact takes, so a
  scripted change is `--reconfigure --review on <dir>`.
- **It writes only what somebody decided.** Enter keeps a value; a headless
  run with no flags changes nothing and says so.
- **Refused** on a target that does not exist, one that does not run the
  harness yet (bootstrap it first), and a copy of the canonical repository.

## Update: consumer CI

`.github/workflows/update.yml`, seeded at bootstrap. Runs the same sync
weekly (Monday 06:00 UTC) and on `workflow_dispatch`, force-pushes branch
`joharness-update`, opens or refreshes one pull request carrying the sync
report. Update now = run that workflow: a human from the consumer's Actions
tab, or a session directly, which is the cheaper route when a session is
already open.

A session dispatches it with a GitHub tool that runs a workflow (Claude
Code: `mcp__github__actions_run_trigger`, method `run_workflow`): workflow
file name and a `ref`.

Two things to know before relying on it:

- **The run wears the human's name.** The token behind the tool is theirs, so
  a dispatched run is indistinguishable in the Actions tab from someone
  clicking the button. Say in the session that you dispatched it; the Actions
  tab will not.
- **Only the default branch is dispatchable.** GitHub registers a workflow
  for dispatch from the default branch only, so a workflow added on a work
  branch cannot be run before its own merge, and `ref` chooses which branch's
  CODE runs, not whether the workflow exists. A gate that must fire before
  the pull request therefore belongs in `joharness.sh ci`, never in a new
  workflow — which is what `.github/workflows/ci.yml`'s own header says.

Consumer-own file, never synced: a fork's own `CANONICAL_REPO` or another
cadence stays put.

Set repository secret `JOHARNESS_UPDATE_TOKEN` (PAT: contents +
pull-requests write on the consumer, read on canonical) when the canonical
is private, when the update pull request must run `ci`, or when the org
disables Actions creating pull requests. Without it the run uses
`GITHUB_TOKEN`, hits all three limits, and the pull request carries no CI
runs: GitHub suppresses workflow-on-workflow events.

## A red base branch

Base branch red before change. Four points:

1. Harness keeps no record of which tests are red on base. `ci` and
   `finish` read git and tree, never a check run. A consumer that wants
   one owns it, in its own `docs/`.
2. Step 7 still binds every manager: "base green" is an infrastructure
   reading, "re-derived at every check, never inherited". Record cannot
   replace your own check. At most it tells you what to expect before you check.
3. Attribution needs no record. Steps, in order:
   1. List failing TESTS from your head's run, not failing checks: one
      check can be whole suite, and same red check can hide one more
      failing test.
   2. Run only those tests on commit your PR run merged with. A
      `pull_request` run checks out head merged into base TIP, not your
      merge base; base tip may have broken test after you branched.
   3. Run head and base side by side, same machine, same hour. Earlier
      CI run against re-run now compares two environments.
   4. Test failing on both with same message = not provably yours. Still
      not proof: base failure stops test early and can hide a second
      break from your diff. Re-run that test once base is green.
   Cost = failing tests on two commits, not suite.
4. A record a consumer keeps (base commit, command, time, result) is a
   forecast only (point 2). Harness prescribes no file and no shape.

## Local checks

`JOHARNESS_CHECKS=local` in the environment only (a `joharness.conf` line is
ignored; `finish` and session start print a warning while one stays) makes
step 7's first condition `finish` running `ci`, and
`verify` when `joharness.sh:checks_verify_needed` holds, on this head.
`ci` runs the harness's own checks (`joharness.sh:cmd_ci`), never a
consumer's suites. The key saves the wait, not the run: GitHub still runs
the workflow when Actions can, except a job the repository VARIABLE of the
same name gates off (`.github/workflows/ci.yml`, `lint`). Every job step
that is not `./joharness.sh ci` or `verify` is then read by nobody, and a
suite needing a database or a browser stops counting.

The repository variable alone is the out-of-credits switch; the session's
step-7 read of the head's checks detects the skipped `lint`
(`.agents/harness/AGENTS.md` step 7). The environment variable needs no such
read and switches every `finish` in that environment.

One command of the consumer's own can stand behind the verdict: a file
`local-check` at the repository root (`joharness.sh:checks_local_check`).
Under local mode `finish` runs the HEAD's copy with `bash`, from the root,
after `ci` and `verify`, and is red on its non-zero exit or on
`JOHARNESS_LOCAL_CHECK_MINUTES` (default 30) running out — a timeout is
red, never a skip. The path is outside `.agents/` and `.claude/`: the sync
never writes it and the shipped `.gitattributes` pins nothing on it. A
Windows clone with `core.autocrlf=true` checks it out CRLF and bash fails on
the `\r`: pin it per clone (`local-check text eol=lf` in
`.git/info/attributes`), since a pin in the root `.gitattributes` marks that
file AHEAD (below).

The head's copy runs because a pull request repairing a check broken on
the base branch must be able to pass. So a branch can weaken it, as it can
weaken what `ci` runs: a branch changing `local-check` against the merge
base prints `CHECK CHANGED on this branch` with the diff stat, and edge
review reads it. The gate's strength is review, not immutability. A copy
present here but not in HEAD (ignored) is named and not run.

Status quo:

- With no `local-check`, `finish` says `no consumer check declared
  (local-check)`: the consumer's own suites gate nothing. With one, the gate
  is only as strong as what the file runs.
- `finish` names the rest of the gap only in general ("Not covered here:
  any job in .github/workflows/ that ci does not run", plus the per-layer
  step). No role runs those jobs on a clock or files their failures.
- A criterion counted established because the workflow INVOKES its suite
  proves nothing while the key holds: invoking is not passing.

Local mode is a posture for an outage, not for weeks: it gates merges on
the harness's checks and, of the consumer's own, only what `local-check`
runs.

## The sync pull request: drive it to merged

`update.yml` gets the branch pushed; everything after is a person or a
session.

**The branch is bot-owned.** Each run does `git checkout -B joharness-update`
from the freshly checked-out default branch and `git push --force`. Two
consequences, and the second is the one that bites:

1. A stale sync branch does not need reconciling. **Re-run the workflow.** It
   rebuilds from the current default branch, so the result is by construction
   0 behind, and the open pull request is reused with a refreshed body.
2. **Anything you commit onto that branch dies at the next run.** Do it the
   way above.

### When the workflow ends red

Three failures. Read the failing run before assuming the sync itself broke.
The other two leave `joharness-update` as the last successful run left it.

| what the log says | what it means | what to do |
| --- | --- | --- |
| `GitHub Actions is not permitted to create or approve pull requests` | The sync worked. Only the pull request could not be opened. | Open it by hand against `joharness-update`, then fix the cause below. |
| `consumer files are AHEAD of canonical` | A consumer edited harness-owned files locally. | [Ahead](#ahead) — never overwrite. |
| the sync step itself failed | A genuine sync failure — and the only one of the three that fails before the commit step. | Read the report; this run pushed nothing. |

The first's cause is a repository setting: enable *Allow GitHub Actions to
create and approve pull requests*, or set `JOHARNESS_UPDATE_TOKEN`.
Prefer the token: the setting alone opens a pull request carrying no checks.

### Before merging one

A sync diff is harness-owned files only, so the consumer's own suites are the
thing that can break, and they are the thing to run:

- `./joharness.sh ci` — the harness's own bar.
- `./joharness.sh verify` — when the diff touches a non-`*.md` file under
  `joharness.sh`, `.agents/harness/`, `.agents/env/` or `.agents/scripts/`. A sync
  usually does. CI runs it only where the selected layer is CI-runnable
  (`.agents/env/README.md`) AND this repo's `ci.yml` carries the job (consumer-own,
  never synced). Read the run; otherwise run it.
- The consumer's own loop (`run-all.sh` or whatever it calls its suites). The
  sync can narrow an enum or tighten a guard that consumer files then fail.
- `./joharness.sh finish` — a sync branch carries no workstream file by design
  (`handover/README.md`, "When NOT to write one").

Read the diff against canonical: the report says what was copied, not what it means.

## Update: by hand

From a clean canonical checkout:

```bash
.agents/scripts/sync-to-consumer.sh --dry-run <dir>
.agents/scripts/sync-to-consumer.sh <dir>
```

Then commit in the consumer. Uncommitted changes under synced paths in
canonical abort the run — commit there first.

## Update: agent in the consumer

Fallback for what CI cannot finish (see [Pick route](#pick-route)).

`upgrade` refuses to run when the branch carries a workstream file, because
that file IS the claim that a session holds product work
(`.agents/harness/AGENTS.md`, "Decide alone", "Consumer repo:"). The steps below start by
cutting a sync branch, which carries none by protocol, so they pass. A
genuine mid-plan sync overrides with `JOHARNESS_UPGRADE_IN_SESSION=1` and
says why in the commit — deliberate and visible, never silent.

[Upgrade](#update-upgrade-from-the-consumer) does the sync; the session owes
the ritual around it:

```bash
git fetch origin main && git checkout -b claude/harness-sync origin/main
./joharness.sh upgrade --dry-run
./joharness.sh upgrade
./joharness.sh ci
git add -A && git commit -m "Sync harness from <canonical>"
git push -u origin HEAD
```

- NO workstream file: the sync diff is self-describing
  ([`handover/README.md`](handover/README.md), "When NOT to write one").
  The commit message carries the source.
- Doing it by hand instead (a canonical checkout already on disk):
  [by hand](#update-by-hand). Clone it OUTSIDE the consumer tree, or
  `git add -A` swallows it, and never with `--depth` — stale-vs-`AHEAD` is
  decided by blob identity against canonical history, and a shallow clone
  reads honestly-synced files as `AHEAD` forever. On Windows clone with
  `git clone -c core.autocrlf=false -c core.eol=lf`: the engine compares
  working-tree bytes, and `core.autocrlf=true` ships CRLF into the
  consumer. `upgrade` gets all three right.
- The synced `.gitattributes` pins the harness-owned trees (`.agents/**`,
  `.claude/commands/**`, `.claude/skills/**`) to LF checkouts — including
  consumer-own files placed inside them, which the sync otherwise leaves
  alone. A Windows `.bat`/`.cmd` helper inside your own skill will check
  out LF and break under cmd.exe: keep native-eol files outside the pinned
  trees, or add your own later-wins pattern below the pinned block (that
  edit marks your `.gitattributes` AHEAD — deliberate: you took over the
  file, future pin changes stop arriving).

## Layers

One layer per consumer: the one its own `joharness.conf` names, plus
`.agents/env/README.md`. Every other layer stays in canonical — a repo gains
nothing from scripts it never runs, and its own `ci` would shellcheck them
every push.

Switch layer:

```bash
./joharness.sh env <name>      # in the consumer; warns the layer is not here yet
```

Then sync (any route above). Layers a consumer does not select are reported;
removals never travel, so the delete is a human's
(`git rm -r .agents/env/<name>`). A layer the consumer wrote itself is
reported and left alone.

## Exit codes

| Code | Means |
| --- | --- |
| 0 | Synced clean. |
| 1 | Refused before any write — consumer untouched. Missing summary line instead = a mid-write tool failure, writes may have landed. |
| 2 | Some consumer copies `AHEAD`. Every other update applied, nothing clobbered. |
| 3 | Listed path missing from canonical. Sync ran; canonical's `FILES`/`DIRS` list or tree is wrong. |

## Ahead

`AHEAD` = consumer content matches no historical canonical blob of that
path. A local edit, or this canonical checkout is stale. The sync never
overwrites it, and re-running changes nothing.

Fix = the direction rule: land that change in joharness `main`, then sync
again. Fetching a current canonical settles the stale case.

## What syncs

Harness-owned vs consumer-own: table in
[`.agents/harness/README.md`](../harness/README.md). Exact list: `FILES` and
`DIRS` in `.agents/scripts/sync-to-consumer.sh`. Root `AGENTS.md` is spliced, not
copied — canonical above the `# Part 2 — project` marker, consumer's own
below. Removals do not travel: a file canonical deleted stays, reported
`consumer-only`.
