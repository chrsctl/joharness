# num_knob — one selftest topic, sourced by ../selftest.sh in the order that
# file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The one reader every numeric knob goes through, and both ways it was wrong
# were SILENT (issue #260). `08` and `09` pass a digits-only filter and then
# die on bash's octal rule — inside a command substitution, where `set -e`
# is not in force, so the caller is handed the EMPTY string and prints a
# confident wrong line at exit 0. `010` is valid octal and so is eight to the
# arithmetic and ten to whoever wrote it. And there was no upper bound, so
# twenty digits wrapped.
#
# Driven through `dispatch`, because that is the command that PRINTS every
# knob it read — the knob line IS the observable, and a reader that only
# checked exit status would have asserted a value that never moves.
#
# Builds its OWN scratch repo: the slots line counts managers from git, and a
# fixture carrying another topic's branches would make that number a property
# of what ran before it.
#
# shellcheck shell=bash disable=SC2154

step "num_knob"

nkwork="${TMP}/nkwork"
nkorigin="${TMP}/nkorigin.git"
git init -q --bare "$nkorigin"
git init -q "$nkwork"
git -C "$nkwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${nkwork}/docs/plans" "${nkwork}/docs/handover" \
  "${nkwork}/.agents/harness" "${nkwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${nkwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${nkwork}/.agents/harness/"
printf '# none\n' >"${nkwork}/.agents/env/none/AGENTS.md"
nkconf="${nkwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$nkconf"
commit_all "$nkwork" "base"
git -C "$nkwork" remote add origin "$nkorigin"
git -C "$nkwork" push -qu origin main

# DISPATCH_FETCH=0: the fixture's refs are already here, and a fetch against a
# bare origin proves nothing about what a knob reads.
nk() { ( cd "$nkwork" && JOHARNESS_CONF="$nkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 env "$@" ./joharness.sh dispatch 2>&1 ); }
# stdout only, so a case can assert that nothing reached stderr.
nkout() { ( cd "$nkwork" && JOHARNESS_CONF="$nkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 env "$@" ./joharness.sh dispatch 2>/dev/null ); }
# `{ ...; } 2>&1` and not `2>&1 >/dev/null`: same effect, and the second
# spelling is the one shellcheck reads as a mistake (SC2069).
nkerr() { ( cd "$nkwork" && JOHARNESS_CONF="$nkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 env "$@" bash -c '{ ./joharness.sh dispatch >/dev/null; } 2>&1' ); }

# --- a zero-padded value is decimal, and does not kill the command ----------
# `08` is the loud half, and it was loud only on stderr: the command exits 0
# with its whole output printed, so exit status pins nothing here and the
# CONTENT of the line is the assertion.
out="$(nk JOHARNESS_CHURN_THRESHOLD=08)"
# Anchored on the `; ` before it: the unfixed line reads `; 08+ = a warning`,
# and `8+ = a warning` is a SUBSTRING of that, so the obvious needle passes
# on the defect it is named for.
expect "a zero-padded threshold is read as decimal" \
  "); 8+ = a warning on the work line" "$out"
expect "and the limit derived from it is a number, not nothing" \
  "one file rewritten 16+ times" "$out"
refute "with no arithmetic error anywhere in the output" \
  "value too great for base" "$out"
# `expect` is `grep -qF "$2"`, and an EMPTY needle matches every string —
# so asserting emptiness by passing "" is an assertion that cannot fail.
# Turned into a real one: the haystack is a marker when stderr is empty and
# the error text itself when it is not.
nkstderr="$(nkerr JOHARNESS_CHURN_THRESHOLD=08)"
expect "nothing reaches stderr" \
  "STDERR-EMPTY" "$([ -z "$nkstderr" ] && printf 'STDERR-EMPTY' || printf '%s' "$nkstderr")"
# The control, and the reason this case is not about the string `08`: the
# same command with an ordinary value prints the same shape.
out="$(nk JOHARNESS_CHURN_THRESHOLD=5)"
expect "an ordinary threshold is unchanged" \
  "5+ = a warning on the work line" "$out"

# --- the QUIET half: a valid octal is silently the wrong number -------------
# `010` never errored. It read as eight, on a cap, which is the human's money
# changed by a spelling. Both lines asserted: the cap line prints the value
# and the slots line counts against it, and a fix that normalised only what
# is printed would pass on the first alone.
out="$(nkout JOHARNESS_MAX_MANAGERS=010)"
expect "a zero-padded cap is ten, not eight" \
  "cap       : 10 manager(s) at once (JOHARNESS_MAX_MANAGERS)" "$out"
expect "and the slots below it count against ten" \
  "slots     : 10 of 10 free" "$out"
refute "never the octal reading" "of 8 free" "$out"

# --- zero survives, because 0 is a value some knobs act on ------------------
# `000` strips to nothing; the answer is 0, never the default, because 0 is
# what lifts the churn gate and a default here would silently re-arm it.
out="$(nk JOHARNESS_CHURN_LIMIT=000)"
expect "an all-zero value is zero" "one file rewritten 0+ times" "$out"

# --- the ceiling: too many digits falls back, it does not clamp -------------
# A knob has no natural maximum to clamp to, so the answer is the caller's
# own default — the same answer a non-digit already got.
out="$(nk JOHARNESS_MAX_MANAGERS=1234567890)"
expect "a value past the digit ceiling falls back to the default" \
  "cap       : 4 manager(s)" "$out"
# Asserted from BELOW as well: a ceiling checked only from above passes when
# it is set to zero and every knob quietly becomes its default.
out="$(nk JOHARNESS_MAX_MANAGERS=123456789)"
expect "and a value one digit under it is honoured" \
  "cap       : 123456789 manager(s)" "$out"
# The pre-existing filter, kept as a control: the fallback is not new
# behaviour invented for long values, it is the answer a word already got.
out="$(nk JOHARNESS_MAX_MANAGERS=lots)"
expect "a word still falls back, as it always did" \
  "cap       : 4 manager(s)" "$out"

# --- what the ceiling does NOT bound, pinned rather than left to be found ---
# The ceiling bounds what the environment or the conf supplies. A default the
# code computes is the repo's own arithmetic on an already-bounded value —
# `JOHARNESS_CHURN_LIMIT` defaults to twice the threshold — so it passes
# through at ten digits. That is deliberate and inside int64; asserted so it
# is a decision rather than a gap somebody rediscovers.
out="$(nk JOHARNESS_CHURN_THRESHOLD=999999999)"
expect "a computed default is not re-bounded by the ceiling" \
  "one file rewritten 1999999998+ times" "$out"
