---
plan: reconfigure-consumer
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/scripts, .agents/harness/selftest, .agents/docs/consumer-repos.md
---

## Goal

Requester, 2026-09-05: a switch that re-asks every question in an existing
child. Today the five switches a consumer runs under are put once, at first
contact, by `bootstrap-consumer.sh`; that script then REFUSES a target that
already runs the harness, and the steady-state sync only offers to write
defaults for keys a conf is MISSING. So a consumer whose operator wants to
change a decision has no route but hand-editing `joharness.conf` against a
vocabulary documented one hop away — the same gap `capture-intent`'s F12 and
F13 measured for requirement frontmatter, one file over.

## Scope

- `.agents/scripts/bootstrap-consumer.sh` — a `--reconfigure` flag, a third
  `MODE`, and the conf-only run it selects: the existing interview, every
  question, each defaulting to the value in force in the CHILD's conf, then
  `write_decided_keys` and nothing else. No sync, no seed, no purge, so the
  refusal that protects a consumer's live work is not the thing being
  relaxed.
- `.agents/harness/selftest/bootstrap-consumer.sh` — cases: refused without
  the flag (unchanged); accepted with it; every question put; an answer
  written; Enter writing nothing; a pty run; the dry run's preview; and the
  autonomy default, which differs from first contact.
- `.agents/docs/consumer-repos.md` — the route, beside the two it already
  documents.

## Out of scope

- Any change to what the sync engine's conf-keys stage does. It answers a
  different question (a key that is ABSENT) and its `[y/N]`-writes-the-default
  shape is right for that.
- New keys, new questions, or a second copy of the interview. One interview,
  in the script that owns it; `conf-keys.sh` stays the one declaration.
- Re-syncing files. `--reconfigure` writes conf keys and nothing else.

## Acceptance

- `bootstrap-consumer.sh <existing-consumer>` still dies with
  "already runs the harness" and writes nothing.
- `bootstrap-consumer.sh --reconfigure <existing-consumer>` under a pty puts
  all five questions and writes only the answers that changed.
- `--reconfigure` on a directory that is NOT a consumer is refused, named.
- `--dry-run --reconfigure` writes nothing and says what it would ask.
- `./joharness.sh ci` — `ci: pass`.
- SHIPS, because `.agents/docs/consumer-repos.md` does. The script itself is
  canonical-only, so the consumer-side check is the route that document now
  tells a consumer's operator to run, against a real child:
  `.agents/scripts/bootstrap-consumer.sh --reconfigure <consumer-dir>` exits
  0, changes only that child's `joharness.conf`, and leaves every other file
  byte-identical.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh:interview` — the five questions and
  the `_GIVEN` convention a flag sets.
- `:write_decided_keys` — writes only what a flag or the interview decided.
- `:conf_value_of` — reads the value in force from the target's conf.
- the mode-detection block — where the existing-consumer refusal lives.

## Traps

- The autonomy question deliberately does NOT offer the conf's value at first
  contact: a clone carries canonical's mid-run flip. That reasoning does not
  hold for an established child, whose line its own bootstrap wrote — so
  reconfigure reads it and first contact still does not. Say which is which
  at the code.
- `JOHARNESS_MODE` is always written. Under reconfigure that makes Enter a
  silent downgrade unless the default is the child's own value.
- The pty cases hang if a question is added without an answer line
  (PR209 r6). Feed one line per question plus blanks.
