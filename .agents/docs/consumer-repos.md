# Consumer repos

Consumer repo = child repo = any repo running a copy of this harness.
joharness is canonical, consumers receive. Everything about creating and
updating one starts here.

Direction rule (doctrine + why:
[`product/README.md`](product/README.md) Reconciliation): a fix born
ANYWHERE lands in joharness `main` first, then syncs out. Never
consumer-to-consumer, never consumer-only.

## Pick route

| Situation | Route |
| --- | --- |
| Repo has no harness yet | [New consumer](#new-consumer) |
| Consumer has `update.yml` | [Consumer CI](#update-consumer-ci) — no checkout needed |
| Canonical checkout in reach | [By hand](#update-by-hand) |
| Agent session sits in the consumer | [Agent](#update-agent-in-the-consumer) |
| Sync reported `AHEAD` | [Ahead](#ahead) — do not overwrite |

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

The consumer's own copy of the script refuses to run (no
`JOHARNESS_CANONICAL=1` in its conf). Clone canonical, run ITS copy.
Canonical's address = `CANONICAL_REPO` in the consumer's own
`.github/workflows/update.yml` — a fork's consumer names the fork there,
so never spell a literal here:

```bash
git fetch origin main && git checkout -b claude/harness-sync origin/main
canon="$(sed -n 's/^ *CANONICAL_REPO: //p' .github/workflows/update.yml)"
git clone "https://github.com/${canon}.git" /tmp/canonical
/tmp/canonical/.agents/scripts/sync-to-consumer.sh --dry-run .
/tmp/canonical/.agents/scripts/sync-to-consumer.sh .
./joharness.sh ci
git add -A && git commit -m "Sync harness from ${canon}"
git push -u origin HEAD
```

- Full clone, no `--depth`: stale-vs-`AHEAD` is decided by blob identity
  against canonical history, and a shallow clone reads honestly-synced
  files as `AHEAD` forever.
- Clone outside the consumer tree, or `git add -A` swallows it.
- `JOHARNESS_SYNC_ROOT` is a selftest hook. Not a way around the refusal.
- NO workstream file: sync diff is self-describing
  ([`handover/README.md`](handover/README.md), "When NOT to write one").
  Commit message carries the source.

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
