# c2-run.sh — one selftest topic, sourced by ../selftest.sh in the order that
# file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# .agents/scripts/c2-run.sh, audit question C2 (plan conduct-c2): does a
# merged branch's test FAIL without its change? One fixture repo, this
# tree's runner and harness, one merged stem per trap the research found
# (conduct-c2-design). Each stem owns script .agents/scripts/c2-<s>.sh
# (a+b, shipped as a-b) and topic c2-<s>, both in the base commit. The
# runner line is the verdict; the table is the evidence.
#
# Fixture code is written as literal text, and the c2r_ builders run
# through eval:
# shellcheck shell=bash disable=SC2016,SC2317

step "c2-run.sh"

c2r_script="${ROOT}/.agents/scripts/c2-run.sh"
c2r_fx="${TMP}/c2fx"
c2r_out="${TMP}/c2out"
c2r_st=.agents/harness/selftest.sh
c2r_stems="chain fix char skip death helperchar newtopic testonly random other newtopicchar direct twopr oldskip notopics"
mkdir -p "$c2r_fx" "$c2r_out"

# Base: this tree's tracked files, every topic but the fixture's own dropped.
git -C "$ROOT" ls-files -z -- . ':(exclude).agents/harness/selftest/' |
  tar -C "$ROOT" --null --ignore-failed-read -T - -cf - 2>/dev/null | tar -C "$c2r_fx" -xf -
