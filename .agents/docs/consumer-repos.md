# Consumer repos

Consumer repo = child repo = any repo running a copy of this harness.
joharness is canonical, consumers receive. Everything about creating and
updating one starts here.

Direction rule (doctrine + why:
[`product/README.md`](product/README.md) Reconciliation): a fix born
ANYWHERE lands in joharness `main` first, then syncs out. Never
consumer-to-consumer, never consumer-only.

Context rule (ratified 2026-08-25): in a CONSUMER, harness upkeep never
runs inside a session doing product work. A session's context belongs to
the plan it claimed. Syncing the harness is upkeep of the tool, not the
work the tool exists for, and a sync diff is large — the harness is
thousands of lines of shell and docs — so reading one costs the claimed
work exactly the context it needed.

Off-session first, cheapest first: `update.yml` runs the sync in the
consumer's own CI and opens a pull request, so no session reads the diff at
all. A conflicted sync that CI cannot finish gets a session of its own, not
the one mid-plan. A session holding product work reviews the resulting pull
request and nothing more — reviewing is the part that needs judgement and
does not delegate.

In CANONICAL (`JOHARNESS_CANONICAL=1` in `joharness.conf`) this rule does
not apply and cannot: the harness IS the product here, `upgrade` refuses to
run, and the sync goes outward. A canonical session working on the harness
is doing the work, not diluting it.

## Pick route

Routes below in preference order for a consumer. Reach past a row only when
the rows above it cannot answer.

