---
workstream: template-child-repos
status: in-progress
branch: claude/template-child-repos-workstream-15leyr
pr: none
plan: none
session: https://claude.ai/code/session_01BrwFdUJkZs6HCKTu2yL544
agent: opus
updated: 2026-08-22
next: Open PR to main; PR deletes this file on merge
---

## Goal

Child repo made from joharness template must start focused on ITS
workstream, not joharness's. Today a whole-clone child inherits: live
`docs/plans/*.md` queue (hook suggests joharness work to child sessions),
`JOHARNESS_CANONICAL=1` (child passes as canonical, could sync out —
forbidden), joharness README, joharness Part 2 of AGENTS.md. Clean path
(sync into empty dir) leaks Part 2 too and seeds no conf, no ci.yml.
Bootstrap story today = "clone whole, hand-delete things" (joharness.conf
comment). Human ask: proper move, one command.

## Decisions

- New `scripts/bootstrap-consumer.sh`, not a flag on sync-to-consumer.sh:
  sync is one-way steady-state with heavy guards; bootstrap is one-time.
  Bootstrap CALLS sync for the harness-owned set, then seeds consumer-own
  files sync never touches.
- Three target states, detected: (1) fresh dir (no joharness.sh) = sync
  in harness set, seed conf (no canonical line), ci.yml, Part 2 stub;
  (2) whole-clone of joharness (conf carries JOHARNESS_CANONICAL=1) =
  strip marker, purge live docs/plans|product|handover *.md (keep
  README/TEMPLATE), reset Part 2 to stub, warn on README; (3) already a
  consumer (harness present, no marker) = refuse, point at sync.
- Part 2 stub written by bootstrap, below marker — head stays canonical
  history so later sync splices keep working.
- Established consumer safety: refusal case (3) is the guard against
  deleting a real consumer's live plans.

- Bootstrap script listed in sync FILES: whole-clone consumers carry it,
  so it must stay reconciled like sync-to-consumer.sh itself.
- Review (high) found 4 correctness bugs, all fixed + regression-tested:
  symlink spelling bypassed self-target guard (whole-clone mode then
  converts the CANONICAL — pwd -P both sides now); whole-clone wrote
  before marker check could die (half-converted clone no tool finishes —
  structural refusal now before first write); missing clone AGENTS.md
  claimed rewrite on exit 0; fresh mode flattened a pre-existing
  consumer's own Part 2 to the stub.
- `.agents/` layout researched on human ask, rejected for now: two-plus
  competing draft specs, no native tool discovery (Claude Code reads
  .claude/ only), sync AHEAD detection is per-path so a move orphans
  every consumer copy. Revisit as own requirement if root clutter in
  children matters; honest name then is `.joharness/`, not `.agents/`.

## Rejected

- Extending sync-to-consumer.sh with --bootstrap: mixes one-time
  destructive ops (purge plans) into a script whose contract is
  never-clobber; every guard would need a mode check.

## Blockers

None.

## Where to look

- `scripts/sync-to-consumer.sh:sync_agents_md` — bootstrap places
  canonical AGENTS.md whole incl. joharness Part 2; the leak.
- `scripts/sync-to-consumer.sh:FILES/DIRS` — harness-owned set; conf,
  README, ci.yml, live docs deliberately absent (consumer-own).
- `joharness.conf` — canonical marker + "DELETE this line" comment =
  manual bootstrap it replaces.
- `harness/selftest.sh:556` — sync test section; bootstrap cases go
  after, same fixture style.
