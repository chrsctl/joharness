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
refute "ci does not warn on an unmapped folder: adoption is incremental" "missing : lib/" "$mlint"
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

# A non-ASCII folder name must read as itself, not as git's quoted escape.
mkdir -p "${mwork}/café"
printf 'x\n' >"${mwork}/café/f.txt"
commit_all "$mwork" "non-ascii folder"
out="$(map_run)"
expect "non-ascii folder is named as itself" "missing : café/" "$out"

# --- finish: a branch that adds or removes a product folder carries its line.
map_finish() { CLAUDE_PROJECT_DIR="$mwork" JOHARNESS_CONF="${mwork}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_CHECKS='' JOHARNESS_VERBOSE='' "${mwork}/joharness.sh" finish 2>&1; }
mfin_sec() { sed -n '/^== map$/,/^$/p' <<<"$1"; }
git -C "$mwork" checkout -q -b mapadd main
mkdir -p "${mwork}/newmod"
printf 'x\n' >"${mwork}/newmod/f.txt"
commit_all "$mwork" "add newmod"
out="$(mfin_sec "$(map_finish)")"
expect "finish names the folder this branch added" "missing : newmod/" "$out"
expect "finish says how to fix it" "run /map <these folders> on this branch" "$out"
refute "finish skips drift this branch did not cause" "café" "$out"
mapline newmod 'a new module' >>"${mwork}/docs/MAP.md"
commit_all "$mwork" "map newmod"
out="$(map_finish)"
refute "finish passes once the map carries the line" "run /map" "$out"
git -C "$mwork" checkout -q -b mapedit main
printf 'z\n' >"${mwork}/app/f.txt"
commit_all "$mwork" "edit app"
out="$(map_finish)"
refute "an edit in a mapped folder never fails finish" "run /map" "$out"
# Incremental adoption: only folders this branch creates or deletes count.
git -C "$mwork" checkout -q -b mapold main
printf 'x\n' >"${mwork}/café/g.txt"
commit_all "$mwork" "add a file to an old unmapped folder"
out="$(map_finish)"
refute "a new file in an old unmapped folder never fails finish" "run /map" "$out"
mkdir -p "${mwork}/café/sub"
printf 'x\n' >"${mwork}/café/sub/f.txt"
commit_all "$mwork" "new subfolder under an old unmapped folder"
out="$(mfin_sec "$(map_finish)")"
expect "finish names the new subfolder" "missing : café/sub/" "$out"
refute "finish never names the old parent" "missing : café/" "$(grep -v 'café/sub/' <<<"$out")"
git -C "$mwork" checkout -q -b mapdel main
git -C "$mwork" rm -rq lib
commit_all "$mwork" "delete lib"
out="$(mfin_sec "$(map_finish)")"
expect "finish names a mapped folder this branch deleted" "gone    : lib/" "$out"
# A move is a create and a delete: a rename must not hide either folder.
git -C "$mwork" checkout -q -b mapmove main
mkdir -p "${mwork}/moved"
git -C "$mwork" mv lib/f.txt moved/f.txt
commit_all "$mwork" "move lib into a new folder"
out="$(mfin_sec "$(map_finish)")"
expect "a move names the new folder" "missing : moved/" "$out"
expect "a move names the emptied mapped folder" "gone    : lib/" "$out"
git -C "$mwork" checkout -q -b mapnone main
git -C "$mwork" rm -q docs/MAP.md
mkdir -p "${mwork}/fresh"
printf 'x\n' >"${mwork}/fresh/f.txt"
commit_all "$mwork" "no map, new folder"
out="$(mfin_sec "$(map_finish)")"
expect "no map: finish asks for the folder this branch added" "missing : fresh/" "$out"
refute "no map: finish names only what this branch touched" "missing : app/" "$out"
git -C "$mwork" checkout -q main