| Situation | Route |
| --- | --- |
| Repo has no harness yet | [New consumer](#new-consumer) |
| Routine update, `update.yml` present | [Consumer CI](#update-consumer-ci) — no checkout, no session context |
| CI sync failed, or none seeded | [Upgrade](#update-upgrade-from-the-consumer) — one command, in a session of its own |
| Canonical checkout in reach | [By hand](#update-by-hand) |
| Agent session sits in the consumer | [Agent](#update-agent-in-the-consumer) |
| Sync reported `AHEAD` | [Ahead](#ahead) — do not overwrite |

A pull request `update.yml` opens carries no CI runs unless the consumer
holds a `JOHARNESS_UPDATE_TOKEN` secret — GitHub suppresses
workflow-on-workflow events, and the workflow's own comment says so. An
update pull request with no checks on it is not a green one; check before
trusting the route.

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

Never bootstrap onto a repo already running the harness — script refuses,
because whole-clone mode's purge eats live `docs/plans|product|handover`.
Never hand-copy a raw joharness clone either: it carries joharness's queue
and marker, so the child's sessions work joharness's workstream.

## What a consumer carries

The harness a consumer receives is the part it runs:

| Ships | Why |
| --- | --- |
| `joharness.sh`, `.agents/harness/*.sh` hooks | every session runs them |
| `.agents/harness/AGENTS.md`, `.agents/docs/` | the protocol itself |
| `.agents/env/README.md` + the selected layer | [Layers](#layers) |
| `.claude/` settings, commands, skills | Claude Code reads them from the tree |
| `CLAUDE.md`, `AGENTS.md`, `.gitattributes` | loaded every session |

Canonical-only, never shipped:

| Stays behind | Why |
| --- | --- |
| `.agents/scripts/` | both tools refuse to run outside canonical |
| `.agents/harness/selftest.sh` | tests harness code a consumer does not edit |

That is 132K of the 320K a consumer used to carry. `ci` in a consumer says
`not here (canonical-only)` for the selftest and runs the rest.

A consumer that predates this rule still carries them; every sync reports
them, removals never travel, so the delete is a human's:
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

## Update: consumer CI

`.github/workflows/update.yml`, seeded at bootstrap. Runs the same sync
weekly (Monday 06:00 UTC) and on `workflow_dispatch`, force-pushes branch
`joharness-update`, opens or refreshes one pull request carrying the sync
report. Update now = run that workflow from the consumer's Actions tab.

Consumer-own file, never synced: a fork's own `CANONICAL_REPO` or another
cadence stays put.

Set repository secret `JOHARNESS_UPDATE_TOKEN` (PAT: contents +
pull-requests write on the consumer, read on canonical) when the canonical
is private, when the update pull request must run `ci`, or when the org
disables Actions creating pull requests. Without it the run uses
`GITHUB_TOKEN` and hits all three limits.

## Update: by hand

From a clean canonical checkout:

```bash
.agents/scripts/sync-to-consumer.sh --dry-run <dir>
.agents/scripts/sync-to-consumer.sh <dir>
```

Then commit in the consumer. Uncommitted changes under synced paths in
canonical abort the run — commit there first.

## Update: agent in the consumer

Fallback, not the normal route. This is the one that spends a session's
context on upkeep, so it is for what CI cannot finish: a conflicted sync,
no `update.yml` seeded, or no network from the runner. Routine updates go
to [Consumer CI](#update-consumer-ci).

`upgrade` refuses to run when the branch carries a workstream file, because
that file IS the claim that a session holds product work
(`.agents/harness/AGENTS.md`, Harness upkeep). The steps below start by
cutting a sync branch, which carries none by protocol, so they pass. A
genuine mid-plan sync overrides with `JOHARNESS_UPGRADE_IN_SESSION=1` and
says why in the commit — deliberate and visible, never silent.

`./joharness.sh upgrade` does all of it — see
[Upgrade](#update-upgrade-from-the-consumer). A session still owes the rest
of the ritual around it:

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
- `JOHARNESS_SYNC_ROOT` is a selftest hook. Not a way around the refusal
  that stops a consumer syncing out.
- Doing it by hand instead (a canonical checkout already on disk):
  [by hand](#update-by-hand). Clone it OUTSIDE the consumer tree, or
  `git add -A` swallows it, and never with `--depth` — stale-vs-`AHEAD` is
  decided by blob identity against canonical history, and a shallow clone
  reads honestly-synced files as `AHEAD` forever. `upgrade` gets both right.

## Layers

One layer per consumer: the one its own `joharness.conf` names, plus
`.agents/env/README.md`. Every other layer stays in canonical — a repo gains
nothing from scripts it never runs, and its own `ci` would shellcheck them
every push.

Switch layer:

```bash
./joharness.sh env <name>      # in the consumer; warns the layer is not here yet
```

Then sync (any route above). The selection is what the sync reads, so writing
it is how a repo asks for a different layer.

A consumer that predates this rule carries layers it does not select. Every
sync reports them; removals never travel, so the delete is a human's:

```bash
git rm -r .agents/env/<name>
```

Only layers whose content came from canonical are named with that advice. A
layer the consumer wrote itself is reported and left alone — the sync never
points a delete at consumer work.

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

## Migration: pre-`.agents` consumers

Both layers moved from root `harness/` and `env/` to `.agents/harness/` and
`.agents/env/` — one dotted root a tool can detect. A consumer synced across
that move receives the new tree and keeps the old one: removals do not
travel. Nothing reads the old tree afterwards — the entrypoint, the hook
wiring in `.claude/settings.json` and the root `AGENTS.md` import all sync
forward to `.agents/` — so it is dead weight, not a second harness.

Remove it once, after the first sync that brings `.agents/`:

```bash
git rm -r harness env
```

The sync warns on every run until that lands. Keep anything of the repo's
own that lived in `env/<name>/` — a consumer's own layer moves to
`.agents/env/<name>/` by hand, it is not canonical's to carry.

Second wave: the protocol docs and sync tools moved too — `docs/` and
`scripts/` in a consumer are now entirely its own. The stale copies are
single files inside dirs that hold live work, so remove exactly the files
the sync's warning names — NEVER `git rm -r` on `docs/`, that eats the
repo's own plans and handover:

```bash
git rm docs/caveman.md docs/graph.md docs/agent-selection.md \
  docs/consumer-repos.md docs/handover/README.md docs/handover/TEMPLATE.md \
  docs/plans/README.md docs/plans/TEMPLATE.md docs/product/README.md \
  docs/product/TEMPLATE.md scripts/sync-to-consumer.sh \
  scripts/bootstrap-consumer.sh
```

(Only the ones actually present — the warning's own remedy line lists
exactly those.)

One more consumer-own edit: a pre-move `update.yml` calls canonical's
`scripts/sync-to-consumer.sh`, which no longer exists — the weekly run
goes red with file-not-found until the workflow's `run sync` step points
at `.agents/scripts/sync-to-consumer.sh`. Newly seeded `update.yml`
probes both spellings.

## What syncs

Harness-owned vs consumer-own: table in
[`.agents/harness/README.md`](../harness/README.md). Exact list: `FILES` and
`DIRS` in `.agents/scripts/sync-to-consumer.sh`. Root `AGENTS.md` is spliced, not
copied — canonical above the `# Part 2 — project` marker, consumer's own
below. Removals do not travel: a file canonical deleted stays, reported
`consumer-only`.
