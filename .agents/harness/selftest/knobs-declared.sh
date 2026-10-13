# knobs-declared — one selftest topic, sourced by ../selftest.sh in the order
# that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# joharness.sh declares every key it reads once, in KNOBS, and `conf` prints
# them with their live values. Three other places say something about the same
# keys: conf-keys.sh (what a consumer's conf answers), the table in
# orchestrated.md (the dispatch numbers) and the script's own reads. Nothing
# failed when a key was added to one and not another; this topic does. It
# reds on a read with no row, a default that differs from conf-keys.sh, a
# dispatch key with no table row and a conf key conf-keys.sh lacks. A key
# present in both declarations is not a defect: ten are.
#
# shellcheck shell=bash disable=SC2154

step "knobs-declared"

# kd_problems <script> <table-doc> <conf-keys>: one line per disagreement.
kd_problems() {
  local script="$1" doc="$2" keys="$3" rows reads k d scope _ ck
  rows="$(awk '/^# KNOBS-BEGIN/{f=1;next} /^# KNOBS-END/{f=0} f' "$script" |
    sed "1s/^KNOBS='//; \$s/'\$//")"
  # Outside the table (which names every key by being the table): every name
  # the script mentions, and every first argument of a num_knob call.
  reads="$(awk '/^# KNOBS-BEGIN/{f=1;next} /^# KNOBS-END/{f=0;next} !f' "$script" |
    grep -oE 'JOHARNESS_[A-Z0-9_]+|num_knob [A-Z][A-Z0-9_]+' |
    sed 's/^num_knob //' | sort -u)"
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    printf '%s\n' "$rows" | grep -q "^${k}|" || printf 'no KNOBS row: %s\n' "$k"
  done <<<"$reads"
  ck="$(bash -c ". '${keys}'; conf_keys_rows")"
  while IFS='|' read -r k d scope _; do
    [ -n "$k" ] || continue
    if printf '%s\n' "$ck" | grep -q "^${k}|"; then
      [ "$(printf '%s\n' "$ck" | grep "^${k}|" | cut -d'|' -f2)" = "$d" ] ||
        printf 'default differs from conf-keys.sh: %s\n' "$k"
    elif [ "$scope" = conf ] || [ "$scope" = base-conf ]; then
      printf 'conf-scoped key absent from conf-keys.sh: %s\n' "$k"
    fi
    if [ "$scope" = dispatch ]; then
      grep -qF "| \`${k}\` |" "$doc" || printf 'dispatch key with no table row: %s\n' "$k"
    fi
  done <<<"$rows"
}

kd_script="${ROOT}/joharness.sh"
kd_doc="${ROOT}/.agents/docs/orchestrated.md"
kd_keys="${ROOT}/.agents/scripts/conf-keys.sh"

