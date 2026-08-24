---
workstream: one-layer-sync
status: in-progress
branch: claude/celluloid3-update-occ76a
pr: 43
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

(r1 and r2 were caught by the gates while building, not by the review
round — recorded here so the ledger is complete, not to claim a process.)

- r1: `bootstrap --env` validated the layer BEFORE the canonical-marker
  guard, so a consumer copy of the script was refused for naming a layer
  rather than for being a consumer copy — the doctrine refusal is the one
  that must speak. Guard order swapped; the selftest that caught it was
  already there. (fixed)
- r2: a header comment line began with the word `shellcheck`, which
  shellcheck reads as a directive — `ci` went red on SC1072. Reworded.
  (fixed)
- r3: `printf '  layer   %s%s' "$LAYER" "$([ ... ] || printf ...)"` — a
  command substitution that exits non-zero inside a command's ARGUMENTS
  does not trip `set -e` (only assignments take its status). Checked
  against bash and exercised against celluloid3. No change.
- r4: CRLF conf. `dest_conf_get` captures `[^#[:space:]]*`, and `\r` is in
  `[:space:]`, so a Windows checkout does not yield a layer name with a
  trailing CR that would then fail `valid_layer`. No change.
- r5: the report runs on `--dry-run` too, unlike the legacy-layout warning
  which is gated on the new tree standing. That gate exists because the
  legacy advice could name the LIVE harness mid-bootstrap; this advice
  names a layer the consumer does not select, which is safe to say at any
  point. No change.
- r6: existing consumers keep their unused layers until a human runs the
  `git rm -r`, so their `ci` keeps linting those scripts in the meantime.
  Accepted, not fixed: deleting consumer files would be the first
  destructive act the engine performs, against the rule the design rests
  on. celluloid3's cleanup rides in its own pull request.

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — `dest_conf_get`/`LAYER`, the
  conditional DIRS entry, `report_unused_layers`.
- `.agents/scripts/bootstrap-consumer.sh` — `--env` parsing, whole-clone
  conf rewrite.
- `joharness.sh:cmd_env` — canonical dies, consumer warns.