(
  cd "$c2r_fx" || exit 1
  git init -q && git symbolic-ref HEAD refs/heads/main
  mkdir -p .agents/scripts .agents/harness/selftest docs/handover
  for s in $c2r_stems; do
    printf '#!/usr/bin/env bash\n# c2-%s <a> <b>: print a+b.\necho $(( $1 - $2 ))\n' "$s" >".agents/scripts/c2-$s.sh"
    printf '# shellcheck shell=bash\nstep "c2-%s"\nexpect "c2-%s runs" "" "$(bash "${ROOT}/.agents/scripts/c2-%s.sh" 1 1)"\n' \
      "$s" "$s" "$s" >".agents/harness/selftest/c2-$s.sh"
  done
  # oldskip: an old case that skips on every host, beside the branch's.
  printf 'skip "c2-oldskip host case" "never here"\n' >>.agents/harness/selftest/c2-oldskip.sh
  # chain: c2-chain reads $c2_chain_args, which c2-chaina sets; one chain.
  printf '# shellcheck shell=bash\nstep "c2-chaina"\nc2_chain_args="2 3"\npass "c2-chaina set its args"\n' \
    >.agents/harness/selftest/c2-chaina.sh
  awk -v list="chaina $c2r_stems" '
    /^SELFTEST_TOPICS=\(/ { print; n = split(list, a, " "); for (i = 1; i <= n; i++) print "  c2-" a[i]; skip = 1; next }
    /^SELFTEST_FIRST=\(/ { print; skip = 1; next }
    /^SELFTEST_CHAINS=\(/ { print; print "  \"c2-chaina c2-chain\""; skip = 1; next }
    skip && /^\)/ { skip = 0 }
    !skip { print }' "$c2r_st" >st.tmp && mv st.tmp "$c2r_st"
  git add -A && git commit -qm "fixture base: one a-b bug per stem"

  # <s> <code step> <test step>: claim, code, test, retire, merged no-ff.
  c2r_stem() {
    git checkout -q -b "fx-$1" main
    printf -- '---\nworkstream: fx-%s\n---\n' "$1" >"docs/handover/fx-$1.md"
    git add -A && git commit -qm "fx-$1: claim"
    eval "$2"; git add -A && git commit -qm "fx-$1: code" --allow-empty
    eval "$3"; git add -A && git commit -qm "fx-$1: test"
    git rm -q "docs/handover/fx-$1.md" && git commit -qm "fx-$1: retire"
    mkdir -p docs/handover
    git checkout -q main && git merge -q --no-ff -m "merge fx-$1" "fx-$1"
  }
  c2r_fix() { sed -i 's/\$1 - \$2/$1 + $2/' ".agents/scripts/c2-$1.sh"; }
  # The refactor: same output, other spelling. Held as text, not a function,
  # because the code steps are strings c2r_stem evals, which no checker follows.
  # Exported: the eval'd steps read it, and a name read only inside a string
  # is a name shellcheck calls unused.
  export c2r_rf_expr='s/^echo \$((/printf "%s\\n" $((/'
  c2r_case() { printf '%s\n' "$2" >>".agents/harness/selftest/c2-$1.sh"; }
  c2r_r() { printf '$(bash "${ROOT}/.agents/scripts/c2-%s.sh" %s)' "$1" "$2"; }

  c2r_stem chain "c2r_fix chain" "c2r_case chain 'expect \"c2-chain chained args sum to 5\" 5 \"\$(bash \"\${ROOT}/.agents/scripts/c2-chain.sh\" \$c2_chain_args 2>/dev/null)\"'"
  c2r_stem fix "c2r_fix fix" "c2r_case fix 'expect \"c2-fix 2 3 is 5\" 5 \"$(c2r_r fix '2 3')\"'"
  c2r_stem char "sed -i \"\$c2r_rf_expr\" .agents/scripts/c2-char.sh" "c2r_case char 'expect \"c2-char 5 3 is 2\" 2 \"$(c2r_r char '5 3')\"'"
  c2r_stem skip "c2r_fix skip" "c2r_case skip 'if [ -n \"\${C2_NEVER:-}\" ]; then expect \"c2-skip 2 3 is 5\" 5 \"$(c2r_r skip '2 3')\"; else skip \"c2-skip 2 3 is 5\" \"C2_NEVER unset\"; fi'"
  c2r_stem death "c2r_fix death" "c2r_case death '[ \"$(c2r_r death '2 3')\" = 5 ] || exit 3; pass \"c2-death 2 3 exits clean\"'"
  # helperchar: the case calls a helper the branch adds to the runner.
  c2r_stem helperchar "sed -i \"\$c2r_rf_expr\" .agents/scripts/c2-helperchar.sh; sed -i 's/^skip() {/c2_run() { bash \"\${ROOT}\/.agents\/scripts\/c2-\$1.sh\" \"\${@:2}\"; }\nskip() {/' $c2r_st" \
    "c2r_case helperchar 'expect \"c2-helperchar via helper 5 3 is 2\" 2 \"\$(c2_run helperchar 5 3)\"'"
  c2r_stem newtopic "c2r_fix newtopic" "printf '%s\n' '# shellcheck shell=bash' 'step \"c2-new\"' 'expect \"c2-new 2 3 is 5\" 5 \"$(c2r_r newtopic '2 3')\"' >.agents/harness/selftest/c2-new.sh; sed -i 's/^  c2-newtopic\$/  c2-newtopic\n  c2-new/' $c2r_st"
  c2r_stem testonly ":" "c2r_case testonly 'expect \"c2-testonly 4 4 is 0\" 0 \"$(c2r_r testonly '4 4')\"'"
  c2r_stem random "c2r_fix random" "c2r_case random 'expect \"c2-random 2 3 is 5 run \$RANDOM\" 5 \"$(c2r_r random '2 3')\"'"
  # other: the Goal's fix B gets a case that passes either way; an unrelated
  # wording change A is what turns the topic red without the change.
  c2r_stem other "sed -i \"\$c2r_rf_expr\" .agents/scripts/c2-other.sh; sed -i 's/^# c2-other.*/&\\necho \"c2-other v2\" >\&2/' .agents/scripts/c2-other.sh" \
    "c2r_case other 'expect \"c2-other says v2\" v2 \"\$(bash \"\${ROOT}/.agents/scripts/c2-other.sh\" 1 1 2>&1)\"'; c2r_case other 'expect \"c2-other fix B: 5 3 is 2\" 2 \"$(c2r_r other '5 3')\"'"
  c2r_stem newtopicchar "sed -i \"\$c2r_rf_expr\" .agents/scripts/c2-newtopicchar.sh" "printf '%s\n' '# shellcheck shell=bash' 'step \"c2-newc\"' 'expect \"c2-newc 5 3 is 2\" 2 \"$(c2r_r newtopicchar '5 3')\"' >.agents/harness/selftest/c2-newc.sh; sed -i 's/^  c2-newtopicchar\$/  c2-newtopicchar\n  c2-newc/' $c2r_st"
  # direct: claim, fix, case and retire committed onto main itself, a merge
  # after them: no main merge brought the retire in.
  printf -- '---\nworkstream: fx-direct\n---\n' >docs/handover/fx-direct.md
  git add -A && git commit -qm "fx-direct: claim"
  c2r_fix direct; git add -A && git commit -qm "fx-direct: code"
  c2r_case direct "expect \"c2-direct 2 3 is 5\" 5 \"$(c2r_r direct '2 3')\""
  git add -A && git commit -qm "fx-direct: test"
  git rm -q docs/handover/fx-direct.md && git commit -qm "fx-direct: retire"
  mkdir -p docs/handover
  # twopr: fix and case merge in the first pull request; a second claim of
  # the same stem changes only a doc.
  c2r_stem twopr "c2r_fix twopr" "c2r_case twopr 'expect \"c2-twopr 2 3 is 5\" 5 \"$(c2r_r twopr '2 3')\"'"
  git checkout -q -b fx-twopr-2 main
  printf -- '---\nworkstream: fx-twopr\n---\n' >docs/handover/fx-twopr.md
  git add -A && git commit -qm "fx-twopr: claim again"
  printf 'twopr note\n' >>docs/fx-twopr-note.md
  git add -A && git commit -qm "fx-twopr: doc"
  git rm -q docs/handover/fx-twopr.md && git commit -qm "fx-twopr: retire again"
  git checkout -q main && git merge -q --no-ff -m "merge fx-twopr-2" fx-twopr-2
  # absent: one claim, never retired.
  git checkout -q -b fx-absent main
  mkdir -p docs/handover
  printf -- '---\nworkstream: fx-absent\n---\n' >docs/handover/fx-absent.md
  git add -A && git commit -qm "fx-absent: claim"
  git checkout -q main && git merge -q --no-ff -m "merge fx-absent" fx-absent
  c2r_stem oldskip "sed -i \"\$c2r_rf_expr\" .agents/scripts/c2-oldskip.sh" "c2r_case oldskip 'expect \"c2-oldskip 5 3 is 2\" 2 \"$(c2r_r oldskip '5 3')\"'"
  # notopics, last: its retire tree has no topic directory, as a tree from
  # before the topic split.
  c2r_stem notopics "c2r_fix notopics" "git rm -rq .agents/harness/selftest"
) >"${c2r_out}/build.log" 2>&1
c2r_built=$?

# A git first on PATH logs every `worktree prune` a run issues, then runs the
# real git: the prune is the call that can delete a sibling's entry mid-add.
c2r_shim="${TMP}/c2shim"
mkdir -p "$c2r_shim"
printf '#!/bin/sh\ncase "$*" in *"worktree prune"*) echo prune >>"%s/prunes" ;; esac\nexec "%s" "$@"\n' \
  "$c2r_out" "$(command -v git)" >"${c2r_shim}/git"
chmod +x "${c2r_shim}/git"
: >"${c2r_out}/prunes"

# Four at a time, each bounded.
# shellcheck disable=SC2086  # the stem list, one name a word
printf '%s\n' $c2r_stems absent |
  xargs -P 4 -I{} sh -c 'cd "$1" && PATH="$5:$PATH" timeout 600 bash "$2" "fx-$3" main >"$4/$3.out" 2>&1' \
    c2r "$c2r_fx" "$c2r_script" {} "$c2r_out" "$c2r_shim"

expect "c2-run: the fixture builds" "built 0" "built ${c2r_built} $(tail -3 "${c2r_out}/build.log")"

# <label> <stem> <runner line>: the stem's LAST line is exactly that.
c2r_line() {
  expect "$1" "[$3]" "[$(tail -1 "${c2r_out}/$2.out" 2>/dev/null)]
$(cat "${c2r_out}/$2.out" 2>/dev/null)"
}
c2r_tab="$(printf '\t')"
c2r_line "c2-run: a fix with a new case flips" fix "FLIP 1"
c2r_line "c2-run: a refactor with a characterization case does not flip" char "NO FLIP"
c2r_line "c2-run: a new case reaching skip is unread" skip "NO FLIP, 1 unread"
c2r_line "c2-run: a case after which the topic exits is unread" death "NO FLIP, 1 unread"
expect "c2-run: and its row reads MISSING without the change" \
  "c2-death 2 3 exits clean${c2r_tab}PASS${c2r_tab}MISSING${c2r_tab}new" "$(cat "${c2r_out}/death.out")"
c2r_line "c2-run: a case through a helper the branch adds to the runner does not flip" helperchar "NO FLIP"
c2r_line "c2-run: a fix tested in a new topic the parent does not list flips" newtopic "FLIP 1"
c2r_line "c2-run: a test-only branch is N/A" testonly "N/A, no change"
c2r_line "c2-run: a case reading its chain's earlier topic flips" chain "FLIP 1"
c2r_line "c2-run: another case's flip is a flip" other "FLIP 1"
expect "c2-run: and the fix's own case reads PASS PASS new" \
  "c2-other fix B: 5 3 is 2${c2r_tab}PASS${c2r_tab}PASS${c2r_tab}new" "$(cat "${c2r_out}/other.out")"
c2r_line "c2-run: a new topic and no fix does not flip" newtopicchar "NO FLIP"
c2r_line "c2-run: a label carrying \$RANDOM is unread" random "NO FLIP, 1 unread"
c2r_line "c2-run: a stem merged twice, fix in the first, flips" twopr "FLIP 1"
c2r_line "c2-run: a claim never retired is no evidence" absent "NO EVIDENCE: pairs (1 adds, 0 deletes)"
c2r_line "c2-run: an old case skipping both ways is no unread" oldskip "NO FLIP"
expect "c2-run: a retire committed onto main has no main merge" "[NO EVIDENCE: no main merge holds " \
  "[$(tail -1 "${c2r_out}/direct.out" 2>/dev/null)]"
c2r_line "c2-run: a tree with no topic directory is no evidence" notopics "NO EVIDENCE: lists"
expect "c2-run: a run's cleanup never prunes the shared repo's worktrees" "prunes 0" \
  "prunes $(wc -l <"${c2r_out}/prunes" 2>/dev/null | tr -d ' ' || true)"
expect "c2-run: no worktree outlives a run" "worktrees 1" \
  "worktrees $(git -C "$c2r_fx" worktree list | wc -l | tr -d ' ')"
refute "c2-run: the runner prints no diff body" "@@ " "$(cat "${c2r_out}"/*.out)"
