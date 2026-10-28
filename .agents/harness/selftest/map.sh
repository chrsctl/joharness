# joharness.sh map (per-folder INDEX.md), its ci lint and its finish check — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone: the runner defines the helpers and the counters.
# shellcheck shell=bash disable=SC2016  # backticks are the INDEX.md text under test

step "joharness.sh map"

mwork="${TMP}/mapwork"
mkdir -p "${mwork}/.agents/harness" "${mwork}/.agents/env/none" \
  "${mwork}/docs/plans" "${mwork}/docs/handover" "${mwork}/docs/product" \
  "${mwork}/app" "${mwork}/lib" "${mwork}/gen" "${mwork}/.hidden" \
  "${mwork}/a/b/c/d"
cp "${ROOT}/joharness.sh" "${mwork}/joharness.sh"
for _t in plans research product handover; do
  mkdir -p "${mwork}/.agents/docs/${_t}"
  printf '# %s\n' "$_t" >"${mwork}/.agents/docs/${_t}/README.md"
done
printf '#!/usr/bin/env bash\nprintf "1 passed, 0 failed\\n"\nexit 0\n' >"${mwork}/.agents/harness/selftest.sh"
chmod +x "${mwork}/.agents/harness/selftest.sh" "${mwork}/joharness.sh"
printf 'gen/** linguist-generated\n' >"${mwork}/.gitattributes"
for _d in app lib gen .hidden a a/b/c/d; do printf 'x\n' >"${mwork}/${_d}/f.txt"; done
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
map_ci() { CLAUDE_PROJECT_DIR="$mwork" JOHARNESS_CONF="${mwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${mwork}/joharness.sh" ci -v 2>&1 |
  sed -n '/== graph lint/,/^$/p'; }
# idx <folder> <purpose> [body lines...]
idx() { local d="$1" p="$2"; shift 2
  { printf '# %s/\n%s\n' "$d" "$p"; [ "$#" -eq 0 ] || printf '\n%s\n' "$@"; } >"${mwork}/${d}/INDEX.md"; }
map_rc=0
out="$(map_run)" || map_rc=$?
expect "no index: every product folder is missing" "missing : app/" "$out"
expect "a parent holding only folders is missing too" "missing : a/" "$out"
expect "depth 3 is indexed" "missing : a/b/c/" "$out"
refute "depth 4 is not" "missing : a/b/c/d/" "$out"
refute "generated folder is not named" "gen/" "$out"
refute "dot folder is not named" ".hidden" "$out"
for _d in "${_pd[@]}"; do
  refute "protocol folder ${_d} is not missing" "missing : ${_d}" "$out"
done
expect "counts line" "map       : 5 missing, 0 orphan, 0 stale, 0 broken" "$out"
expect "map exits 0" "0" "$map_rc"

idx app 'the application' '## Interface' '- `f.txt:x` — the thing' '- `f.txt:nosuch` — gone'
idx lib 'shared code' '## Folders' '- [`sub/`](sub/INDEX.md) — nothing'
idx a 'top' '## Folders' '- [`b/`](b/INDEX.md) — middle'
idx a/b 'middle' '## Folders' '- [`c/`](c/INDEX.md) — bottom'
idx a/b/c 'bottom'
idx a/b/c/d 'too deep'
idx docs 'harness docs'
commit_all "$mwork" "indexes"
out="$(map_run)"
expect "a symbol not in its file is broken" "broken  : app/INDEX.md -> f.txt:nosuch" "$out"
refute "a symbol in its file is fine" "f.txt:x" "$out"
expect "a dead link is broken" "broken  : lib/INDEX.md -> sub/INDEX.md" "$out"
expect "an index in a protocol folder is an orphan" "orphan  : docs/INDEX.md" "$out"
expect "an index too deep is an orphan" "orphan  : a/b/c/d/INDEX.md" "$out"
refute "indexed folders are not missing" "missing : a/" "$out"
# A person's INDEX.md (first line not `# <dir>/`) is never ours.
printf '# Decisions index\n- one\n' >"${mwork}/docs/adr/INDEX.md"
mkdir -p "${mwork}/hand"; printf 'x\n' >"${mwork}/hand/f.txt"
printf '# Hand-written\n- [nowhere](nowhere.md)\n' >"${mwork}/hand/INDEX.md"
commit_all "$mwork" "a person's index files"
out="$(map_run)"
refute "a person's INDEX.md in a protocol folder is no orphan" "docs/adr/INDEX.md" "$out"
refute "a person's INDEX.md covers its product folder" "missing : hand/" "$out"
refute "a person's INDEX.md is never link-checked" "hand/INDEX.md" "$out"
expect "an index /map wrote in a protocol folder is still an orphan" "orphan  : docs/INDEX.md" "$out"
printf '# app/ \n- [gone](nowhere.md)\n' >"${mwork}/app/INDEX.md"
expect "a trailing blank on the heading keeps the index ours" "broken  : app/INDEX.md -> nowhere.md" "$(map_run)"
git -C "$mwork" checkout -q -- app/INDEX.md
printf 'y\n' >>"${mwork}/hand/f.txt"
commit_all "$mwork" "change a folder a person indexes"
refute "a person's INDEX.md is never stale" "stale   : hand/" "$(map_run)"
# What the reference check accepts: a dotted symbol by its last name, a path
# from the repo root, and nothing outside `## Interface` or without a file.
printf 'def permits():\n' >"${mwork}/app/t.py"
git -C "$mwork" add app/t.py
idx app 'the application' '## Interface' '- `f.txt:x` — the thing' \
  '- `t.py:Table.permits` — dotted' '- `app/t.py:permits` — from the root' \
  '- `127.0.0.1:8000` — an address, not a file' '## Verify' '- `make x:nosuch` (Makefile)'
