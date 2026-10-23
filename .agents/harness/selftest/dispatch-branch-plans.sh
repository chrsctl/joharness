# joharness.sh dispatch: branch plans — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Plans on a branch, FREEABLE, CEILING? and a stopped fleet. Split from dispatch.sh so the runner can
# run it beside the rest: every fixture here is its own repository and
# nothing in another dispatch topic reads it. How a case uses a fixture:
# dispatch.sh's header.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh dispatch: branch plans"

# --- plans on a branch: visible, never free (issue #297) --------------------
# The queue reads `docs/plans/` on the base only, so a plan an unmerged branch
# added had no row anywhere. Its own repo: the verdict and the free count are
# compared with and without the branch, so nothing else may move between.
bpwork="${TMP}/branchplanwork"
bporigin="${TMP}/branchplanorigin.git"
git init -q --bare "$bporigin"
git init -q "$bpwork"
git -C "$bpwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${bpwork}/docs/plans" "${bpwork}/docs/handover" \
  "${bpwork}/.agents/harness" "${bpwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${bpwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${bpwork}/.agents/harness/"
printf '# none\n' >"${bpwork}/.agents/env/none/AGENTS.md"
bpconf="${bpwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$bpconf"
# <file> <name> <urgency>
bpplan() {
  printf -- '---\nplan: %s\nurgency: %s\nagent: sonnet\neffort: low\n---\n\n## Goal\nFixture.\n' \
    "$2" "$3" >"$1"
}
bpplan "${bpwork}/docs/plans/onmain.md" onmain normal
commit_all "$bpwork" "base"
git -C "$bpwork" remote add origin "$bporigin"
git -C "$bpwork" push -qu origin main
bp() { ( cd "$bpwork" && JOHARNESS_CONF="$bpconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 ); }
bp_before="$(bp)"
refute "no branch plan, no block" "plans on a branch" "$bp_before"

# A plan-only branch: an urgent plan, no workstream file.
git -C "$bpwork" checkout -qb plan-only
bpplan "${bpwork}/docs/plans/x.md" x urgent
commit_all "$bpwork" "file plan x"
git -C "$bpwork" push -qu origin plan-only
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a plan an unmerged branch added is listed, URGENT first, with its branch" \
  "  URGENT x (urgency: urgent, agent: sonnet)  on plan-only" "$out"
expect "under its own heading" \
  "plans on a branch, not in the queue until it merges:" "$out"
if [ "$(grep '^verdict' <<<"$out")" = "$(grep '^verdict' <<<"$bp_before")" ]; then
  pass "and the verdict, free count included, is the one without the branch"
else
  fail "and the verdict, free count included, is the one without the branch"
  printf '    without: %s\n    with:    %s\n' \
    "$(grep '^verdict' <<<"$bp_before")" "$(grep '^verdict' <<<"$out")"
fi
refute "and it is never in the spawn list" "docs/plans/x.md" "$out"

# A manager branch carrying its own same-session plan, `plan:` written as a
# path: in flight, not hidden.
git -C "$bpwork" checkout -qb mgr-y main
mkdir -p "${bpwork}/docs/handover"
bpplan "${bpwork}/docs/plans/y.md" y normal
printf -- '---\nworkstream: y\nstatus: in-progress\nbranch: mgr-y\nplan: docs/plans/y.md\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/y.md"
commit_all "$bpwork" "manager with its own plan"
git -C "$bpwork" push -qu origin mgr-y
git -C "$bpwork" checkout -q main
# An abandoned branch that added a plan of its own and another.
git -C "$bpwork" checkout -qb gone-z main
# git took the directory with mgr-y's file: put it back, then CHECK the file
# landed, or the refute below passes over a fixture that was never built.
mkdir -p "${bpwork}/docs/handover"
bpplan "${bpwork}/docs/plans/z.md" z urgent
printf -- '---\nworkstream: gone\nstatus: abandoned\nbranch: gone-z\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: Nothing\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/gone.md"
commit_all "$bpwork" "abandoned branch with a plan"
git -C "$bpwork" push -qu origin gone-z
git -C "$bpwork" checkout -q main
for bpf in y.md gone.md; do
  bpref="mgr-y"; [ "$bpf" = y.md ] || bpref="gone-z"
  if git -C "$bpwork" cat-file -e \
       "refs/remotes/origin/${bpref}:docs/handover/${bpf}" 2>/dev/null; then
    pass "the fixture built the state: ${bpref} carries its workstream file"
  else
    fail "${bpref} carries no workstream file, so its case below tests nothing"
  fi
done
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
expect "the plan-only branch's plan is still listed" "URGENT x" "$bpblock"
refute "a manager's own plan, named in plan: as a path, is not listed" \
  " y (urgency" "$bpblock"
refute "a plan on an abandoned branch is not listed" " z (urgency" "$bpblock"
# Diff, never tree: every branch inherits onmain.md from the base.
refute "an inherited base plan is never a branch plan" "onmain (urgency" "$bpblock"

# The edge shape of any branch with a follow-up (verifier r3): it retires its
# done plan and adds a new one from the same template. Rename detection read
# the pair as an R, and `--diff-filter=A` dropped the follow-up.
git -C "$bpwork" checkout -qb retire-and-follow main
git -C "$bpwork" rm -q docs/plans/onmain.md
mkdir -p "${bpwork}/docs/plans"
bpplan "${bpwork}/docs/plans/followup.md" followup normal
commit_all "$bpwork" "retire onmain, file followup"
git -C "$bpwork" push -qu origin retire-and-follow
# A branch stacked on the plan-only branch carries x too (verifier r5).
git -C "$bpwork" checkout -qb stacked plan-only
printf 'more\n' >"${bpwork}/stacked.txt"
commit_all "$bpwork" "stacked on plan-only"
git -C "$bpwork" push -qu origin stacked
git -C "$bpwork" checkout -q main
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
expect "a follow-up added beside a retired plan is listed, not lost to a rename" \
  "  followup (urgency: normal, agent: sonnet)  on retire-and-follow" "$bpblock"
expect "a plan two branches carry is one row naming both" \
  "  URGENT x (urgency: urgent, agent: sonnet)  on plan-only, stacked" "$bpblock"
if [ "$(grep -c 'URGENT x ' <<<"$bpblock")" = 1 ]; then
  pass "and never two URGENT rows for one plan"
else
  fail "and never two URGENT rows for one plan"
  printf '%s\n' "$(indent "$bpblock")"
fi

# A plan the base ALSO carries under the same path (verifier r6): the queue has
# its row, so it is not a branch plan, though the branch's own diff adds it.
git -C "$bpwork" checkout -qb twice main
bpplan "${bpwork}/docs/plans/w.md" w urgent
commit_all "$bpwork" "branch files w"
git -C "$bpwork" push -qu origin twice
git -C "$bpwork" checkout -q main
bpplan "${bpwork}/docs/plans/w.md" w normal
commit_all "$bpwork" "the base files w too"
git -C "$bpwork" push -q origin main
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
refute "a plan the base also carries is the queue's, not a branch plan" \
  " w (urgency" "$bpblock"
expect "while the block still lists the real branch plans" "URGENT x" "$bpblock"

# A non-ASCII plan name (verifier r4): quoted by git, it failed the `.md` test
# and vanished. The row's stem is the sanitised one; the row is what matters.
git -C "$bpwork" checkout -qb nonascii main
bpplan "${bpwork}/docs/plans/fixé.md" fixe urgent
commit_all "$bpwork" "a plan with a non-ASCII name"
git -C "$bpwork" push -qu origin nonascii
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a non-ASCII plan name still has its row" "on nonascii" \
  "$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"

# A plan another branch carried to the base and retired (carried-plan-leftover):
# absent on the base, yet not a plan waiting to land. The merge is by merge
# commit, so only `--full-history -m` sees the retire.
git -C "$bpwork" checkout -qb carry-src main
bpplan "${bpwork}/docs/plans/carried.md" carried urgent
commit_all "$bpwork" "source branch files carried"
git -C "$bpwork" push -qu origin carry-src
git -C "$bpwork" checkout -qb carrier main
bpplan "${bpwork}/docs/plans/carried.md" carried urgent
commit_all "$bpwork" "carrier takes the plan"
git -C "$bpwork" rm -q docs/plans/carried.md
git -C "$bpwork" commit -qm "carrier retires the plan"
git -C "$bpwork" checkout -q main
git -C "$bpwork" merge -q --no-ff -m "merge carrier" carrier
git -C "$bpwork" push -q origin main
# A plan retired on the base BEFORE the branch was cut: a different plan of the
# same name, which must still show.
bpplan "${bpwork}/docs/plans/reused.md" reused normal
commit_all "$bpwork" "base files reused"
git -C "$bpwork" rm -q docs/plans/reused.md
git -C "$bpwork" commit -qm "base retires reused"
git -C "$bpwork" push -q origin main
git -C "$bpwork" checkout -qb reuse-src main
bpplan "${bpwork}/docs/plans/reused.md" reused normal
commit_all "$bpwork" "branch files reused again"
git -C "$bpwork" push -qu origin reuse-src
git -C "$bpwork" checkout -q main
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
refute "a carried-and-retired plan is not a plan on a branch" "carried (urgency" "$bpblock"
expect "it is a leftover row naming its branch" \
  "docs/plans/carried.md  carry-src  leftover" "$out"
expect "a plan of a retired stem's name filed AFTER the retire still shows" \
  "  reused (urgency: normal, agent: sonnet)  on reuse-src" "$bpblock"

# --- plans on a branch: DONE ON MAIN and held Nd (issue #423) --------------
# A carry that wrote `status: done, pr: none` deletes nothing on the base, so
# the leftover test above never fires: in a consumer 3 of 9 held plans were
# already done. Same fixture repo; each case its own stem.
# <branch> <stem>: a plan-only owner branch cut from main.
bdowner() {
  git -C "$bpwork" checkout -qb "$1" main
  mkdir -p "${bpwork}/docs/plans"
  bpplan "${bpwork}/docs/plans/$2.md" "$2" normal
  commit_all "$bpwork" "owner files $2"
  git -C "$bpwork" push -qu origin "$1"
  git -C "$bpwork" checkout -q main
}
# <file> <stem>: a carrier's workstream file, done, no pull request.
bddone() {
  mkdir -p "${bpwork}/docs/handover"
  printf -- '---\nworkstream: carry-%s\nstatus: done\nbranch: x\npr: none\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\nnext: Nothing\n---\n\n## Goal\nFixture.\n' \
    "$2" "$2" >"$1"
}
# (a) an unmerged carrier retired the plan on its branch.
bdowner own-pa pa
git -C "$bpwork" checkout -qb carry-pa main
bddone "${bpwork}/docs/handover/carry-pa.md" pa
commit_all "$bpwork" "carrier finds pa done"
git -C "$bpwork" push -qu origin carry-pa
git -C "$bpwork" checkout -q main
# (b) a carrier that MERGED, with no plan file.
bdowner own-pb pb
git -C "$bpwork" checkout -qb carry-pb main
bddone "${bpwork}/docs/handover/carry-pb.md" pb
commit_all "$bpwork" "carrier finds pb done"
git -C "$bpwork" checkout -q main
git -C "$bpwork" merge -q --no-ff -m "merge carry-pb" carry-pb
git -C "$bpwork" push -q origin main carry-pb
# (c) the base's ledger lists the stem.
bdowner own-pc pc
printf '# Retired stems\n\n- pc carry-pc\n' >"${bpwork}/docs/plans/RETIRED.md"
commit_all "$bpwork" "ledger retires pc"
git -C "$bpwork" push -q origin main
# (d) a done workstream file for pd already in the owner's merge base: an
# older plan of that name. A ledger line already there is NOT: `ci` refuses
# the re-add whatever its age (lint_plans_in_diff), so the row reads done.
bddone "${bpwork}/docs/handover/old-pd.md" pd
printf -- '- pe old-carry\n' >>"${bpwork}/docs/plans/RETIRED.md"
commit_all "$bpwork" "older pd done, older pe retired"
git -C "$bpwork" push -q origin main
bdowner own-pd pd
bdowner own-pe pe
# (f) a live plan filed three days ago.
git -C "$bpwork" checkout -qb own-pf main
bpplan "${bpwork}/docs/plans/pf.md" pf normal
git -C "$bpwork" add -A
GIT_AUTHOR_DATE="$(( $(date +%s) - 3 * 86400 - 600 )) +0000" \
GIT_COMMITTER_DATE="$(( $(date +%s) - 3 * 86400 - 600 )) +0000" \
  git -C "$bpwork" commit -qm "owner files pf, three days ago"
# merged up from the base today: the age still reads the filing commit.
git -C "$bpwork" merge -q --no-ff -m "merge main into own-pf" main
git -C "$bpwork" push -qu origin own-pf
git -C "$bpwork" checkout -q main
# (g) the owner merged the base up AFTER a carrier merged pg as done: the
# carry is in the tip's merge base, never in the filing commit's.
bdowner own-pg pg
git -C "$bpwork" checkout -qb carry-pg main
bddone "${bpwork}/docs/handover/carry-pg.md" pg
commit_all "$bpwork" "carrier finds pg done"
git -C "$bpwork" checkout -q main
git -C "$bpwork" merge -q --no-ff -m "merge carry-pg" carry-pg
git -C "$bpwork" push -q origin main carry-pg
git -C "$bpwork" checkout -q own-pg
git -C "$bpwork" merge -q --no-ff -m "merge main into own-pg" main
git -C "$bpwork" push -q origin own-pg
git -C "$bpwork" checkout -q main
# (h) a builder wrote ph done, then reopened it, unmerged: its tip says
# in-progress, so the history line counts for nothing (verifier r2).
bdowner own-ph ph
git -C "$bpwork" checkout -qb build-ph main
bddone "${bpwork}/docs/handover/build-ph.md" ph
commit_all "$bpwork" "builder writes ph done"
sed -i 's/^status: done$/status: in-progress/' "${bpwork}/docs/handover/build-ph.md"
commit_all "$bpwork" "builder reopens ph"
git -C "$bpwork" push -qu origin build-ph
git -C "$bpwork" checkout -q main
# (i) an old unmerged branch wrote pi done a day before pi was filed again:
# never in any merge base, still an older plan of that name (verifier r3).
git -C "$bpwork" checkout -qb old-pi main
bddone "${bpwork}/docs/handover/old-pi.md" pi
git -C "$bpwork" add -A
GIT_AUTHOR_DATE="$(( $(date +%s) - 86400 )) +0000" \
GIT_COMMITTER_DATE="$(( $(date +%s) - 86400 )) +0000" \
  git -C "$bpwork" commit -qm "old branch writes pi done, a day ago"
git -C "$bpwork" push -qu origin old-pi
git -C "$bpwork" checkout -q main
bdowner own-pi pi
# (j) the same old record, and THEN its branch merges main up (Loop step 3):
# the merge re-shows the done line with today's time (verifier r9).
git -C "$bpwork" checkout -qb old-pj main
bddone "${bpwork}/docs/handover/old-pj.md" pj
git -C "$bpwork" add -A
GIT_AUTHOR_DATE="$(( $(date +%s) - 86400 )) +0000" \
GIT_COMMITTER_DATE="$(( $(date +%s) - 86400 )) +0000" \
  git -C "$bpwork" commit -qm "old branch writes pj done, a day ago"
git -C "$bpwork" push -qu origin old-pj
git -C "$bpwork" checkout -q main
bdowner own-pj pj
printf 'moved\n' >"${bpwork}/moved-pj.txt"
commit_all "$bpwork" "main moves"
git -C "$bpwork" push -q origin main
git -C "$bpwork" checkout -q old-pj
git -C "$bpwork" merge -q --no-ff -m "merge main into old-pj" main
git -C "$bpwork" push -q origin old-pj
git -C "$bpwork" checkout -q main
# (k) a done record in the owner's merge base, re-shown by a branch cut
# BEFORE it that merges main up afterwards (verifier r10).
git -C "$bpwork" checkout -qb side-pk main
printf 'side\n' >"${bpwork}/side-pk.txt"
commit_all "$bpwork" "side work"
git -C "$bpwork" push -qu origin side-pk
git -C "$bpwork" checkout -q main
bddone "${bpwork}/docs/handover/old-pk.md" pk
commit_all "$bpwork" "older pk done on main"
git -C "$bpwork" push -q origin main
bdowner own-pk pk
git -C "$bpwork" checkout -q side-pk
git -C "$bpwork" merge -q --no-ff -m "merge main into side-pk" main
git -C "$bpwork" push -q origin side-pk
git -C "$bpwork" checkout -q main
# (l) a done record in the merge base that main retires AFTER the filing:
# the retire deletes the line with today's time (verifier r11).
bddone "${bpwork}/docs/handover/old-pl.md" pl
commit_all "$bpwork" "older pl done on main"
git -C "$bpwork" push -q origin main
bdowner own-pl pl
git -C "$bpwork" rm -q docs/handover/old-pl.md
git -C "$bpwork" commit -qm "main retires the old pl record"
git -C "$bpwork" push -q origin main
# (m) a builder writes pm done, then renames the file and reopens it: the
# old path is gone, which is no retire (verifier r12).
bdowner own-pm pm
git -C "$bpwork" checkout -qb build-pm main
bddone "${bpwork}/docs/handover/a-pm.md" pm
commit_all "$bpwork" "builder writes pm done"
git -C "$bpwork" mv docs/handover/a-pm.md docs/handover/b-pm.md
sed -i 's/^status: done$/status: in-progress/' "${bpwork}/docs/handover/b-pm.md"
commit_all "$bpwork" "builder renames and reopens pm"
git -C "$bpwork" push -qu origin build-pm
git -C "$bpwork" checkout -q main
# (n) a carrier merged pn done, then MAIN reopened it: the carrier's own ref
# still says done, main decides (verifier r15).
bdowner own-pn pn
git -C "$bpwork" checkout -qb carry-pn main
bddone "${bpwork}/docs/handover/carry-pn.md" pn
commit_all "$bpwork" "carrier finds pn done"
git -C "$bpwork" checkout -q main
git -C "$bpwork" merge -q --no-ff -m "merge carry-pn" carry-pn
git -C "$bpwork" push -q origin main carry-pn
sed -i 's/^status: done$/status: in-progress/' "${bpwork}/docs/handover/carry-pn.md"
commit_all "$bpwork" "main reopens pn"
git -C "$bpwork" push -q origin main
# (o) a builder writes po done, then reopens it naming the plan in backticks:
# the reader every other `plan:` goes through still reads po (verifier r16).
bdowner own-po po
git -C "$bpwork" checkout -qb build-po main
bddone "${bpwork}/docs/handover/build-po.md" po
commit_all "$bpwork" "builder writes po done"
sed -i "s/^status: done\$/status: in-progress/; s/^plan: po\$/plan: \`po\`/" \
  "${bpwork}/docs/handover/build-po.md"
commit_all "$bpwork" "builder reopens po, backticked"
git -C "$bpwork" push -qu origin build-po
git -C "$bpwork" checkout -q main
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
expect "(a) a stem an unmerged carrier wrote done is DONE ON MAIN" \
  "  DONE ON MAIN pa (urgency: normal, agent: sonnet)  on own-pa  held 0d: retired elsewhere — drop it, never spawn on it" "$bpblock"
expect "(b) a stem a merged carrier wrote done is DONE ON MAIN" \
  "  DONE ON MAIN pb (urgency: normal, agent: sonnet)  on own-pb" "$bpblock"
expect "(c) a stem the base's ledger lists is DONE ON MAIN" \
  "  DONE ON MAIN pc (urgency: normal, agent: sonnet)  on own-pc" "$bpblock"
expect "(d) a done record already in the merge base is an older plan: live" \
  "  pd (urgency: normal, agent: sonnet)  on own-pd  held 0d" "$bpblock"
refute "(d) and it carries no marker" "DONE ON MAIN pd " "$bpblock"
expect "(c) a ledger line older than the plan still reads done, as ci refuses it" \
  "  DONE ON MAIN pe (urgency: normal, agent: sonnet)  on own-pe" "$bpblock"
expect "(e) the base-added-and-retired leftover keeps its text" \
  "docs/plans/carried.md  carry-src  leftover  its plan carried landed and was retired by another branch" "$out"
refute "(e) and it is no DONE ON MAIN row" "DONE ON MAIN carried" "$bpblock"
expect "(f) a live plan carries held Nd from its filing commit, not its tip" \
  "  pf (urgency: normal, agent: sonnet)  on own-pf  held 3d" "$bpblock"
refute "(f) and no marker" "DONE ON MAIN pf " "$bpblock"
expect "(g) a carry the owner merged up after still reads DONE ON MAIN" \
  "  DONE ON MAIN pg (urgency: normal, agent: sonnet)  on own-pg" "$bpblock"
expect "(h) a done record its ref reopened is live" \
  "  ph (urgency: normal, agent: sonnet)  on own-ph  held 0d" "$bpblock"
refute "(h) and no marker" "DONE ON MAIN ph " "$bpblock"
expect "(i) a done record older than the filing, on an unmerged branch, is live" \
  "  pi (urgency: normal, agent: sonnet)  on own-pi  held 0d" "$bpblock"
refute "(i) and no marker" "DONE ON MAIN pi " "$bpblock"
expect "(j) an old record its branch merged main up over is still older: live" \
  "  pj (urgency: normal, agent: sonnet)  on own-pj  held 0d" "$bpblock"
refute "(j), no marker" "DONE ON MAIN pj " "$bpblock"
expect "(k) a merge-base record a later merge-up re-shows is still older: live" \
  "  pk (urgency: normal, agent: sonnet)  on own-pk  held 0d" "$bpblock"
refute "(k), no marker" "DONE ON MAIN pk " "$bpblock"
expect "(l) a merge-base record main retires later is still older: live" \
  "  pl (urgency: normal, agent: sonnet)  on own-pl  held 0d" "$bpblock"
refute "(l), no marker" "DONE ON MAIN pl " "$bpblock"
expect "(m) a done record renamed and reopened is live" \
  "  pm (urgency: normal, agent: sonnet)  on own-pm  held 0d" "$bpblock"
refute "(m), no marker" "DONE ON MAIN pm " "$bpblock"
expect "(n) a merged carrier's record main reopened is live" \
  "  pn (urgency: normal, agent: sonnet)  on own-pn  held 0d" "$bpblock"
refute "(n), no marker" "DONE ON MAIN pn " "$bpblock"
expect "(o) a record reopened with a backticked plan: is live" \
  "  po (urgency: normal, agent: sonnet)  on own-po  held 0d" "$bpblock"
refute "(o), no marker" "DONE ON MAIN po " "$bpblock"
bdrows="$(grep -c '^  ' <<<"$bpblock")"
bdheld="$(grep -c '  held [0-9][0-9]*d' <<<"$bpblock")"
if [ "$bdrows" -gt 0 ] && [ "$bdrows" = "$bdheld" ]; then
  pass "every plans-on-a-branch row carries held"
else
  fail "every plans-on-a-branch row carries held (${bdheld} of ${bdrows})"
  printf '%s\n' "$(indent "$bpblock")"
fi
if grep -q '^verdict' <<<"$out" && ! grep -q 'docs/plans/p[a-o]\.md' \
     <<<"$(sed '/^plans on a branch/,/^$/d' <<<"$out")"; then
  pass "and no DONE ON MAIN or live branch plan reaches the spawn list"
else
  fail "and no DONE ON MAIN or live branch plan reaches the spawn list"
fi

# --- FREEABLE: a doc-only branch nobody will merge (issue #423) -------------
# Same fixture. A fresh plan branch is no row: its author may be mid-pull-
# request. A plan branch past HANDOVER_STALE_SECONDS is `free <branch>`, a
# spawnable item. An empty done branch needs no wait.
refute "a fresh plan branch is not FREEABLE" "free plan-only (agent" "$out"
expect "an empty done branch is FREEABLE at once" \
  "  free carry-pa (agent: sonnet)  FREEABLE — its only diff is a status: done, pr: none workstream file" "$out"
# The free count before the stale branch, to pin that it adds exactly one
# (verifier r6: NOT DRAINED alone held with the count code removed).
bpfree0="$(sed -n 's/^verdict   : NOT DRAINED — \([0-9][0-9]*\) free item.*/\1/p' <<<"$out")"
git -C "$bpwork" checkout -qb gone-q main
bpplan "${bpwork}/docs/plans/q.md" q normal
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$bpwork" commit -qm "file q, long ago"
git -C "$bpwork" push -qu origin gone-q
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a plan branch past the stale window is FREEABLE" \
  "  free gone-q (agent: sonnet)  FREEABLE — 1 plan(s) on a doc-only branch" "$out"
expect "and it counts as one more free item" \
  "verdict   : NOT DRAINED — $(( ${bpfree0:-0} + 1 )) free item(s)" "$out"
refute "plan-only, still fresh, is still no row" "free plan-only (agent" "$out"
# The manager's claim: the row goes, the claim holds a slot, and the claim's
# own doc-only branch is never FREEABLE.
git -C "$bpwork" checkout -qb mgr-free-q main
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: free-gone-q\nstatus: in-progress\nbranch: mgr-free-q\npr: none\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: Run free\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/free-gone-q.md"
commit_all "$bpwork" "claim free gone-q"
git -C "$bpwork" push -qu origin mgr-free-q
git -C "$bpwork" checkout -q main
out="$(bp)"
refute "a free claim on its key drops the row" "free gone-q (agent" "$out"
expect "the claim is a manager in flight" "  free-gone-q  mgr-free-q  in-progress" "$out"
refute "and the claim's own branch is never FREEABLE" "free mgr-free-q (agent" "$out"
# Past its retire commit the claim file is gone, the pull request open: the
# owner sits merged in the manager's branch, so neither is offered (r3).
git -C "$bpwork" checkout -q mgr-free-q
git -C "$bpwork" merge -q --no-ff -m "free: merge gone-q (fixture)" gone-q
git -C "$bpwork" rm -q docs/handover/free-gone-q.md
commit_all "$bpwork" "retire the free claim"
git -C "$bpwork" push -q origin mgr-free-q
git -C "$bpwork" checkout -q main
out="$(bp)"
refute "a freed owner past the retire commit is not offered again" "free gone-q (agent" "$out"
refute "nor is the free manager's own branch" "free mgr-free-q (agent" "$out"
# A free merged by hand, git's own subject, claim retired: the owner is
# still held, and the manager's branch is still never offered (round 3).
git -C "$bpwork" checkout -qb gone-hm main
bpplan "${bpwork}/docs/plans/fhm.md" fhm normal
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$bpwork" commit -qm "file fhm, long ago"
git -C "$bpwork" push -qu origin gone-hm
git -C "$bpwork" checkout -qb mgr-free-hm main
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: free-gone-hm\nstatus: in-progress\nbranch: mgr-free-hm\npr: none\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: Merge by hand\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/free-gone-hm.md"
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-02T00:00:00Z' GIT_AUTHOR_DATE='2026-01-02T00:00:00Z' \
  git -C "$bpwork" commit -qm "claim free gone-hm"
GIT_COMMITTER_DATE='2026-01-02T00:00:00Z' GIT_AUTHOR_DATE='2026-01-02T00:00:00Z' \
  git -C "$bpwork" merge -q --no-ff --no-edit gone-hm
git -C "$bpwork" rm -q docs/handover/free-gone-hm.md
commit_all "$bpwork" "retire the free claim"
git -C "$bpwork" push -qu origin mgr-free-hm
git -C "$bpwork" checkout -q main
out="$(bp)"
refute "a hand-merged free still holds its owner" "free gone-hm (agent" "$out"
refute "and its manager's branch is never offered" "free mgr-free-hm (agent" "$out"
# A retired claim past the stale window: its session is gone and no pull
# request merged it; nothing else can release it, so it holds nothing (round 4).
git -C "$bpwork" checkout -qb gone-st main
bpplan "${bpwork}/docs/plans/fst.md" fst normal
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$bpwork" commit -qm "file fst, long ago"
git -C "$bpwork" push -qu origin gone-st
git -C "$bpwork" checkout -qb mgr-free-st main
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: free-gone-st\nstatus: in-progress\nbranch: mgr-free-st\npr: none\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: Free\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/free-gone-st.md"
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-02T00:00:00Z' GIT_AUTHOR_DATE='2026-01-02T00:00:00Z' \
  git -C "$bpwork" commit -qm "claim free gone-st"
GIT_COMMITTER_DATE='2026-01-02T00:00:00Z' GIT_AUTHOR_DATE='2026-01-02T00:00:00Z' \
  git -C "$bpwork" merge -q --no-ff -m "free: merge gone-st (fixture)" gone-st
git -C "$bpwork" rm -q docs/handover/free-gone-st.md
GIT_COMMITTER_DATE='2026-01-02T00:00:00Z' GIT_AUTHOR_DATE='2026-01-02T00:00:00Z' \
  git -C "$bpwork" commit -qm "retire the free claim, then the session died"
git -C "$bpwork" push -qu origin mgr-free-st
git -C "$bpwork" checkout -q main
# A builder file named free-* for a plan of that name is no free claim
# (round 4): its branch, cut from an owner, never holds it.
git -C "$bpwork" checkout -qb gone-ft main
bpplan "${bpwork}/docs/plans/fft.md" fft normal
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$bpwork" commit -qm "file fft, long ago"
git -C "$bpwork" push -qu origin gone-ft
git -C "$bpwork" checkout -qb build-ft gone-ft
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: free-text\nstatus: in-progress\nbranch: build-ft\npr: none\nplan: free-text\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/free-text.md"
commit_all "$bpwork" "builder of plan free-text"
git -C "$bpwork" push -qu origin build-ft
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a stale retired free claim no longer holds its owner" "  free gone-st (agent: sonnet)  FREEABLE" "$out"
expect "a free-* file that is a builder's, not a claim, holds nothing" \
  "  free gone-ft (agent: sonnet)  FREEABLE" "$out"
# A released free claim lends nothing: its owner is offered again (r4).
git -C "$bpwork" checkout -qb gone-w main
bpplan "${bpwork}/docs/plans/fw.md" fw normal
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$bpwork" commit -qm "file w, long ago"
git -C "$bpwork" push -qu origin gone-w
git -C "$bpwork" checkout -qb mgr-free-w main
git -C "$bpwork" merge -q --no-ff -m "free: merge gone-w (fixture)" gone-w
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: free-gone-w\nstatus: abandoned\nbranch: mgr-free-w\npr: none\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: Released\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/free-gone-w.md"
commit_all "$bpwork" "free claim released"
git -C "$bpwork" push -qu origin mgr-free-w
git -C "$bpwork" checkout -q main
# A branch cut from the owner frees nothing: it never hides the owner (v4).
git -C "$bpwork" checkout -qb prod-w gone-w
printf 'product\n' >"${bpwork}/prod-w.txt"
commit_all "$bpwork" "product work on top of gone-w"
git -C "$bpwork" push -qu origin prod-w
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a released free claim offers its owner again" "  free gone-w (agent: sonnet)  FREEABLE" "$out"
# A done free claim with no merge pushed holds no key: the owner is offered
# (round 2, v2: a refusal must not park it for the stale window).
git -C "$bpwork" checkout -qb gone-d main
bpplan "${bpwork}/docs/plans/fd.md" fd normal
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$bpwork" commit -qm "file fd, long ago"
git -C "$bpwork" push -qu origin gone-d
git -C "$bpwork" checkout -qb mgr-free-d main
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: free-gone-d\nstatus: done\nbranch: mgr-free-d\npr: none\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: Nothing\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/free-gone-d.md"
commit_all "$bpwork" "a done free claim, no merge"
git -C "$bpwork" push -qu origin mgr-free-d
git -C "$bpwork" checkout -q main
# A branch that merges the owner but never claimed a free holds nothing,
# whatever its merge subject says (round 3).
git -C "$bpwork" checkout -qb spoof-d main
git -C "$bpwork" merge -q --no-ff -m "free: merge gone-d (spoof)" gone-d
git -C "$bpwork" push -qu origin spoof-d
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a done free claim with no merge does not hide its owner" \
  "  free gone-d (agent: sonnet)  FREEABLE" "$out"
# Parked on a human: never offered, however old (r2).
git -C "$bpwork" checkout -qb held-h main
bpplan "${bpwork}/docs/plans/fh.md" fh normal
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: held\nstatus: blocked\nbranch: held-h\npr: none\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: product: which one?\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/held.md"
git -C "$bpwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$bpwork" commit -qm "park on a question, long ago"
git -C "$bpwork" push -qu origin held-h
git -C "$bpwork" checkout -q main
out="$(bp)"
refute "a branch parked on a human is never FREEABLE" "free held-h (agent" "$out"
# A free claim at done is mid-retire: listed, no slot.
bpslots0="$(sed -n 's/^slots     : \([0-9][0-9]*\) of.*/\1/p' <<<"$out")"
git -C "$bpwork" checkout -qb mgr-free-held main
mkdir -p "${bpwork}/docs/handover"
printf -- '---\nworkstream: free-held-h\nstatus: done\nbranch: mgr-free-held\npr: none\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: free refused: held-h is blocked\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/free-held-h.md"
commit_all "$bpwork" "free refused"
git -C "$bpwork" push -qu origin mgr-free-held
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a done free claim is listed" \
  "  free-held-h  mgr-free-held  done  pushed 0m  done: holds no slot" "$out"
expect "and holds no slot" "slots     : ${bpslots0:-x} of" "$out"

# --- time against the item: CEILING? (issue #298) ---------------------------
# A manager that pushes inside the stall window and under the churn limit read
# healthy for 5.5h and $48 with no pull request. The row now carries hours
# since the CLAIM when its workstream says `pr: none` — a report, never a
# condition, so the verdict must be the one the same fixture gives with the
# knob lifted. Its own fixture: the branches it adds move no count above.
cewwork="${TMP}/ceilingwork"
cewworigin="${TMP}/ceilingorigin.git"
git init -q --bare "$cewworigin"
git init -q "$cewwork"
git -C "$cewwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cewwork}/docs/plans" "${cewwork}/docs/handover" \
  "${cewwork}/.agents/harness" "${cewwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${cewwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${cewwork}/.agents/harness/"
printf '# none\n' >"${cewwork}/.agents/env/none/AGENTS.md"
cewconf="${cewwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$cewconf"
for p in slow other; do
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$p" >"${cewwork}/docs/plans/${p}.md"
done
commit_all "$cewwork" "base and two plans"
git -C "$cewwork" remote add origin "$cewworigin"
git -C "$cewwork" push -qu origin main
cew() { ( cd "$cewwork" && JOHARNESS_CONF="$cewconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
# <pr value>: the workstream file a manager on `slow` would write.
cewws() {
  printf -- '---\nworkstream: slow\nstatus: in-progress\nbranch: mgr-slow\npr: %s\nplan: slow\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nWorking.\n' \
    "$1" >"${cewwork}/docs/handover/slow.md"
}
# Claimed 10h ago, pushed NOW: inside every stall window, past the ceiling.
# The date rides on the one commit, so it cannot leak into the push after it.
git -C "$cewwork" checkout -qb mgr-slow
cewws none
git -C "$cewwork" add -A
cewt=$(( $(date +%s) - 10 * 3600 ))
GIT_AUTHOR_DATE="@${cewt} +0000" GIT_COMMITTER_DATE="@${cewt} +0000" \
  git -C "$cewwork" commit -qm "claim slow"
printf 'code\n' >"${cewwork}/code.txt"
commit_all "$cewwork" "a push this minute"
git -C "$cewwork" push -qu origin mgr-slow
git -C "$cewwork" checkout -q main

# A claim past the ceiling with no pr:.
out="$(cew)"
cewrow="$(printf '%s\n' "$out" | grep 'mgr-slow')"
expect "the header names the ceiling and its knob" \
  "ceiling   : 4h since the claim with no pr: = CEILING? (JOHARNESS_MANAGER_HOURS; 0 lifts it)" "$out"
expect "a claim past the ceiling with no pr: carries CEILING?" \
  "CEILING? 10h since the claim, no pr:" "$cewrow"
refute "aged from the claim, not the push" "CEILING? 0m" "$cewrow"
refute "a recent push is no stall" "STALL?" "$cewrow"
expect "the tail counts it as a report" \
  "1 manager(s) past the ceiling with no pr: in the claim file: report, never kill on this alone" "$out"
refute "and orders no health pass" "past the stall window" "$out"
cewlifted="$(cew env JOHARNESS_MANAGER_HOURS=0)"
refute "0 lifts it" "CEILING?" "$cewlifted"
expect "and the header says so" "ceiling   : lifted" "$cewlifted"
refute "and lifts the tail line with it" "past the ceiling" "$cewlifted"
# Every line from the verdict on, less the one tail line CEILING? adds.
if [ "$(sed -n '/^verdict/,$p' <<<"$out" | grep -v 'past the ceiling')" = \
     "$(sed -n '/^verdict/,$p' <<<"$cewlifted")" ] &&
   [ -n "$(sed -n '/^verdict/p' <<<"$out")" ]; then
  pass "the verdict and the spawn list are the ones the lifted knob gives"
else
  fail "the verdict and the spawn list are the ones the lifted knob gives"
fi

# The same branch with a pull request open: the ceiling is a claim with NO pr.
git -C "$cewwork" checkout -q mgr-slow
cewws 12
commit_all "$cewwork" "open the pull request"
git -C "$cewwork" push -q origin mgr-slow
git -C "$cewwork" checkout -q main
cewrow="$(cew | grep 'mgr-slow')"
expect "the row is still in flight, so the refute below reads something" \
  "docs/plans/slow.md  mgr-slow  in-progress" "$cewrow"
refute "a claim with a pr: carries no CEILING?" "CEILING?" "$cewrow"

# The claim's age is the OLDER of its two dates (verifier, r2 and r3). A
# rebase rewrites the committer date to now and keeps the author's; a branch
# can write an author date in the future. Either one alone hides the mark.
# <stem> <author offset s> <committer offset s>: a claim 10h-ish old by one
# date and not by the other, then a push now.
cewdated() {
  git -C "$cewwork" checkout -qb "mgr-$1"
  mkdir -p "${cewwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: mgr-%s\npr: none\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nWorking.\n' \
    "$1" "$1" "$1" >"${cewwork}/docs/handover/${1}.md"
  git -C "$cewwork" add -A
  GIT_AUTHOR_DATE="@$(( $(date +%s) + $2 )) +0000" \
    GIT_COMMITTER_DATE="@$(( $(date +%s) + $3 )) +0000" \
    git -C "$cewwork" commit -qm "claim $1"
  printf '%s\n' "$1" >"${cewwork}/code.txt"
  commit_all "$cewwork" "a push this minute"
  git -C "$cewwork" push -qu origin "mgr-$1"
  git -C "$cewwork" checkout -q main
}
for p in rebased future; do
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$p" >"${cewwork}/docs/plans/${p}.md"
done
commit_all "$cewwork" "two more plans"
git -C "$cewwork" push -q origin main
cewdated rebased $(( -10 * 3600 )) 0
cewdated future 99999999 $(( -10 * 3600 ))
out="$(cew env JOHARNESS_STALL_MINUTES=9999 JOHARNESS_MAX_MANAGERS=8)"
expect "a rebased claim keeps its age: the author date" \
  "CEILING? 10h since the claim" "$(printf '%s\n' "$out" | grep 'mgr-rebased')"
expect "a claim dated in the future reads the committer date" \
  "CEILING? 10h since the claim" "$(printf '%s\n' "$out" | grep 'mgr-future')"

# --- a stopped fleet: every manager silent AND the base branch still --------
# Issue #283. An orchestrator back from an 18-day suspension read three
# RUNNING managers as 434h stalled: push age froze for the fleet, not for
# them. Own repo, because the condition is about EVERY row in flight and
# about the base branch's own age, which a shared fixture decides elsewhere.
sfwork="${TMP}/stoppedfleetwork"
sforigin="${TMP}/stoppedfleetorigin.git"
git init -q --bare "$sforigin"
git init -q "$sfwork"
git -C "$sfwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${sfwork}/docs/plans" "${sfwork}/docs/handover" \
  "${sfwork}/.agents/harness" "${sfwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${sfwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${sfwork}/.agents/harness/"
printf '# none\n' >"${sfwork}/.agents/env/none/AGENTS.md"
sfconf="${sfwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$sfconf"
for p in frozen recent; do
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$p" >"${sfwork}/docs/plans/${p}.md"
done
git -C "$sfwork" add -A
# Base AND claim both 100h old: past 24 windows of the 45m default (18h).
# The date rides on each commit as a prefix, so it cannot leak.
sft=$(( $(date +%s) - 100 * 3600 ))
GIT_AUTHOR_DATE="@${sft} +0000" GIT_COMMITTER_DATE="@${sft} +0000" \
  git -C "$sfwork" commit -qm "base, four days ago"
git -C "$sfwork" remote add origin "$sforigin"
git -C "$sfwork" push -qu origin main
# <stem> <commit epoch>: one manager's claim, on its own branch.
sfclaim() {
  git -C "$sfwork" checkout -qb "mgr-$1" main
  # main tracks no workstream file, so checking it out removed the directory.
  mkdir -p "${sfwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: mgr-%s\nplan: %s\nsession: https://example.invalid/session_%s\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
    "$1" "$1" "$1" "$1" >"${sfwork}/docs/handover/${1}.md"
  git -C "$sfwork" add -A
  GIT_AUTHOR_DATE="@${2} +0000" GIT_COMMITTER_DATE="@${2} +0000" \
    git -C "$sfwork" commit -qm "claim $1"
  git -C "$sfwork" push -qu origin "mgr-$1"
  git -C "$sfwork" checkout -q main
}
sfclaim frozen "$sft"
sf() { ( cd "$sfwork" && JOHARNESS_CONF="$sfconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
sfline="every manager in flight is silent and main has not moved in 100h: suspect a stopped fleet (a suspension), not 1 dead manager(s) — read the control plane for EACH before any respawn"
out="$(sf)"
expect "the silent manager is a stall row, so the line below has a row to speak for" \
  "STALL? no push for 100h" "$out"
expect "every row silent and the base still: the stopped-fleet line prints" \
  "$sfline" "$out"
expect "and it rides the verdict's tail, not the listing" \
  "suspect a stopped fleet" "$(sed -n '/^verdict/,$p' <<<"$out")"
# DISPATCH_FETCH=0 is a view this pass did not refresh, frozen exactly like a
# stopped fleet: the line says so rather than naming one cause (verifier r4).
expect "a view nobody fetched is named as the other cause" \
  "${sfline} (or this clone is stale: fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*)" "$out"
# And a pass that DID fetch, from the fixture's own bare origin, names one
# cause only: the suffix is the stale view's, never every pass's (r9).
out="$(sf env DISPATCH_FETCH=1)"
expect "a fresh fetch still suspects the fleet" "$sfline" "$out"
refute "and names no stale clone" "this clone is stale" "$out"
# A window wider than the silence: 24 x 300m = 120h > 100h. The stall row
# still fires (100h >= 300m), the multiple does not.
out="$(sf env JOHARNESS_STALL_MINUTES=300)"
expect "inside 24 windows the row still stalls" "STALL? no push for 100h" "$out"
refute "but nothing has been still long enough to suspect the fleet" \
  "suspect a stopped fleet" "$out"
# A zero window is zero windows: every base would pass it (verifier r2).
out="$(sf env JOHARNESS_STALL_MINUTES=0)"
expect "a zero window still stalls the row" "STALL? no push for" "$out"
refute "and suspects no fleet on a zero multiple" "suspect a stopped fleet" "$out"

# A second manager, pushed an hour ago. At the default window it is a stall
# too, so EVERY row stalls and the base is 100h still — and it is still no
# suspension: a manager that pushed an hour ago was not frozen 100h (r1).
sfclaim recent "$(( $(date +%s) - 3600 ))"
out="$(sf)"
expect "both rows stall at the default window" \
  "2 manager(s) past the stall window" "$out"
refute "a manager silent one hour is no frozen fleet, however still the base" \
  "suspect a stopped fleet" "$out"
# At 180m the recent one is NOT a stall: one row of two silent is not every
# row, though the silent one and the base are both past 24 windows (72h) (r3).
out="$(sf env JOHARNESS_STALL_MINUTES=180)"
expect "one row of two stalls" "1 manager(s) past the stall window" "$out"
refute "and one live row voids the suspicion" "suspect a stopped fleet" "$out"
# Parked: a blocked row is the human's and out of the count, so the silent
# one is every row again.
git -C "$sfwork" checkout -q mgr-recent
sed -i 's/^status: in-progress$/status: blocked/' "${sfwork}/docs/handover/recent.md"
commit_all "$sfwork" "park recent"
git -C "$sfwork" push -q origin mgr-recent
git -C "$sfwork" checkout -q main
out="$(sf)"
expect "the parked row is blocked, so the line below reads a live case" \
  "BLOCKED: the human's" "$out"
expect "a blocked row does not void the suspicion" "$sfline" "$out"

# The same fleet, the base branch moved this minute: the managers are silent
# while somebody else merged, so it is not a suspension.
printf 'moved\n' >"${sfwork}/moved.txt"
commit_all "$sfwork" "base moves now"
git -C "$sfwork" push -q origin main
out="$(sf)"
expect "the row still stalls, so the refute below reads a live case" \
  "STALL? no push for 100h" "$out"
refute "a base that moved prints no stopped-fleet line" "suspect a stopped fleet" "$out"

# The janitor row on a view nobody refreshed: a stale remote-tracking ref can
# name a branch already deleted on origin (#397), so the row carries the same
# stale-clone caveat as the fleet line. A 1h window makes the 100h claim stale.
sfjan="this clone is stale: fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*"
out="$(sf env HANDOVER_STALE_SECONDS=3600)"
expect "an old claim with no pr: is a janitor row" "janitor   : stale claim(s) on" "$out"
expect "and an unrefreshed view says the clone may be stale on that row" \
  "$sfjan" "$(grep '^janitor   :' <<<"$out" || :)"
out="$(sf env HANDOVER_STALE_SECONDS=3600 DISPATCH_FETCH=1)"
expect "a fetched view still names the stale claim" "janitor   : stale claim(s) on" "$out"
refute "and carries no caveat on that row" "this clone is stale" \
  "$(grep '^janitor   :' <<<"$out" || :)"
