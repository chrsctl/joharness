#!/usr/bin/env bash
#
# conf-keys.sh - the settings a consumer repo runs under, declared once.
#
# Sourced, never executed. Two callers read it and they are the reason it
# exists: bootstrap-consumer.sh ASKS for these at first contact and seeds
# them, and sync-to-consumer.sh names the ones a consumer's conf does not
# carry at update. Before this file the list lived in the bootstrap twice
# over — once in the interview, once in the seeded heredoc — and a third copy
# in the sync engine is how two readers of one fact start disagreeing. The
# selftest reds if the seeded conf and this declaration name different keys.
#
# `.agents/scripts` is canonical-only (sync-to-consumer.sh:CANONICAL_ONLY_DIRS),
# so this reaches every consumer's update by being in canonical and ships to
# none of them. Nothing here is copied into a child.
#
# A key belongs here when a consumer's joharness.conf is where it is answered
# and the harness reads it. JOHARNESS_CANONICAL does NOT: it marks the
# canonical checkout, the bootstrap strips it, and offering it to a child
# would offer the one line that makes a consumer pass as canonical.
#
# Adding a key: add a row, add it to the bootstrap's seeded heredoc, and the
# selftest that compares the two tells you if you did only one. Every update
# after that names it to every consumer that predates it, which is the whole
# point — JOHARNESS_MODE landed with no way to reach a child bootstrapped the
# week before.
#
# Row format, `|`-separated so a meaning can carry spaces and commas:
#   KEY|default|one-line meaning
# The default is what a fresh child is seeded with, not a value anybody must
# take: every reader of these keys resolves an absent or unrecognised value to
# the safe answer already.

# shellcheck shell=bash

conf_keys_rows() {
  cat <<'ROWS'
JOHARNESS_ENV|none|Directory under .agents/env/ this repo provisions. 'none' = harness only.
JOHARNESS_ENV_SETUP|lazy|lazy = provision on demand; eager = at session start.
JOHARNESS_ENV_MD|lazy|lazy = inject a pointer to the layer's rules; eager = the file whole.
JOHARNESS_REVIEW|off|off = review reports only; on = ci gates the record at the edge.
JOHARNESS_MODE|supervised|supervised = a session asks at the queue edge; unsupervised = it exits instead; orchestrated (beta) = an orchestrator dispatches managers.
ROWS
}

# Just the names, in declaration order.
conf_keys_names() { conf_keys_rows | cut -d'|' -f1; }

# One field of one row. Absent key prints nothing and returns 1, so a caller
# that mistypes a name gets a failure rather than an empty default it would
# then write into somebody's conf.
conf_key_field() {
  local want="$1" field="$2" line
  line="$(conf_keys_rows | grep "^${want}|" || :)"
  [ -n "$line" ] || return 1
  printf '%s' "$line" | cut -d'|' -f"$field"
}
conf_key_default() { conf_key_field "$1" 2; }
# `3-`, not `3`: a meaning is prose and the separator is a character prose
# uses. Taking the rest of the line means a row can say `on | off` without
# the reader silently keeping the half before the pipe.
conf_key_meaning() { conf_key_field "$1" 3-; }

# Whether a conf file already answers a key. Reads it the way
# joharness.sh:conf_get does, so the two never disagree about what a repo
# currently says. A commented-out line is not an answer.
conf_file_has_key() {
  local conf="$1" key="$2"
  # -f, not -r: a directory at this path is readable, and `grep` on one exits
  # 2 with a message the caller folds into "missing" — five times, into a
  # report a consumer reads. A path that is not a regular file answers no key,
  # and the caller is the one that decides what to say about it.
  [ -f "$conf" ] || return 1
  grep -q "^[[:space:]]*${key}[[:space:]]*=" "$conf"
}

# The declared keys a conf does not answer, in declaration order. Prints
# nothing when the conf answers all of them, which is what lets a caller skip
# its whole report stage on the common case.
conf_keys_missing_from() {
  local conf="$1" key
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    conf_file_has_key "$conf" "$key" || printf '%s\n' "$key"
  done <<<"$(conf_keys_names)"
}
