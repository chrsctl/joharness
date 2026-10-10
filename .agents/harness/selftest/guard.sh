# joharness.sh guard — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The live re-read right before a harness push onto a branch the session does
# not own (#397, #398). Each check must REFUSE its own case, named, and the
# untouched case must pass: a guard that cannot fail proves nothing, and one
# that cannot pass blocks every write. And it writes nothing: no push, no
# commit, no file in the tree.
#
# Its own bare origin and two clones: `gwork` decides, `gother` moves origin
# under it.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh guard"

gwork="${TMP}/guardwork"
gother="${TMP}/guardother"
gorigin="${TMP}/guardorigin.git"
git init -q --bare "$gorigin"
git init -q "$gwork"
git -C "$gwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${gwork}/docs/handover" "${gwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${gwork}/joharness.sh"
printf '# none\n' >"${gwork}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${gwork}/code.txt"
gconf="${gwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$gconf"
git -C "$gwork" add -A
git -C "$gwork" commit -qm base
git -C "$gwork" remote add origin "$gorigin"
git -C "$gwork" push -qu origin main
git clone -q "$gorigin" "$gother"

# <branch> <pr> — a claim on its own branch, pushed from gwork.
gclaim() {
  git -C "$gwork" checkout -qb "$1" main
  mkdir -p "${gwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: %s\nplan: none\npr: %s\nsession: https://example.invalid/session_%s\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
    "$1" "$1" "$2" "$1" "$1" >"${gwork}/docs/handover/${1}.md"
  git -C "$gwork" add -A
  git -C "$gwork" commit -qm "claim $1"
  git -C "$gwork" push -qu origin "$1"
  git -C "$gwork" checkout -q main
}
grun() { ( cd "$gwork" && env JOHARNESS_CONF="$gconf" ./joharness.sh guard "$@" 2>&1 ); }
# <label> <out> <rc>: refused, non-zero.
grefused() {
  if [ "$3" -ne 0 ]; then pass "$1 exits non-zero"
  else fail "$1 exits non-zero"; printf '%s\n' "$(indent "$2")"; fi
  refute "$1 never says pass at the end" "guard     : pass" "$2"
}

# --- untouched: every check passes ------------------------------------------
gclaim g-clean none
gorig_refs="$(git -C "$gorigin" for-each-ref)"
out="$(grun janitor g-clean)"; rc=$?
expect "untouched: protected passes" "protected : pass — g-clean is not the base branch" "$out"
expect "untouched: live passes" "live      : pass — origin has g-clean" "$out"
expect "untouched: head passes" "head      : pass — live" "$out"
expect "untouched: the pr: check passes" "protected : pass — no workstream file names a pr:" "$out"
expect "untouched: the verdict" "guard     : pass — janitor may push" "$out"
if [ "$rc" -eq 0 ]; then pass "untouched: exit 0"
else fail "untouched: exit 0 (rc ${rc})"; fi
out="$(grun kill g-clean --expect "$(git -C "$gwork" rev-parse origin/g-clean)")"; rc=$?
if [ "$rc" -eq 0 ]; then pass "an explicit --expect at the live head passes"
else fail "an explicit --expect at the live head passes (rc ${rc})"; printf '%s\n' "$(indent "$out")"; fi

# --- base branch: refused by name, before any network read -----------------
out="$(grun janitor main)"; rc=$?
expect "base branch: refused at protected" "protected : REFUSED — main is the base branch" "$out"
grefused "base branch" "$out" "$rc"
refute "base branch: no live read" "live      :" "$out"
# A stale local refs/remotes/origin/main: origin's main moved since this read.
# Without check 1 first, head would refuse; the refusal must name protected.
git -C "$gother" commit -q --allow-empty -m "main moves"
git -C "$gother" push -q origin main
out="$(grun loop main)"; rc=$?
expect "stale base ref: still refused at protected" "protected : REFUSED — main is the base branch" "$out"
refute "stale base ref: not at head" "head      :" "$out"
grefused "stale base ref" "$out" "$rc"

# --- deleted on origin: released already ------------------------------------
gclaim g-deleted none
git -C "$gorigin" branch -qD g-deleted
out="$(grun janitor g-deleted)"; rc=$?
expect "deleted ref: refused at live" "live      : REFUSED — g-deleted gone on origin: already released" "$out"
grefused "deleted ref" "$out" "$rc"
if [ "$rc" -eq 2 ]; then pass "deleted ref: exit 2, the released code"
else fail "deleted ref: exit 2, the released code (rc ${rc})"; fi
if [ -z "$(git -C "$gorigin" ls-remote --heads "$gorigin" g-deleted)" ]; then
  pass "deleted ref: origin still has no such branch"
else fail "deleted ref: origin still has no such branch (re-created)"; fi