out="$(map_run)"
refute "a dotted symbol is found by its last name" "Table.permits" "$out"
refute "a path from the repo root resolves" "app/t.py:permits" "$out"
refute "an address is not a file reference" "127.0.0.1" "$out"
refute "only Interface lines are reference-checked" "x:nosuch" "$out"
git -C "$mwork" checkout -q -- app/INDEX.md
git -C "$mwork" rm -q --cached app/t.py; rm -f "${mwork}/app/t.py"
mkdir -p "${mwork}/web"; printf 'x\n' >"${mwork}/web/f.txt"
commit_all "$mwork" "unindexed web"
mlint="$(map_ci)"
expect "ci warns on a broken reference" "warn broken  : app/INDEX.md -> f.txt:nosuch" "$mlint"
expect "ci warns on an orphan" "warn orphan  : docs/INDEX.md" "$mlint"
refute "ci never warns on a missing index: adoption is incremental" "missing" "$mlint"

idx app 'the application' '## Interface' '- `f.txt:x` — the thing'
idx lib 'shared code'
idx web 'the web client'
git -C "$mwork" rm -q docs/INDEX.md a/b/c/d/INDEX.md
commit_all "$mwork" "settle"
out="$(map_run)"
expect "settled indexes are current" "map       : current" "$out"
printf 'x\ny\n' >"${mwork}/app/f.txt"
commit_all "$mwork" "change app"
out="$(map_run)"
expect "a changed direct file makes its folder stale" "stale   : app/ (1 changed)" "$out"
mkdir -p "${mwork}/lib/sub"; printf 'x\n' >"${mwork}/lib/sub/f.txt"
commit_all "$mwork" "new child of lib"
out="$(map_run)"
expect "a new child folder makes its parent stale" "stale   : lib/ (1 changed)" "$out"
expect "and the child is missing" "missing : lib/sub/" "$out"
refute "ci does not warn on stale" "stale" "$(map_ci)"
mkdir -p "${mwork}/café"; printf 'x\n' >"${mwork}/café/f.txt"
commit_all "$mwork" "non-ascii folder"
expect "non-ascii folder is named as itself" "missing : café/" "$(map_run)"

# --- finish: only what this branch caused fails.
map_finish() { CLAUDE_PROJECT_DIR="$mwork" JOHARNESS_CONF="${mwork}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_CHECKS='' JOHARNESS_VERBOSE='' "${mwork}/joharness.sh" finish 2>&1; }
mfin_sec() { sed -n '/^== map$/,/^$/p' <<<"$1"; }
git -C "$mwork" checkout -q -b fadd main
mkdir -p "${mwork}/newmod"; printf 'x\n' >"${mwork}/newmod/f.txt"
commit_all "$mwork" "add newmod"
out="$(mfin_sec "$(map_finish)")"
expect "finish names the folder this branch created" "missing : newmod/" "$out"
expect "finish says how to fix it" "run /map <these folders> on this branch" "$out"
refute "finish skips what this branch did not cause" "café" "$out"
idx newmod 'a new module'
commit_all "$mwork" "index newmod"
refute "finish passes once the folder has its index" "run /map" "$(map_finish)"
git -C "$mwork" checkout -q -b fedit main
printf 'x\nz\n' >"${mwork}/app/f.txt"
commit_all "$mwork" "edit app"
refute "an edit never fails finish" "run /map" "$(map_finish)"
git -C "$mwork" checkout -q -b fold main
printf 'x\n' >"${mwork}/café/g.txt"
commit_all "$mwork" "file in an old unindexed folder"
refute "a new file in an old unindexed folder never fails finish" "run /map" "$(map_finish)"
mkdir -p "${mwork}/café/sub"; printf 'x\n' >"${mwork}/café/sub/f.txt"
commit_all "$mwork" "subfolder under an old unindexed folder"
out="$(mfin_sec "$(map_finish)")"
expect "finish names the new subfolder" "missing : café/sub/" "$out"
refute "finish never names the old parent" "missing : café/" "$(grep -v 'café/sub/' <<<"$out")"
git -C "$mwork" checkout -q -b fdel main
git -C "$mwork" rm -rq a/b
commit_all "$mwork" "delete a/b"
out="$(mfin_sec "$(map_finish)")"
expect "deleting a linked child fails as broken" "broken  : a/INDEX.md -> b/INDEX.md" "$out"
git -C "$mwork" checkout -q -b fsym main
printf 'y\n' >"${mwork}/app/f.txt"
commit_all "$mwork" "drop the symbol app's index names"
out="$(mfin_sec "$(map_finish)")"
expect "removing a referenced symbol fails as broken" "broken  : app/INDEX.md -> f.txt:x" "$out"
git -C "$mwork" checkout -q -b fmove main
mkdir -p "${mwork}/moved"
git -C "$mwork" mv web/f.txt moved/f.txt
commit_all "$mwork" "move web into a new folder"
out="$(mfin_sec "$(map_finish)")"
expect "a move names the new folder" "missing : moved/" "$out"
expect "a move names the index it left behind" "orphan  : web/INDEX.md" "$out"
git -C "$mwork" checkout -q -b forph main
idx docs 'harness docs'
commit_all "$mwork" "orphan index"
out="$(mfin_sec "$(map_finish)")"
expect "a branch adding an orphan index fails" "orphan  : docs/INDEX.md" "$out"
git -C "$mwork" checkout -q main