if [ -r "$kd_keys" ] && [ -r "$kd_doc" ]; then
  out="$(kd_problems "$kd_script" "$kd_doc" "$kd_keys")"
  if [ -z "$out" ]; then
    pass "KNOBS, conf-keys.sh and the orchestrated.md table agree"
  else
    fail "KNOBS, conf-keys.sh and the orchestrated.md table agree"
    printf '%s\n' "$(indent "$out")"
  fi

  # Each check must be able to fail: a mutated copy, one defect at a time.
  kdw="${TMP}/kdwork"
  mkdir -p "$kdw"
  cp "$kd_script" "${kdw}/a.sh"
  printf ': "${JOHARNESS_BRAND_NEW:-}"\n' >>"${kdw}/a.sh"
  expect "a name the script reads with no row reds" \
    "no KNOBS row: JOHARNESS_BRAND_NEW" "$(kd_problems "${kdw}/a.sh" "$kd_doc" "$kd_keys")"
  cp "$kd_script" "${kdw}/b.sh"
  printf ': "$(num_knob JOHARNESS_VIA_NUM_KNOB)"\n' >>"${kdw}/b.sh"
  expect "a num_knob first argument with no row reds" \
    "no KNOBS row: JOHARNESS_VIA_NUM_KNOB" "$(kd_problems "${kdw}/b.sh" "$kd_doc" "$kd_keys")"
  sed 's/^JOHARNESS_CURATE_PLANS|10|/JOHARNESS_CURATE_PLANS|11|/' "$kd_script" >"${kdw}/c.sh"
  expect "a default that differs from conf-keys.sh reds" \
    "default differs from conf-keys.sh: JOHARNESS_CURATE_PLANS" \
    "$(kd_problems "${kdw}/c.sh" "$kd_doc" "$kd_keys")"
  grep -vF '| `JOHARNESS_CLERK_BATCH` |' "$kd_doc" >"${kdw}/d.md"
  expect "a dispatch key with no table row reds" \
    "dispatch key with no table row: JOHARNESS_CLERK_BATCH" \
    "$(kd_problems "$kd_script" "${kdw}/d.md" "$kd_keys")"
  sed 's/^HANDOVER_STALE_SECONDS|/JOHARNESS_ONLY_HERE|1|conf|x\nHANDOVER_STALE_SECONDS|/' \
    "$kd_script" >"${kdw}/e.sh"
  expect "a conf-scoped key absent from conf-keys.sh reds" \
    "conf-scoped key absent from conf-keys.sh: JOHARNESS_ONLY_HERE" \
    "$(kd_problems "${kdw}/e.sh" "$kd_doc" "$kd_keys")"
else
  skip "KNOBS against conf-keys.sh and the table" "no .agents/scripts/conf-keys.sh here (canonical-only)"
fi

# --- `conf` prints what the readers use, and where it came from --------------
kdfix="${TMP}/kdfix"
git init -q "$kdfix"
cp "$kd_script" "${kdfix}/joharness.sh"
printf 'JOHARNESS_MAX_MANAGERS=3\nJOHARNESS_SCOUT_REVIEWER=carol\nJOHARNESS_CURATE_PLANS=\n' >"${kdfix}/joharness.conf"
commit_all "$kdfix" "base"
git -C "$kdfix" update-ref refs/remotes/origin/main HEAD
printf 'JOHARNESS_SCOUT_REVIEWER=alice\nJOHARNESS_MAX_MANAGERS=3\nJOHARNESS_CURATE_PLANS=\n' >"${kdfix}/joharness.conf"
kdconf() { ( cd "$kdfix" && JOHARNESS_CONF="${kdfix}/joharness.conf" env "$@" ./joharness.sh conf 2>&1 ); }

out="$(kdconf)"
rows="$(awk '/^# KNOBS-BEGIN/{f=1;next} /^# KNOBS-END/{f=0} f' "$kd_script" |
  sed "1s/^KNOBS='//; \$s/'\$//" | wc -l | tr -d ' ')"
expect "one line per KNOBS row" "${rows}" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
expect "a conf value reads conf" "JOHARNESS_MAX_MANAGERS = 3 (conf)" "$out"
expect "a default reads default" "JOHARNESS_STALL_MINUTES = 45 (default)" "$out"
expect "the computed default is the value, twice the threshold" \
  "JOHARNESS_CHURN_LIMIT = 10 (default)" "$out"
expect "a scout key reads the BASE branch's conf, not the checkout's" \
  "JOHARNESS_SCOUT_REVIEWER = carol (base conf)" "$out"
expect "an empty conf line is a skipped layer, not a value" \
  "JOHARNESS_CURATE_PLANS = 10 (default; conf set but empty, ignored)" "$out"
expect "the environment wins" \
  "JOHARNESS_SCOUT_REVIEWER = bob (env)" "$(kdconf JOHARNESS_SCOUT_REVIEWER=bob)"
expect "an empty environment falls through to conf and says so" \
  "JOHARNESS_MAX_MANAGERS = 3 (conf; env set but empty, ignored)" \
  "$(kdconf JOHARNESS_MAX_MANAGERS=)"
expect "a non-number in the environment goes to the default, conf unread" \
  "JOHARNESS_MAX_MANAGERS = 4 (default; env set but not a number, ignored, conf not consulted)" \
  "$(kdconf JOHARNESS_MAX_MANAGERS=x)"
