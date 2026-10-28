#!/usr/bin/env bash
# c2.sh <stem> [base]: prototype of conduct question C2.
# T_fix   = the stem's last retire commit's tree.
# T_nofix = T_fix with the stem's OWN non-merge commits' changes to non-test
#           paths reverse-applied (tests kept as the branch left them).
# Runs only the selftest units holding topics the stem's own commits touched,
# in both trees, and prints each label's word in both.
set -uo pipefail
stem="$1"; base="${2:-origin/main}"
repo="$(git rev-parse --show-toplevel)"
work="$(mktemp -d)"; trap 'git -C "$repo" worktree remove --force "$work/fix" 2>/dev/null; git -C "$repo" worktree remove --force "$work/nofix" 2>/dev/null; git -C "$repo" worktree remove --force "$work/pre" 2>/dev/null; rm -rf "$work"' EXIT
hf="docs/handover/${stem}.md"
tests_re='^\.agents/harness/selftest(\.sh|/)'

# Every claim/retire pair: adds and deletes of the workstream file, oldest first.
mapfile -t adds < <(git log --reverse --full-history --diff-filter=A --format=%H "$base" -- "$hf")
mapfile -t dels < <(git log --reverse --full-history --diff-filter=D --format=%H "$base" -- "$hf")
[ "${#adds[@]}" -gt 0 ] && [ "${#adds[@]}" -eq "${#dels[@]}" ] || { echo "C2 NO EVIDENCE: claim/retire pairs ${#adds[@]}/${#dels[@]}"; exit 0; }
own=()
first=0; [ -z "${C2_LAST_PAIR_ONLY:-}" ] || first=$((${#adds[@]} - 1))
for ((i = first; i < ${#adds[@]}; i++)); do
  mapfile -t -O "${#own[@]}" own < <(git rev-list --reverse --no-merges --first-parent "${adds[$i]}^..${dels[$i]}")
done
fix="${dels[$((${#dels[@]} - 1))]}"
echo "pairs: ${#adds[@]}  own commits: ${#own[@]}  T_fix: $(git rev-parse --short "$fix")"

files="$(for c in "${own[@]}"; do git diff-tree --no-commit-id --name-only -r "$c"; done | sort -u)"
# A command or doc .md is product here (a selftest case may grep it); only
# the queue's own bookkeeping files are not.
code="$(grep -vE "$tests_re" <<<"$files" | grep -vE '^docs/(handover|plans|research)/' || true)"
topics="$(grep -E '^\.agents/harness/selftest/' <<<"$files" | sed 's|.*/||; s|\.sh$||' | sort -u)"
[ -n "$code" ] || { echo "C2 N/A: own commits touch only selftest files and queue files"; exit 0; }
[ -n "$topics" ] || grep -qx '.agents/harness/selftest.sh' <<<"$files" || { echo "C2 NO TEST: own commits touch no selftest file"; exit 0; }
echo "topics: $(tr '\n' ' ' <<<"$topics")"

git -C "$repo" worktree add -q --detach "$work/fix" "$fix"
if [ -n "${C2_NAIVE:-}" ]; then
  # The design the traps were found against: the parent's own tree and
  # runner, the touched topic files copied in, the run's exit as verdict.
  git -C "$repo" worktree add -q --detach "$work/nofix" "${adds[0]}^"
  for t in $topics; do git -C "$repo" show "$fix:.agents/harness/selftest/$t.sh" >"$work/nofix/.agents/harness/selftest/$t.sh"; done
  git -C "$work/nofix" add -A
else
# Code: the main commit the last branch last saw (its last merge of main,
# else its base) — T_fix minus exactly the branch's own changes, with no
# revert. Earlier pairs (a stem merged in several pull requests) are
# reverse-applied on top, three-way.
# The main merge that brought the last delete in: the oldest first-parent
# merge holding it (--ancestry-path with --first-parent misses a branch that
# merged main again after its retire).
mm=""
for m in $(git rev-list --reverse --first-parent --merges "$base" --not "${adds[0]}^"); do
  git merge-base --is-ancestor "$fix" "$m" && { mm="$m"; break; }
done
[ -n "$mm" ] || { echo "C2 NO EVIDENCE: no main merge holds $(git rev-parse --short "$fix")"; exit 0; }
P="$(git merge-base "${mm}^1" "$fix")"
echo "code from: $(git rev-parse --short "$P")"
git -C "$repo" worktree add -q --detach "$work/nofix" "$P"
for ((i = ${#own[@]} - 1; i >= 0; i--)); do
  c="${own[$i]}"
  git merge-base --is-ancestor "$c" "$P" || continue
  git -C "$repo" diff "${c}^" "$c" -- . ':(exclude).agents/harness/selftest.sh' ':(exclude).agents/harness/selftest/' >"$work/p.diff"
  [ -s "$work/p.diff" ] || continue
  git -C "$work/nofix" apply -R --3way "$work/p.diff" >"$work/apply.err" 2>&1 ||
    { echo "C2 NO EVIDENCE: reverse of $(git rev-parse --short "$c") conflicts: $(grep -m1 -iE 'conflict|error' "$work/apply.err")"; exit 0; }
done
git -C "$work/nofix" rm -rq --ignore-unmatch .agents/harness/selftest
git -C "$work/nofix" checkout "$fix" -- .agents/harness/selftest.sh .agents/harness/selftest
git -C "$work/nofix" add -A -- .agents/harness/selftest 2>/dev/null
fi

# Keep only the units holding a touched topic: rewrite the two lists, drop
# every other topic file, commit locally so ls-files agrees.
restrict() {
  local t="$1" keep
  keep="$(cd "$t" && bash -c '
    src=".agents/harness/selftest.sh"
    eval "$(sed -n "/^SELFTEST_TOPICS=(/,/^)/p; /^SELFTEST_CHAINS=(/,/^)/p" "$src")"
    for want in '"$(tr '\n' ' ' <<<"$topics")"'; do
      unit="$want"
      for c in "${SELFTEST_CHAINS[@]}"; do case " $c " in *" $want "*) unit="$c";; esac; done
      printf "%s\n" $unit
    done | sort -u')"
  local list chains
  list="$(cd "$t" && bash -c 'eval "$(sed -n "/^SELFTEST_TOPICS=(/,/^)/p" .agents/harness/selftest.sh)"; printf "%s\n" "${SELFTEST_TOPICS[@]}"' | grep -xF -f <(printf '%s\n' $keep))"
  chains="$(cd "$t" && bash -c 'eval "$(sed -n "/^SELFTEST_CHAINS=(/,/^)/p" .agents/harness/selftest.sh)"; printf "%s\n" "${SELFTEST_CHAINS[@]}"' |
    while read -r c; do set -- $c; grep -qxF "$1" <<<"$keep" && printf '  "%s"\n' "$c"; done)"
  awk -v list="$list" -v chains="$chains" '
    /^SELFTEST_TOPICS=\(/ { print; n=split(list, a, "\n"); for (i=1;i<=n;i++) if (a[i]!="") print "  " a[i]; skip=1; next }
    /^SELFTEST_CHAINS=\(/ { print; if (chains!="") print chains; skip=1; next }
    skip && /^\)/ { skip=0 }
    !skip { print }' "$t/.agents/harness/selftest.sh" >"$t/st.tmp" && mv "$t/st.tmp" "$t/.agents/harness/selftest.sh"
  for f in "$t"/.agents/harness/selftest/*.sh; do
    n="${f##*/}"; n="${n%.sh}"; grep -qxF "$n" <<<"$list" || git -C "$t" rm -q "$f"
  done
  git -C "$t" add -A && git -C "$t" -c user.name=c2 -c user.email=c2@invalid commit -qm c2 --allow-empty
}
restrict "$work/fix"; restrict "$work/nofix"
# Pre: before the stem's first claim, its own runner; only to tell which
# labels are new.
[ -n "${C2_NAIVE:-}" ] || { git -C "$repo" worktree add -q --detach "$work/pre" "${adds[0]}^" && restrict "$work/pre" 2>/dev/null; }

run() { local s=$SECONDS; (cd "$1" && timeout 1800 bash .agents/harness/selftest.sh) >"$work/$2.out" 2>&1; echo "$2: exit $? in $((SECONDS - s))s, $(tail -1 "$work/$2.out")"; }
run "$work/fix" fix & run "$work/nofix" nofix & { [ -n "${C2_NAIVE:-}" ] || run "$work/pre" pre; } & wait
if [ -n "${C2_NAIVE:-}" ]; then
  if grep -q ' 0 failed' <(tail -1 "$work/nofix.out"); then echo "NAIVE CONCERN"; else echo "NAIVE FINE"; fi
  exit 0
fi

# A FAIL line may carry a diagnostic after the label ("(exit 127, wanted 2)"),
# and a label may repeat: match the k-th fix line of label L to the k-th
# nofix line that is L or starts with "L (".
awk -F'\t' '
  FNR==1 { f++ }
  { match($0, /^  (PASS|FAIL|SKIP) /); if (!RSTART) next
    w=substr($0,3,4); l=substr($0,8) }
  f==1 { n++; lab[n]=l; word[n]=w; next }
  { m++; nl[m]=l; nw[m]=w }
  END {
    for (i=1;i<=n;i++) { k[lab[i]]++; want=k[lab[i]]; got="MISSING"; seen=0
      for (j=1;j<=m;j++) if (nl[j]==lab[i] || index(nl[j], lab[i] " (")==1) { if (++seen==want) { got=nw[j]; break } }
      printf "%s\t%s\t%s\n", lab[i], word[i], got }
  }' "$work/fix.out" "$work/nofix.out" >"$work/joined"
awk -F'\t' 'FNR==1{f++} f==1{ if (match($0,/^  (PASS|FAIL|SKIP) /)) pre[substr($0,8)]++; next }
  { k[$1]++; print $0 "\t" (k[$1] > pre[$1] ? "new" : "old") }' "$work/pre.out" "$work/joined" >"$work/j4" && mv "$work/j4" "$work/joined"
caught="$(awk -F'\t' '$2=="PASS" && $3=="FAIL"' "$work/joined")"
echo "per case (label, with, without, new|old) — new or flipped only:"
awk -F'\t' '$4=="new" || $2!=$3' "$work/joined" | sed 's/^/  /' | head -${C2_ROWS:-12}
echo "labels: $(wc -l <"$work/joined")  fix-FAIL: $(awk -F'\t' '$2=="FAIL"' "$work/joined" | wc -l)"
echo "PASS->FAIL: $(grep -c . <<<"$caught")  PASS->SKIP: $(awk -F'\t' '$2=="PASS" && $3=="SKIP"' "$work/joined" | wc -l)  PASS->MISSING: $(awk -F'\t' '$2=="PASS" && $3=="MISSING"' "$work/joined" | wc -l)"
grep -E 'command not found|unbound variable|^selftest: ' "$work/nofix.out" | sort | uniq -c | head -5 | sed 's/^/nofix fatal-ish: /'
other="$(awk -F'\t' '!($2=="PASS" && $3=="PASS")' "$work/joined" | grep -c .)"
if [ -n "$caught" ]; then echo "C2 FINE"
elif [ "$other" -gt 0 ]; then echo "C2 NO EVIDENCE ($other labels not PASS in both runs, none PASS->FAIL)"
else echo "C2 CONCERN (every label passes without the change)"; fi
[ -z "${C2_KEEP:-}" ] || cp "$work"/*.out "$work/joined" "$C2_KEEP"/
