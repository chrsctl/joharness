#!/usr/bin/env bash
# fixtures.sh <dir>: a clone of origin/main plus one merged stem per C2 trap.
# Each stem owns script .agents/scripts/c2-<stem>.sh (a+b, shipped as a-b)
# and topic .agents/harness/selftest/c2-<stem>.sh, both in the base commit.
set -euo pipefail
d="$1"; rm -rf "$d"; git clone -q --no-local /home/user/joharness "$d"; cd "$d"
git checkout -q -B main origin/main
export GIT_AUTHOR_NAME=fx GIT_AUTHOR_EMAIL=fx@invalid GIT_COMMITTER_NAME=fx GIT_COMMITTER_EMAIL=fx@invalid
st=.agents/harness/selftest.sh
stems="fix char skip death helperchar newtopic testonly random other newtopicchar twopr"
list=""
for s in $stems; do
  printf '#!/usr/bin/env bash\n# c2-%s <a> <b>: print a+b.\necho $(( $1 - $2 ))\n' "$s" > ".agents/scripts/c2-$s.sh"
  printf '# shellcheck shell=bash\nstep "c2-%s"\nexpect "c2-%s runs" "" "$(bash "${ROOT}/.agents/scripts/c2-%s.sh" 1 1)"\n' "$s" "$s" "$s" > ".agents/harness/selftest/c2-$s.sh"
  list="$list\n  c2-$s"
done
sed -i "s/^  selftest-shards\$/  selftest-shards$list/" $st
git add -A; git commit -qm "fixture base: one a-b bug per stem"

stem() { # stem <s> <code-step> <test-step>
  git checkout -q -b "fx-$1" main
  mkdir -p docs/handover; printf -- '---\nworkstream: fx-%s\n---\n' "$1" > "docs/handover/fx-$1.md"; git add -A; git commit -qm "fx-$1: claim"
  eval "$2"; git add -A; git commit -qm "fx-$1: code" --allow-empty
  eval "$3"; git add -A; git commit -qm "fx-$1: test"
  git rm -q "docs/handover/fx-$1.md"; git commit -qm "fx-$1: retire"
  git checkout -q main; git merge -q --no-ff -m "merge fx-$1" "fx-$1"
}
fix() { sed -i 's/\$1 - \$2/$1 + $2/' ".agents/scripts/c2-$1.sh"; }
refactor() { sed -i 's/^echo \$((/printf "%s\\n" $((/' ".agents/scripts/c2-$1.sh"; }
addcase() { printf '%s\n' "$2" >> ".agents/harness/selftest/c2-$1.sh"; }
r() { printf '$(bash "${ROOT}/.agents/scripts/c2-%s.sh" %s)' "$1" "$2"; }

stem fix "fix fix" "addcase fix 'expect \"c2-fix 2 3 is 5\" 5 \"$(r fix '2 3')\"'"
stem char "refactor char" "addcase char 'expect \"c2-char 5 3 is 2\" 2 \"$(r char '5 3')\"'"
stem skip "fix skip" "addcase skip 'if [ -n \"\${C2_NEVER:-}\" ]; then expect \"c2-skip 2 3 is 5\" 5 \"$(r skip '2 3')\"; else skip \"c2-skip 2 3 is 5\" \"C2_NEVER unset\"; fi'"
stem death "fix death" "addcase death '[ \"$(r death '2 3')\" = 5 ] || exit 3; pass \"c2-death 2 3 exits clean\"'"
stem helperchar "refactor helperchar; sed -i 's/^skip() {/c2_run() { bash \"\${ROOT}\/.agents\/scripts\/c2-\$1.sh\" \"\${@:2}\"; }\nskip() {/' $st" \
  "addcase helperchar 'expect \"c2-helperchar via helper 5 3 is 2\" 2 \"\$(c2_run helperchar 5 3)\"'"
stem newtopic "fix newtopic" "printf '%s\n' '# shellcheck shell=bash' 'step \"c2-new\"' 'expect \"c2-new 2 3 is 5\" 5 \"$(r newtopic '2 3')\"' > .agents/harness/selftest/c2-new.sh; sed -i 's/^  c2-newtopic\$/  c2-newtopic\n  c2-new/' $st"
stem testonly ":" "addcase testonly 'expect \"c2-testonly 4 4 is 0\" 0 \"$(r testonly '4 4')\"'"
stem random "fix random" "addcase random 'expect \"c2-random 2 3 is 5 run \$RANDOM\" 5 \"$(r random '2 3')\"'"
# other: the Goal's fix B gets a case that passes either way; an unrelated
# wording change A is what turns the topic red without the change.
stem other "refactor other; sed -i 's/^# c2-other.*/&\\necho \"c2-other v2\" >\&2/' .agents/scripts/c2-other.sh" \
  "addcase other 'expect \"c2-other says v2\" v2 \"\$(bash \"\${ROOT}/.agents/scripts/c2-other.sh\" 1 1 2>&1)\"'; addcase other 'expect \"c2-other fix B: 5 3 is 2\" 2 \"$(r other '5 3')\"'"
stem newtopicchar "refactor newtopicchar" "printf '%s\n' '# shellcheck shell=bash' 'step \"c2-newc\"' 'expect \"c2-newc 5 3 is 2\" 2 \"$(r newtopicchar '5 3')\"' > .agents/harness/selftest/c2-newc.sh; sed -i 's/^  c2-newtopicchar\$/  c2-newtopicchar\n  c2-newc/' $st"
# twopr: the fix and its case merge in the first pull request; a second
# claim of the same stem changes only a doc.
stem twopr "fix twopr" "addcase twopr 'expect \"c2-twopr 2 3 is 5\" 5 \"$(r twopr '2 3')\"'"
git checkout -q -b fx-twopr-2 main
mkdir -p docs/handover; printf -- '---\nworkstream: fx-twopr\n---\n' > docs/handover/fx-twopr.md; git add -A; git commit -qm "fx-twopr: claim again"
echo "twopr note" >> docs/fx-twopr-note.md; git add -A; git commit -qm "fx-twopr: doc"
git rm -q docs/handover/fx-twopr.md; git commit -qm "fx-twopr: retire again"
git checkout -q main; git merge -q --no-ff -m "merge fx-twopr-2" fx-twopr-2
git log --oneline -1