# --- unreachable origin: a question unanswered is a refusal -----------------
gurl="$(git -C "$gwork" config remote.origin.url)"
git -C "$gwork" config remote.origin.url "${TMP}/no-such-guard-origin.git"
out="$(grun kill g-clean)"; rc=$?
git -C "$gwork" config remote.origin.url "$gurl"
expect "unreachable: refused at live" "live      : REFUSED — g-clean: cannot ask origin" "$out"
grefused "unreachable" "$out" "$rc"
if [ "$rc" -eq 1 ]; then pass "unreachable: exit 1, not the released code"
else fail "unreachable: exit 1, not the released code (rc ${rc})"; fi

# --- moved head: the decision's read is stale --------------------------------
gclaim g-moved none
git -C "$gother" fetch -q origin g-moved
git -C "$gother" checkout -q -b g-moved origin/g-moved
printf 'more\n' >>"${gother}/code.txt"
git -C "$gother" commit -qam "manager pushed"
git -C "$gother" push -q origin g-moved
out="$(grun kill g-moved)"; rc=$?
expect "moved head: refused at head" "head      : REFUSED — live" "$out"
expect "moved head: says re-decide" ": re-decide" "$out"
grefused "moved head" "$out" "$rc"
expect "moved head: claim line, unchanged claim both sides" \
  "claim     : docs/handover/g-moved.md — read: session https://example.invalid/session_g-moved status in-progress; live: session https://example.invalid/session_g-moved status in-progress" "$out"

# --- re-claimed: a new session took the branch over -------------------------
gclaim g-reclaim none
git -C "$gother" fetch -q origin g-reclaim
git -C "$gother" checkout -q -b g-reclaim origin/g-reclaim
sed -i.bak -e 's/session_g-reclaim/session_successor/' -e 's/^status: .*/status: review/' \
  "${gother}/docs/handover/g-reclaim.md"
rm -f "${gother}/docs/handover/g-reclaim.md.bak"
git -C "$gother" commit -qam "successor resumes"
git -C "$gother" push -q origin g-reclaim
out="$(grun janitor g-reclaim)"; rc=$?
expect "re-claimed: refused at head" "head      : REFUSED — live" "$out"
expect "re-claimed: claim line prints both sides" \
  "read: session https://example.invalid/session_g-reclaim status in-progress; live: session https://example.invalid/session_successor status review" "$out"
grefused "re-claimed" "$out" "$rc"

# --- pr: set at live head ---------------------------------------------------
gclaim g-withpr 77
out="$(grun janitor g-withpr)"; rc=$?
expect "pr: set, janitor: refused at protected" \
  "protected : REFUSED — docs/handover/g-withpr.md names pr: 77 at live head" "$out"
grefused "pr: set, janitor" "$out" "$rc"
out="$(grun kill g-withpr)"; rc=$?
expect "pr: set, kill: passes, a stalled manager stays killable" "guard     : pass — kill may push" "$out"
if [ "$rc" -eq 0 ]; then pass "pr: set, kill: exit 0"
else fail "pr: set, kill: exit 0 (rc ${rc})"; fi
refute "pr: set, kill: the pr: check never runs" "names pr:" "$out"

# --- usage ------------------------------------------------------------------
out="$(grun release g-clean)"; rc=$?
if [ "$rc" -ne 0 ]; then pass "an unknown verb is a usage error"
else fail "an unknown verb is a usage error"; fi
out="$(grun janitor)"; rc=$?
if [ "$rc" -ne 0 ]; then pass "no branch is a usage error"
else fail "no branch is a usage error"; fi

# --- guard writes nothing ---------------------------------------------------
# Origin holds exactly the branches the fixture pushed: guard re-created none.
gmoves="$(git -C "$gorigin" for-each-ref --format='%(refname)' | sort)"
gwant="$( { printf '%s\n' "$gorig_refs" | awk '{ print $3 }'; \
  printf 'refs/heads/%s\n' g-moved g-reclaim g-withpr; } | grep -v '^refs/heads/g-deleted$' | sort -u)"
if [ "$gmoves" = "$gwant" ]; then pass "guard pushed no ref to origin"
else fail "guard pushed no ref to origin"; printf '    got:\n%s\n    wanted:\n%s\n' "$(indent "$gmoves")" "$(indent "$gwant")"; fi
if [ -z "$(git -C "$gwork" status --porcelain)" ]; then pass "guard left the tree clean"
else fail "guard left the tree clean"; printf '%s\n' "$(indent "$(git -C "$gwork" status --porcelain)")"; fi
if [ "$(git -C "$gwork" rev-parse HEAD)" = "$(git -C "$gwork" rev-parse main)" ] &&
   [ "$(git -C "$gwork" rev-list --count main)" -eq 1 ]; then
  pass "guard committed nothing"
else fail "guard committed nothing"; fi
