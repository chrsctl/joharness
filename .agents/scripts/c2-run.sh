#!/usr/bin/env bash
#
# c2-run.sh - audit question C2 (.claude/commands/retro-audit.md §3): does a
# merged branch's test FAIL without its change?
#
# Usage: .agents/scripts/c2-run.sh <stem> [base, default origin/main]
#
# Runs the selftest units the stem's own commits touched three times: on
# T_fix (the stem's last retire), on T_nofix (the code the branch last saw
# from main, with T_fix's tests) and on the tree before its first claim (only
# to tell new labels from old). Prints one row per new or changed label,
# `<label> TAB <with> TAB <without> TAB <new|old>`, then ONE runner line:
#   FLIP <n>                n labels PASS with the change, FAIL without
#   NO FLIP                 every label reads the same both ways
#   NO FLIP, <n> unread     n new or changed labels SKIP, MISSING, or FAIL
#                           with the change
#   N/A, no change          own commits touch only tests and queue files
#   NO TEST                 own commits touch no selftest file
#   NO EVIDENCE: <why>      pairs, conflict <sha>, lists, or no main merge
# The table is the evidence; no verdict rests on a run's exit. Applies diffs,
# prints none.

set -uo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf 'usage: c2-run.sh <stem> [base]\n' >&2
  exit 2
fi
stem="$1"
base="${2:-origin/main}"
repo="$(git rev-parse --show-toplevel)" || exit 2
git -C "$repo" rev-parse -q --verify "${base}^{commit}" >/dev/null || {
  printf 'c2-run: no such base: %s\n' "$base" >&2
  exit 2
}
cd "$repo" || exit 2

work="$(mktemp -d)"
c2_cleanup() {
  local t
  for t in fix nofix pre; do
    [ ! -d "${work}/${t}" ] || git -C "$repo" worktree remove --force "${work}/${t}" 2>/dev/null
  done
  rm -rf "$work"
  git -C "$repo" worktree prune 2>/dev/null
}
trap c2_cleanup EXIT

verdict() { printf '%s\n' "$*"; exit 0; }

hf="docs/handover/${stem}.md"
st=".agents/harness/selftest.sh"
tests_re='^\.agents/harness/selftest(\.sh$|/)'

# Pairs: every add and every delete of the workstream file, oldest first.
mapfile -t adds < <(git log --reverse --full-history --diff-filter=A --format=%H "$base" -- "$hf")
mapfile -t dels < <(git log --reverse --full-history --diff-filter=D --format=%H "$base" -- "$hf")
if [ "${#adds[@]}" -eq 0 ] || [ "${#adds[@]}" -ne "${#dels[@]}" ]; then
  verdict "NO EVIDENCE: pairs (${#adds[@]} adds, ${#dels[@]} deletes)"
fi

