# History: consumer repos

Why behind rules in [`../consumer-repos.md`](../consumer-repos.md):
measurements, incidents, rejected alternatives. Append-only. Each heading
names the rule and the date its text entered the document (`git log -S`).
Moved here 2026-10-14; `git log -p` of both files recovers every sentence.

## Settings report, 2026-09-04

Sync with the harness already current, report only in the Actions log: that
case is the steady state this stage is aimed at, so a repo
waiting to be told in a pull request will wait a long time.

## Name no consumer, 2026-09-16

`.agents/docs/`, `.claude/commands/`, `joharness.sh`
and `.agents/harness/` all ship — the last minus its `selftest/` tree and
`selftest.sh`, which are canonical-only — so a repository named in any of them
rides into every consumer, and one operator's internal development becomes
part of the harness every other operator reads.

Canonical-only files too: they are read by the same people, and a rule
with a carve-out is one nobody remembers correctly.

"Measured 2026-09-06 in a consumer at `afdd11d`" is
re-countable by whoever holds that repo and says nothing to anybody else,
which is the correct amount.

Plan names and item names: both say what that repo is building, which is the
internal work this section exists to keep out of every other operator's copy.

Not gated: a list of names
to match would enumerate an operator's repositories, which is their call.

## Reconfigure, 2026-09-05

`--reconfigure` runs no sync, seeding or purge. That is why it is allowed where a
re-bootstrap is refused — the refusal exists to keep whole-clone mode's purge
away from a consumer's live plans and handover, and this run has no purge.

## Dispatch from a session, 2026-08-28

Proven on canonical
2026-08-28: HTTP 204, one run, green in 7s, the canonical guard matching and
the three sync steps skipped.

## A red base branch, 2026-10-10

That narrow run (failing tests on two commits) is
what full baseline worktree per manager was paying for.

Why no harness record of red checks: a reading keyed to a commit still moves
with the environment (runner, registry, clock), and a file of red checks is a
written number and a shared registry every writer would collide on.

## Bot-owned sync branch, 2026-08-25

`joharness-update` is rebuilt every run. Merging the
default branch into it by hand works and fights the design — it survives
only until the Monday cron, and a sync pull request left open over a weekend
loses the merge silently.

## Consumer suites after a sync, 2026-08-25

One sync narrowed the handover `status` vocabulary and every in-flight
branch carrying the old value went red on `graph lint`.

## Migration, 2026-08-23

Nothing reads the old tree afterwards — the entrypoint, the hook
wiring in `.claude/settings.json` and the root `AGENTS.md` import all sync
forward to `.agents/` — so it is dead weight, not a second harness.
