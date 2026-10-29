# Consumer repos

Consumer repo = child repo = any repo running a copy of this harness.
joharness is canonical, consumers receive.

Direction rule (why: [`product.md`](product.md) Reconciliation):
a fix born ANYWHERE lands in joharness `main` first, then syncs out. Never
consumer-to-consumer, never consumer-only. A consumer session gets it there
per [`feedback.md`](feedback.md) § *When the consumer is the detector*; an
issue filed in a consumer, through the clerk's UPSTREAM verdict
(`.claude/commands/clerk.md`).

Context rule and Source rule: `.agents/harness/AGENTS.md`, "Decide alone"
(the "Consumer repo:" bullet) and step 4. A product diff touching the files
step 4 names is harness work, routed per the direction rule. A session holding
product work reviews the sync pull request ([Pick route](#pick-route)) and
nothing more. In CANONICAL (`JOHARNESS_CANONICAL=1` in `joharness.conf`) the
context rule does not apply, `upgrade` refuses to run, and the sync goes outward.

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
live workstream files, plans and canonical marker, prints the remaining
steps. Only the `--env` layer ships ([Layers](#layers)); omitted = `none`.

Every switch is ASKED at first contact when a terminal is there; a flag
answers it instead:

| Question | Flag | Default |
| --- | --- | --- |
| environment layer | `--env <layer>` | `none` |
| provision it when | `--env-setup <lazy\|eager>` | `lazy` |
| inject its rules when | `--env-md <lazy\|eager>` | `lazy` |
| gate the review record | `--review <off\|on>` | `off` |

Layer `none` skips the two layer questions. Enter takes the value in
brackets (the value ALREADY IN FORCE), either word takes itself, `y`/`n` take
the second and first. No terminal = no questions: a seeded conf gets the
defaults, an existing one keeps its values. A key is written into an existing
conf only when a flag gave it or the interview answered it.

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

Canonical-only, never shipped: `.agents/scripts/` (both tools refuse to run
outside canonical) and `.agents/harness/selftest.sh` (`ci` in a consumer says
`not here (canonical-only)`). A consumer still carrying them: every sync
reports them, removals never travel, the delete is a human's:
`git rm -r .agents/scripts .agents/harness/selftest.sh`.

## Update: upgrade from the consumer

```bash
./joharness.sh upgrade --dry-run    # reports, writes nothing
./joharness.sh upgrade              # fetches canonical, syncs this repo forward
```

Clones the canonical named by `CANONICAL_REPO` in the consumer's own
`.github/workflows/update.yml` and runs ITS sync engine here. Then review the
diff, `./joharness.sh ci`, commit. Refused in canonical: there, syncing out is
[by hand](#update-by-hand).

## Name no consumer

Harness text, canonical-only files included, names no consumer repository,
plan or item: cite the measurement (command, commit, counts, date). The
canonical's own name, hashes and pull request numbers are fine. Not gated:
edge review catches it.

## Settings a child does not answer, or wants to CHANGE

First contact asks about every switch; update asks about the ones that did not
exist yet. The conf is consumer-own and never syncs, so a key added after
bootstrap has no line and takes the fail-closed default in silence (with or
without a line, the default applies). Keys are declared once in
`.agents/scripts/conf-keys.sh`, canonical-only. Every sync names the declared
keys the conf does not answer, each with its default and meaning, and:

- **reports always**, `update.yml` included: in the pull request body when the
  run changes files, in the Actions log otherwise;
- **asks only with a terminal**;
- **writes only what was answered.** Enter or `n` leaves the file alone. A key
  the conf already answers is not named, asked about, or touched.

The sync never re-opens an answered key. To CHANGE one, re-ask every switch
from canonical, naming the child:

```bash
.agents/scripts/bootstrap-consumer.sh --reconfigure <consumer-dir>
```

Same questions as first contact, each offering the value in force in THAT
child's conf; answers go to its `joharness.conf`. No sync, no seeding, no purge.

- **Flags answer without asking**: `--reconfigure --review on <dir>`.
- **It writes only what somebody decided.** Enter keeps a value; a headless
  run with no flags changes nothing and says so.
- **Refused** on a target that does not exist, one that does not run the
  harness yet (bootstrap it first), and a copy of the canonical repository.

A consumer keeps the conf comments it was seeded with: an instruction file
points at a command's own output (which ships), never at a conf comment.

## Update: consumer CI

`.github/workflows/update.yml`, seeded at bootstrap, consumer-own (never
synced). Runs the same sync weekly (Monday 06:00 UTC) and on
`workflow_dispatch`, force-pushes branch `joharness-update`, opens or
refreshes one pull request carrying the sync report. Update now = run that
workflow: from the Actions tab, or from a session
(`mcp__github__actions_run_trigger`, method `run_workflow`, workflow file
name and a `ref`).

- **The run wears the human's name** (their token): say in the session that
  you dispatched it; the Actions tab will not.
- **Only the default branch is dispatchable**: a workflow added on a work
  branch cannot run before its merge; `ref` picks which branch's CODE runs. A
  gate that must fire before the pull request belongs in `joharness.sh ci`,
  never in a new workflow.

Set repository secret `JOHARNESS_UPDATE_TOKEN` (PAT: contents +
pull-requests write on the consumer, read on canonical) when the canonical
is private, the update pull request must run `ci`, or the org disables
Actions creating pull requests. `GITHUB_TOKEN` hits all three: GitHub
suppresses workflow-on-workflow events, so its pull request carries no CI.

## A red base branch

Harness keeps no record of which tests are red on base: `ci` and `finish`
read git and tree, never a check run. A record a consumer keeps (own `docs/`,
any shape) is a forecast only; step 7's "base green" is re-checked every
time, never inherited. Attribution needs no record:

1. List failing TESTS from your head's run, not failing checks (one red check
   can hide one more failing test).
2. Run only those on the commit your PR run merged with: a `pull_request`
   run merges head into base TIP, not your merge base.
3. Head and base side by side, same machine, same hour.
4. Failing on both with the same message = not provably yours, still not
   proof (an early base failure can hide a second break). Re-run once base is green.

## Local checks

`JOHARNESS_CHECKS=local` in the environment only (a `joharness.conf` line is
ignored, with a warning from `finish` and session start) makes step 7's first
condition `finish` running `ci` (the harness's own checks,
`joharness.sh:cmd_ci`), and `verify` when `joharness.sh:checks_verify_needed`
holds, on this head. GitHub still runs the workflow when Actions can, except
a job the repository VARIABLE of the same name gates off
(`.github/workflows/ci.yml`, `lint`); every other job step is then read by
nobody. The repository variable alone is the out-of-credits switch: step 7
detects the skipped `lint`. The environment variable switches every `finish`
in that environment.

In a consumer, one command of its own must stand behind the verdict: a file
`local-check` at the repository root (`joharness.sh:checks_local_check`).
Under local mode `finish` runs the HEAD's copy with `bash`, from the root,
after `ci` and `verify`, and is red on its non-zero exit or on
`JOHARNESS_LOCAL_CHECK_MINUTES` (default 30) running out — a timeout is
red, never a skip. The sync never writes it. Windows with
`core.autocrlf=true` checks it out CRLF and bash fails on the `\r`: pin it per
clone (`local-check text eol=lf` in
`.git/info/attributes`); a pin in the root `.gitattributes` marks that file AHEAD.

The head's copy runs so a pull request repairing a check broken on base can
pass; a branch can therefore weaken it. A branch changing `local-check`
against the merge base prints `CHECK CHANGED on this branch` with the diff
stat, for edge review. A copy present here but not in HEAD is named and not run.

With no `local-check` in HEAD, a consumer's local-mode `finish` is red:
`NO CHECK     no consumer check declared (local-check)`. Without it the
consumer's suites gate nothing, and a merge waiting for no GitHub check
lands on `ci` alone — gx merged ten regressions that way (gx #797). Clear it
by committing `local-check` running the consumer's own suites (the ones its
workflow runs); `exit 0` clears it too and gates nothing, which edge review
reads as a weakening. The canonical repository (`JOHARNESS_CANONICAL=1`)
has no suites of a consumer's: there it stays a note and green. The sync
delivering this red is itself red in such a consumer: land `local-check`
first (§ "Before merging one"). `finish` names the rest of
the gap only in general ("Not covered here: any job in .github/workflows/ that
ci does not run"); no role runs those jobs on a clock or files their failures. A workflow that INVOKES a suite
proves nothing while the key holds. Local mode is a posture for an outage,
not for weeks.

## The sync pull request: drive it to merged

`update.yml` gets the branch pushed; everything after is a person or a
session. **The branch is bot-owned**: each run rebuilds `joharness-update`
from the default branch (`git checkout -B`, `git push --force`). So a stale
sync branch needs no reconciling: **re-run the workflow** (0 behind by
construction, same pull request, refreshed body). **Anything you commit onto
that branch dies at the next run.**

### When the workflow ends red

Read the failing run before assuming the sync broke; the other two leave
`joharness-update` as the last successful run left it:

| what the log says | what it means | what to do |
| --- | --- | --- |
| `GitHub Actions is not permitted to create or approve pull requests` | The sync worked. Only the pull request could not be opened. | Open it by hand against `joharness-update`, then fix the cause below. |
| `consumer files are AHEAD of canonical` | A consumer edited harness-owned files locally. | [Ahead](#ahead) — never overwrite. |
| the sync step itself failed | A genuine sync failure — and the only one of the three that fails before the commit step. | Read the report; this run pushed nothing. |

Fix the first with `JOHARNESS_UPDATE_TOKEN` (preferred) or the setting *Allow
GitHub Actions to create and approve pull requests*, which alone opens a pull
request carrying no checks.

### Before merging one

A sync diff is harness-owned files only; the consumer's own suites are what
breaks:

- `./joharness.sh ci` — the harness's own bar.
- `./joharness.sh verify` — on the paths `.agents/harness/AGENTS.md` step 7
  names; a sync usually touches them. CI runs it only where the selected layer
  is CI-runnable (`.agents/env/README.md`) AND this repo's `ci.yml` carries the
  job. Read the run; otherwise run it.
- The consumer's own suites: a sync can narrow an enum or tighten a guard
  that consumer files then fail.
- `./joharness.sh finish` — a sync branch carries no workstream file by design
  (`handover.md`, "When NOT to write one"). Under local mode with no
  `local-check` it is red (§ Local checks), and committing one onto the
  bot-owned sync branch is wiped by the next run: land `local-check` in its
  own pull request first, then re-run the sync.

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

`upgrade` refuses on a branch carrying a workstream file (the claim that a
session holds product work, `.agents/harness/AGENTS.md`, "Decide alone",
"Consumer repo:"); a sync branch carries none. A genuine mid-plan sync
overrides with `JOHARNESS_UPGRADE_IN_SESSION=1` and says why in the commit.
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

- NO workstream file ([`handover.md`](handover.md), "When NOT
  to write one"); the commit message carries the source.
- `JOHARNESS_SYNC_ROOT` is a selftest hook, not a way around the refusal
  that stops a consumer syncing out.
- [By hand](#update-by-hand) instead: clone canonical OUTSIDE the consumer
  tree (or `git add -A` swallows it), never `--depth` (a shallow clone reads
  synced files as `AHEAD` forever), on Windows with
  `git clone -c core.autocrlf=false -c core.eol=lf` (the engine compares
  working-tree bytes; `core.autocrlf=true` ships CRLF into the consumer). `upgrade` gets all three right.
- The synced `.gitattributes` pins `.agents/**`, `.claude/commands/**`,
  `.claude/skills/**` to LF, consumer-own files inside included: keep
  native-eol files (a `.bat`/`.cmd` breaks under cmd.exe) outside, or add a
  later-wins pattern below the pinned block (marks `.gitattributes` AHEAD; pin
  changes stop arriving).

## Layers

One layer per consumer: the one its own `joharness.conf` names, plus
`.agents/env/README.md`. Every other layer stays in canonical.

Switch layer:

```bash
./joharness.sh env <name>      # in the consumer; warns the layer is not here yet
```

Then sync (any route above). Unselected layers are reported; removals never
travel, the delete is a human's (`git rm -r .agents/env/<name>`). A layer the
consumer wrote itself is reported and left alone.

## Exit codes

| Code | Means |
| --- | --- |
| 0 | Synced clean. |
| 1 | Refused before any write — consumer untouched. Missing summary line instead = a mid-write tool failure, writes may have landed. |
| 2 | Some consumer copies `AHEAD`. Every other update applied, nothing clobbered. |
| 3 | Listed path missing from canonical. Sync ran; canonical's `FILES`/`DIRS` list or tree is wrong. |

## Ahead

`AHEAD` = consumer content matches no historical canonical blob of that
path: a local edit, or a stale canonical checkout (fetch settles it). The
sync never overwrites it; re-running changes nothing. Fix = the direction rule: land the change in
joharness `main`, then sync again.

## What syncs

One sentence: `.agents/` + `.claude/` + the root instruction files +
`joharness.sh` = harness, `docs/` = the consumer's. Exact list: `FILES`,
`DIRS` in `.agents/scripts/sync-to-consumer.sh`. Root `AGENTS.md` is spliced:
canonical above the `# Part 2 — project` marker, consumer's own below. A file
canonical deleted stays, reported `consumer-only`.

Harness-owned, synced joharness to consumer only; consumer-born fixes land
in joharness first (`product.md`, Reconciliation). Consumer-own, never
synced: `README.md`, `joharness.conf` (each repo picks its environment),
`.gitignore`, `.github/workflows/ci.yml` (consumer CI wiring; harness checks
stay reachable as `./joharness.sh ci`), `.github/workflows/update.yml` (the
consumer's sync cadence and canonical), and ALL of `docs/`: the work dirs
`docs/handover/`, `docs/plans/`, `docs/product/` hold only that repo's files.
