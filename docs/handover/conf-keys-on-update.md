---
workstream: conf-keys-on-update
status: in-progress
branch: claude/drain-session-access-r80jpt
pr: none
plan: conf-keys-on-update
issue: none
session: https://claude.ai/code/session_01HkdcTFBBEsYFS3MKbxjZ3R
agent: sonnet
updated: 2026-09-04
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

First contact asks about every switch; update asks about nothing. A child
bootstrapped before a key existed never learns of it, and `JOHARNESS_MODE`
landed this week, so every child older than that is in that position now.

## Decisions

- **One declaration, sourced by both scripts.** The list already exists twice
  in the bootstrap alone (the interview and the seed heredoc) and a third copy
  in the sync would be the drift this repo keeps paying for. A selftest case
  reds if the seeded conf and the declaration name different keys.
- **`.agents/scripts` is canonical-only**, proven by `CANONICAL_ONLY_DIRS` in
  the sync engine. So the declaration reaches every consumer's update by being
  in canonical, and nothing new ships.
- **Report always, ask only with a terminal, write only what was answered.**
  `update.yml` runs on a cron with nobody to ask, and it already carries the
  sync report into its pull request body, so the report is the channel that
  works everywhere and the ask is a bonus for a human running the sync.
- **Append, never overwrite.** The conf is consumer-own. A key the consumer
  already holds is not re-asked and not touched.

## Rejected

- **Inferring "do not ask" from stdin in the engine.** The bootstrap closes
  stdin when it calls the engine, which would have silenced the ask, but the
  reason to stay quiet is that somebody else owns these answers on this run —
  not a thing a terminal check can see. An explicit variable says it.
- **Fixing the engine's layer lookup while here.** A directory at the conf
  path fails `sed` in `layer_of_consumer` long before this stage runs (review
  r8). Real, older than this change, and a fix means deciding which layer a
  broken conf selects, which is not a question about update-time settings.
  The case asserts the behaviour as it stands so it changes when somebody
  does fix it.

## Review

Sonnet depth: `/code-review` (high) on the full diff plus the harness verifier
reading it cold. Eight findings, three of them serious, and the readers
overlapped on none of them.

- r1: (code-review) **The bootstrap let the engine re-ask everything.** It
  runs the sync before seeding the conf and without closing stdin, so the new
  stage put all five questions again seconds after the interview — and an
  answer there CREATED the conf, which made `seed` decline it as the
  consumer's own, so the seeded conf never landed at all. A consumer came out
  with no `JOHARNESS_ENV` line. Reproduced under a pty. (fixed: the bootstrap
  passes `JOHARNESS_SYNC_CONF_KEYS=skip` and closes stdin, and a pty case
  drives a full bootstrap answering `y` to everything and requires the seeded
  conf to land)
- r2: (verifier) **The append wrote through a symlinked conf** to whatever it
  pointed at, outside the consumer tree, with no guard — while every other
  write in that engine goes through its staged `place` helper. Reproduced
  against a symlink aimed outside `DEST`. The same shape once aimed a purge
  outside the target in this file. (fixed: a path that is not a regular file
  is named and skipped, never followed; a case aims a symlink outside the tree
  and requires the target untouched)
- r3: (verifier) **A conf that is a directory** reached `grep` five times as a
  readable thing, folding "Is a directory" into the report a consumer reads,
  then died on the append under `set -e` rather than through `die`. (fixed in
  this stage: the key reader requires a regular file. The engine still stops
  earlier on the same path for its own reasons — see Rejected)
- r4: (verifier) **Both scripts hard-sourced the new declaration** before any
  of their own checks, so an absent file aborted the whole tool on a bare
  `no such file` naming a line number. (fixed: a named refusal saying what the
  file is for, and a case that copies the engine somewhere without it)
- r5: (verifier) **The dry-run check sat above the terminal check**, so a
  headless dry run promised "would ask" where the real run in that context
  asks nothing — the same defect, in the opposite file, that the bootstrap's
  interview already carries a comment about. (fixed: terminal first, the
  headless case asserts the sentence the real run prints, and a pty dry run
  covers the other half)
- r6: (code-review) **The question went to stderr while its context went to
  stdout**, so a sync with stdout redirected showed a bare prompt with no
  question and no confirmation. (fixed: the report stays on stdout where the
  pull request body captures it, and the whole conversation moved to stderr)
- r7: (code-review) The doc claimed `update.yml`'s pull request body is how a
  cron-updated repo hears about this. It is not, in the case that matters: a
  sync changing no files opens no pull request, and that is exactly the steady
  state this stage targets. (fixed: the doc says which case gets a pull
  request and which leaves the report in the Actions log)
- r8: (verifier) A meaning containing a `|` would be silently truncated at it
  by `cut -f3`. Latent, since no row has one. (fixed: `-f3-`, so a row can say
  `on | off` without losing half of it)

The verifier also cleared, by reproduction, the things most likely to be
wrong here and worth not re-deriving: the prefix collision between
`JOHARNESS_ENV` and `JOHARNESS_ENV_SETUP` in both the row lookup and the conf
match; a commented-out key reading as unanswered; CRLF; a conf with no
trailing newline, which the append supplies; and every other `while read` loop
in both scripts, none of which nests an interactive read the way the one bug
already found did.

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — report stages live near the end.
- `.agents/scripts/bootstrap-consumer.sh` — the interview and the seed.
