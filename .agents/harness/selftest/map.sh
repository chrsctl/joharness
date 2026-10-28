# joharness.sh map and its ci lint — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone: the runner defines the helpers and the counters.
# shellcheck shell=bash

step "joharness.sh map"

mwork="${TMP}/mapwork"
mkdir -p "${mwork}/.agents/harness" "${mwork}/.agents/env/none" \
  "${mwork}/docs/plans" "${mwork}/docs/handover" "${mwork}/docs/product" \
  "${mwork}/app" "${mwork}/lib" "${mwork}/gen" "${mwork}/.hidden"
cp "${ROOT}/joharness.sh" "${mwork}/joharness.sh"
for _t in plans research product handover; do
  mkdir -p "${mwork}/.agents/docs/${_t}"
  printf '# %s\n' "$_t" >"${mwork}/.agents/docs/${_t}/README.md"
done
printf '#!/usr/bin/env bash\nprintf "1 passed, 0 failed\\n"\nexit 0\n' >"${mwork}/.agents/harness/selftest.sh"
chmod +x "${mwork}/.agents/harness/selftest.sh" "${mwork}/joharness.sh"
printf 'gen/** linguist-generated\n' >"${mwork}/.gitattributes"
for _d in app lib gen .hidden; do printf 'x\n' >"${mwork}/${_d}/f.txt"; done
# A tracked file in EACH protocol folder, read from the one constant.
mapfile -t _pd < <(bash -c 'source <(sed -n "/^MAP_PROTOCOL_DIRS=/p" "$1"); printf "%s\n" "${MAP_PROTOCOL_DIRS[@]}"' _ "${ROOT}/joharness.sh")
for _d in "${_pd[@]}"; do
  mkdir -p "${mwork}/${_d}/adr"
  printf 'x\n' >"${mwork}/${_d}/adr/f.txt"
  printf 'x\n' >"${mwork}/${_d}/f.txt"
done
git init -q "$mwork"
git -C "$mwork" symbolic-ref HEAD refs/heads/main
commit_all "$mwork" "scratch repo"

map_run() { CLAUDE_PROJECT_DIR="$mwork" JOHARNESS_CONF="${mwork}/joharness.conf" \
  "${mwork}/joharness.sh" map 2>&1; }
mapline() { printf -- '- %s%s/%s — %s\n' '`' "$1" '`' "$2"; }
map_rc=0
out="$(map_run)" || map_rc=$?
expect "no map reads none" "none — /map creates it" "$out"
expect "no map exits 0" "0" "$map_rc"

{
  printf '# Map\n\n'
  mapline app 'the application'
  mapline ghost 'a folder that is gone'
  mapline docs 'harness docs'
  mapline docs/adr 'decisions'
} >"${mwork}/docs/MAP.md"
commit_all "$mwork" "add map"
out="$(map_run)"
expect "unlisted product folder is missing" "missing : lib/" "$out"
expect "absent folder is gone" "gone    : ghost/" "$out"
expect "protocol folder in the map is gone" "gone    : docs/ (protocol folder)" "$out"
expect "protocol subfolder in the map is gone" "gone    : docs/adr/ (protocol folder)" "$out"
expect "counts line" "map       : 1 missing, 3 gone, 0 stale" "$out"
refute "generated folder is not named" "gen/" "$out"
refute "dot folder is not named" ".hidden" "$out"
for _d in "${_pd[@]}"; do
  refute "protocol folder ${_d} is not missing" "missing : ${_d}" "$out"
done

mout="$(CLAUDE_PROJECT_DIR="$mwork" JOHARNESS_CONF="${mwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${mwork}/joharness.sh" ci 2>&1)"
mlint="$(sed -n '/== graph lint/,/^$/p' <<<"$mout")"
expect "ci warns on a missing folder" "warn docs/MAP.md: missing : lib/" "$mlint"
expect "ci warns on a gone folder" "warn docs/MAP.md: gone    : ghost/" "$mlint"

# Settle the map, then change a mapped folder.
{
  mapline app 'the application'
  mapline lib 'shared code'
} >"${mwork}/docs/MAP.md"
commit_all "$mwork" "settle map"
out="$(map_run)"
expect "settled map is current" "map       : current" "$out"
printf 'y\n' >"${mwork}/app/f.txt"
commit_all "$mwork" "change app"
out="$(map_run)"
expect "changed folder is stale" "stale   : app/ (1 files changed)" "$out"
mout="$(CLAUDE_PROJECT_DIR="$mwork" JOHARNESS_CONF="${mwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${mwork}/joharness.sh" ci 2>&1)"
refute "ci does not warn on stale" "stale" "$(sed -n '/== graph lint/,/^$/p' <<<"$mout")"