# Own commits, every pair unioned: a stem merged in several pull requests
# counts all of them.
own=()
for ((i = 0; i < ${#adds[@]}; i++)); do
  mapfile -t -O "${#own[@]}" own < <(git rev-list --reverse --no-merges --first-parent "${adds[$i]}^..${dels[$i]}")
done
fix="${dels[$((${#dels[@]} - 1))]}"
printf 'pairs: %s  own commits: %s  T_fix: %s\n' "${#adds[@]}" "${#own[@]}" "$(git rev-parse --short "$fix")"

# Gate. A command or doc .md is product (a case may grep it); only the
# queue's own bookkeeping files are not.
files="$(for c in "${own[@]}"; do git diff-tree --no-commit-id --name-only -r "$c"; done | sort -u)"
code="$(grep -vE "$tests_re" <<<"$files" | grep -vE '^docs/(handover|plans|research)/' || true)"
topics="$(grep -E '^\.agents/harness/selftest/[^/]*\.sh$' <<<"$files" | sed 's|.*/||; s|\.sh$||' | sort -u)"
[ -n "$code" ] || verdict "N/A, no change"
[ -n "$topics" ] || grep -qxF "$st" <<<"$files" || verdict "NO TEST"
printf 'topics: %s\n' "$(tr '\n' ' ' <<<"$topics")"

# T_nofix code = P, the main commit the last branch last saw. The main merge
# that brought the last delete in is the oldest first-parent merge holding it
# (--ancestry-path with --first-parent misses a branch that merged main again
# after its retire). A delete main already held before that merge (a retire
# committed onto main itself) has none: P would be T_fix.
mm=""
for m in $(git rev-list --reverse --first-parent --merges "$base" --not "${adds[0]}^"); do
  if git merge-base --is-ancestor "$fix" "$m"; then
    git merge-base --is-ancestor "$fix" "${m}^1" || mm="$m"
    break
  fi
done
[ -n "$mm" ] || verdict "NO EVIDENCE: no main merge holds $(git rev-parse --short "$fix")"
P="$(git merge-base "${mm}^1" "$fix")"
printf 'code from: %s\n' "$(git rev-parse --short "$P")"

git worktree add -q --detach "${work}/fix" "$fix" || exit 2
git worktree add -q --detach "${work}/nofix" "$P" || exit 2
git worktree add -q --detach "${work}/pre" "${adds[0]}^" || exit 2

# Own commits of EARLIER pairs that P already holds: reverse-applied on top,
# newest first, non-test paths only.
for ((i = ${#own[@]} - 1; i >= 0; i--)); do
  c="${own[$i]}"
  git merge-base --is-ancestor "$c" "$P" || continue
  git diff "${c}^" "$c" -- . ":(exclude)${st}" ':(exclude).agents/harness/selftest/' >"${work}/p.diff"
  [ -s "${work}/p.diff" ] || continue
  git -C "${work}/nofix" apply -R --3way "${work}/p.diff" >/dev/null 2>&1 ||
    verdict "NO EVIDENCE: conflict $(git rev-parse --short "$c")"
done
# T_nofix tests = T_fix's runner and topics, whole. Never the parent's runner.
git -C "${work}/nofix" rm -rq --ignore-unmatch -- .agents/harness/selftest >/dev/null
git -C "${work}/nofix" checkout "$fix" -- "$st" .agents/harness/selftest >/dev/null 2>&1 ||
  verdict "NO EVIDENCE: lists"

# <tree> <name>: one list of selftest.sh, one entry per line. Fails when the
# list does not parse or is empty.
c2_list() {
  (cd "$1" && bash -c '
    eval "$(sed -n "/^$1=(/,/^)/p" "$2")" 2>/dev/null || exit 1
    declare -p "$1" >/dev/null 2>&1 || exit 1
    eval "printf \"%s\\n\" \"\${$1[@]}\""' c2 "$2" "$st")
}

# <tree>: keep only the units holding a touched topic (a chain whole), drop
# every other topic file, commit so ls-files agrees.
c2_restrict() {
  local t="$1" all chains keep list kchains want unit c f n
  all="$(c2_list "$t" SELFTEST_TOPICS)" && [ -n "$all" ] || return 1
  chains="$(c2_list "$t" SELFTEST_CHAINS)" || return 1
  keep="$(for want in $topics; do
    unit="$want"
    while IFS= read -r c; do
      case " ${c} " in *" ${want} "*) unit="$c" ;; esac
    done <<<"$chains"
    # shellcheck disable=SC2086  # a unit is a space-separated topic list
    printf '%s\n' $unit
  done | sort -u)"
  list="$(grep -xF -f <(printf '%s\n' "$keep") <<<"$all" || true)"
  kchains="$(while read -r c rest; do
    [ -n "$c" ] && grep -qxF "$c" <<<"$keep" && printf '  "%s"\n' "$c${rest:+ $rest}"
  done <<<"$chains")"
  awk -v list="$list" -v chains="$kchains" '
    /^SELFTEST_TOPICS=\(/ { print; n = split(list, a, "\n")
      for (i = 1; i <= n; i++) if (a[i] != "") print "  " a[i]; skip = 1; next }
    /^SELFTEST_CHAINS=\(/ { print; if (chains != "") print chains; skip = 1; next }
    skip && /^\)/ { skip = 0 }
    !skip { print }' "${t}/${st}" >"${t}/c2.tmp" && mv "${t}/c2.tmp" "${t}/${st}" || return 1
  for f in "$t"/.agents/harness/selftest/*.sh; do
    [ -e "$f" ] || continue
    n="${f##*/}"; n="${n%.sh}"
    grep -qxF "$n" <<<"$list" || git -C "$t" rm -q -- "${f#"${t}/"}" || return 1
  done
  git -C "$t" add -A &&
    git -C "$t" -c user.name=c2 -c user.email=c2@invalid commit -qm c2 --allow-empty
}
for t in fix nofix pre; do
  c2_restrict "${work}/${t}" >/dev/null 2>&1 || verdict "NO EVIDENCE: lists"
done

c2_run() {
  local s=$SECONDS
  (cd "${work}/$1" && timeout 1800 bash "$st") >"${work}/$1.out" 2>&1
  printf '%s: exit %s in %ss, %s\n' "$1" "$?" "$((SECONDS - s))" "$(tail -1 "${work}/$1.out")"
}
c2_run fix >"${work}/fix.line" & c2_run nofix >"${work}/nofix.line" & c2_run pre >"${work}/pre.line" &
wait
cat "${work}/fix.line" "${work}/nofix.line" "${work}/pre.line"

# A case line: "  PASS|FAIL|SKIP <label>", above the runner's FAIL summary.
# The k-th fix line of label L matches the k-th line of the other run that
# is L or starts with "L (" (a FAIL line may carry a diagnostic). Runs are
# told apart by file name: an empty file has no first line.
awk -F'\t' '
  FNR == 1 { done = 0 }
  { f = (FILENAME == ARGV[1] ? 1 : FILENAME == ARGV[2] ? 2 : 3) }
  /^FAIL lines by topic:$/ { done = 1 }
  done { next }
  { if (!match($0, /^  (PASS|FAIL|SKIP) /)) next
    w = substr($0, 3, 4); l = substr($0, 8) }
  f == 1 { n++; lab[n] = l; word[n] = w; next }
  f == 2 { m++; nl[m] = l; nw[m] = w; next }
  { pre[l]++ }
  END {
    for (i = 1; i <= n; i++) {
      k[lab[i]]++; want = k[lab[i]]; got = "MISSING"; seen = 0
      for (j = 1; j <= m; j++)
        if (nl[j] == lab[i] || index(nl[j], lab[i] " (") == 1)
          if (++seen == want) { got = nw[j]; break }
      printf "%s\t%s\t%s\t%s\n", lab[i], word[i], got, (want > pre[lab[i]] ? "new" : "old")
    }
  }' "${work}/fix.out" "${work}/nofix.out" "${work}/pre.out" >"${work}/joined"

# Printed and counted alike: new rows and changed rows. An old case that
# reads the same both ways (a SKIP on this host, a red that predates the
# branch) says nothing about the branch.
awk -F'\t' '$4 == "new" || $2 != $3' "${work}/joined" >"${work}/rows"
cat "${work}/rows"
flips="$(awk -F'\t' '$2 == "PASS" && $3 == "FAIL"' "${work}/rows" | wc -l)"
unread="$(awk -F'\t' '$2 != "PASS" || ($3 != "PASS" && $3 != "FAIL")' "${work}/rows" | wc -l)"
if [ "$flips" -gt 0 ]; then
  printf 'FLIP %d\n' "$flips"
elif [ "$unread" -gt 0 ]; then
  printf 'NO FLIP, %d unread\n' "$unread"
else
  printf 'NO FLIP\n'
fi
