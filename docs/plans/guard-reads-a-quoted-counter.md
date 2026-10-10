---
plan: guard-reads-a-quoted-counter
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: .agents/harness/pretool-bash-guard.sh, .agents/harness/selftest/pretool-bash-guard.sh
---

## Goal

`pretool-bash-guard.sh` denies the shellcheck-correct bounded loop and
allows the unquoted one. `n=1; while [ "$n" -gt 0 ]; do sleep 10; done` is
DENIED as unbounded; the same line with `$n` unquoted is ALLOWED. A gate
that denies the correct spelling of its own remedy teaches sessions to
write the worse one. Found while settling the research node
a-self-match-the-guard-cannot-see (fixtures U and V, 2026-10-10).

Cause: `count_re` allows one optional `"` after the variable, but the guard
never unescapes the JSON payload — it replaces only `\n` and `\t` — so the
character after `$n` reaches the regex as `\`, then `"`.

## Scope

- `.agents/harness/pretool-bash-guard.sh` — `count_re` accepts the
  escaped quote (`\"`) after the variable name, and a quoted `"$n"` / `"${n}"`
  before the operator. Comment above `count_re` says why: the payload is
  read escaped.
- `.agents/harness/selftest/pretool-bash-guard.sh` — one `pbg_allowed` for
  the quoted counter, one `pbg_denied` that a quoted test on the world
  (`until [ "$(grep -c x /tmp/f)" -gt 0 ]; do sleep 5; done`) is still
  denied.

## Out of scope

- Unescaping the payload in general (`\"` → `"` everywhere). Every other
  pattern in the guard was measured against the escaped text; changing it
  under them is a different plan.
- The self-match predicate and `for`/`select` reach — plan
  guard-self-match-keyed-on-the-reader.

## Acceptance

Payloads through a file and a runner (the guard is live on the session's
own Bash):

- `n=1; while [ "$n" -gt 0 ]; do sleep 10; done` — exit 0, nothing on stderr.
- `n=1; while [ "${n}" -gt 0 ]; do sleep 10; done` — exit 0.
- `until [ "$(grep -c x /tmp/f)" -gt 0 ]; do sleep 5; done` — exit 2.
- `./joharness.sh verify` — `0 failed`, existing cases unchanged, perf row
  at 0 external commands.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:count_re` — the pattern.
- `.agents/harness/pretool-bash-guard.sh:judge` — where it is read.

## Traps

- NO FORKS: builtins only.
- Never skip, disable or quarantine a pinned case.
- Both plans touch the guard: whichever merges second reconciles.
