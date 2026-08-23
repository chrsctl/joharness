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
scripts/bootstrap-consumer.sh <dir>        # --dry-run first, it reports
```

Places the harness set, seeds consumer-own stubs (`joharness.conf`,
`ci.yml`, `update.yml`, `README.md`, AGENTS.md Part 2), strips joharness's
live workstream files, plans and canonical marker. Script prints the
remaining steps; follow them.

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
scripts/sync-to-consumer.sh --dry-run <dir>
scripts/sync-to-consumer.sh <dir>
```

Then commit in the consumer. Uncommitted changes under synced paths in
canonical abort the run — commit there first.

## Update: agent in the consumer

The consumer's own copy of the script refuses to run (no
`JOHARNESS_CANONICAL=1` in its conf). Clone canonical, run ITS copy:

```bash
git fetch origin main && git checkout -b claude/harness-sync origin/main
git clone https://github.com/chrsctl/joharness.git /tmp/canonical
/tmp/canonical/scripts/sync-to-consumer.sh --dry-run .
/tmp/canonical/scripts/sync-to-consumer.sh .
./joharness.sh ci
git add -A && git commit -m "Sync harness from chrsctl/joharness"
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

## What syncs

Harness-owned vs consumer-own: table in
[`.agents/harness/README.md`](../.agents/harness/README.md). Exact list: `FILES` and
`DIRS` in `scripts/sync-to-consumer.sh`. Root `AGENTS.md` is spliced, not
copied — canonical above the `# Part 2 — project` marker, consumer's own
below. Removals do not travel: a file canonical deleted stays, reported
`consumer-only`.
