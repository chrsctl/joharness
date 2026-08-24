---
workstream: one-layer-sync
status: in-progress
branch: claude/celluloid3-update-occ76a
pr: none
plan: none
session: https://claude.ai/code/session_01JoK1BRUuDsQ2VR9zbJMKHD
agent: opus
updated: 2026-08-24
next: Add selftests for one-layer sync, bootstrap --env and the consumer-side env selection, then run ci
---

## Goal

Human: "Johannes always copies all envs which is unnecessary." The sync
shipped `.agents/env/` whole, so celluloid3 received docker (28K) and k8s
(56K) it will never run, and its own `ci` shellchecks five scripts
belonging to those layers on every push. One layer ships now — the one the
consumer's own `joharness.conf` names.

## Decisions

- The consumer's `joharness.conf` is the single source of truth for which
  layer ships. Any second answer (a flag, a list in the engine) would let
  what ships and what runs disagree.
- `JOHARNESS_SYNC_ENV` exists for exactly one caller: `bootstrap-consumer.sh
  --env`, whose sync runs before the conf it seeds exists.
- `.agents/env/README.md` ships as a FILES entry. It is the layer contract,
  belongs to no layer, and a consumer without it cannot read what a layer is.
- Unselected layers are reported, never deleted — removals do not travel
  (engine header), and vouching is per layer on its `AGENTS.md`, so a
  consumer's own layer is named but never has `git rm -r` pointed at it.
- `joharness.sh env <name>` no longer dies on an absent layer in a
  consumer: the sync reads that file to decide what to ship, so refusing to
  write it would leave no way to ask for a different layer. It still dies in
  canonical, where every layer exists and an unknown name is a typo.

## Rejected

- Deleting unselected layers during the sync. It would be the first
  destructive act the engine performs on consumer files, against the
  removals-do-not-travel rule the whole design rests on.
- Keeping `.agents/env` in DIRS and filtering inside `sync_dir`. The dirty
  check, preflight, the C-quote guard and `reap_scan` all read DIRS; a
  filter inside one function would leave the other four believing all
  layers travel.
- Shipping `none` alongside the selected layer as a fallback. `none` is an
  ordinary layer; a repo that selects `docker` gains nothing from carrying
  the empty one, and the entrypoint already falls back to running nothing.

## Review

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — `dest_conf_get`/`LAYER`, the
  conditional DIRS entry, `report_unused_layers`.
- `.agents/scripts/bootstrap-consumer.sh` — `--env` parsing, whole-clone
  conf rewrite.
- `joharness.sh:cmd_env` — canonical dies, consumer warns.
