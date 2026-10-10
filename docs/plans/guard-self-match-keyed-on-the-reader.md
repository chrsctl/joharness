---
plan: guard-self-match-keyed-on-the-reader
urgency: normal
agent: opus
effort: medium
needs: none
requirement: none
issue: none
scope: .agents/harness/pretool-bash-guard.sh, .agents/harness/selftest/pretool-bash-guard.sh
---

## Goal

`pretool-bash-guard.sh` refuses a wait whose condition matches its own
command line — but only when it is spelled `pgrep -f`/`pkill -f` and sits in
a `while`/`until` loop. A consumer hit the same trap spelled
`for i in $(seq 1 N); do n=$(ps -e -o args | grep -cE "<pat>"); ...; done`
and the guard allowed it: wrong reader, wrong opener. The answer to "what
should the deny be keyed on, and which openers reach it" is already decided
and written in the guard's header, beside `proc_re`/`full_re` ("SELF-MATCH:
DECIDED, NOT YET BUILT"). This plan builds exactly that, and nothing else.

## Scope

- `.agents/harness/pretool-bash-guard.sh`:
  - Replace `proc_re`/`full_re` with one predicate that fires when a loop's
    span reads full command lines from the process table, any of:
    - `pgrep`/`pkill` with `f` ANYWHERE in a short-option cluster
      (`-f`, `-fl`, `-lf`, `-f"pat"`, `-fc`) or `--full`, within the same
      simple command (no `;`, `&`, `|` between the tool and the flag);
    - `ps` (with or without arguments) piped straight into `grep`/`egrep`;
    - a `/proc/…/cmdline` path.
  - Exempt the idiom that does NOT match itself: a quoted pattern opening
    with a one-character bracket class (`"[b]ash selftest.sh"`,
    `'[p]ython3 x'`). Name it in the self-match deny as the remedy.
  - Reach: run the self-match branch for `for NAME in`, `for ((` and
    `select` openers in reader B. The BOUND check stays `while`/`until`
    only — for the other openers `judge` returns after the self-match test.
  - Keep the order: self-match first, bounded or not.
  - Rewrite the header's "DECIDED, NOT YET BUILT" block as the record of what
    was built: keep its measurements, drop "not yet built".
- `.agents/harness/selftest/pretool-bash-guard.sh` — one `pbg_denied` or
  `pbg_allowed` per row in Acceptance below that the topic does not already
  pin. Every existing case stays as it is.

## Out of scope

- The quoted-counter defect (`while [ "$n" -gt 0 ]` read as unbounded,
  `[ $n -gt 0 ]` read as bounded — `count_re` meets `\"`, never `"`). Real,
  same function, different question; a separate plan.
- Teaching the bound check to read `for`/`select`. Measured: seven pinned
  allows flip to DENY, five of them the prose cases a previous plan existed
  to close.
- Reader A (`start_re`). Reach goes through reader B only; above 8 KB B does
  not run and a `for` self-match stays allowed. Say so in the header; do not
  widen A.
- Any other reader of command lines (`pidof`, `pgrep` without `-f`, `top`,
  `awk` over `ps`). They test names, or are not seen; an unlisted reader is
  an allow, same doctrine as failing open.
- `handover-guard.sh`, `.claude/settings.json` (core path), the deny's two
  bound spellings.

## Acceptance

Every row: payload `{"tool_name":"Bash","tool_input":{"command":<cmd>}}` piped
to `bash .agents/harness/pretool-bash-guard.sh`. DENY = exit 2 with
`matches ITSELF` on stderr; ALLOW = exit 0, nothing on stderr. Drive them
from a file through a runner — the guard is live on the session's own Bash
and refuses a command line that carries one of these loops.

| cmd | wanted |
|---|---|
| `for i in $(seq 1 20); do n=$(ps -e -o args \| grep -cE "python3 (platform\|apps\|tools)/"); if [ "$n" -gt 0 ]; then sleep 15; else break; fi; done` | DENY |
| `timeout 600 bash -c 'until [ "$(ps -e -o args \| grep -c "python3 platform/")" -eq 0 ]; do sleep 15; done'` | DENY |
| `timeout 600 bash -c 'while ps aux \| grep -q "python3 platform/tests"; do sleep 10; done'` | DENY |
| `timeout 300 bash -c 'until ! pgrep -fl "bash selftest.sh"; do sleep 3; done'` | DENY |
| `timeout 300 bash -c 'until ! pgrep -f"bash selftest.sh"; do sleep 3; done'` | DENY |
| `timeout 300 bash -c 'until ! grep -l "python3 platform/" /proc/*/cmdline; do sleep 3; done'` | DENY |
| `for i in $(seq 1 20); do pgrep -f "python3 platform/" \|\| break; sleep 5; done` | DENY |
| `for ((i=0; i<20; i++)); do ps -e -o args \| grep -c "python3 x"; sleep 15; done` | DENY |
| `select x in a b; do pgrep -f "python3 platform/"; sleep 5; done` | DENY |
| `timeout 300 bash -c 'until ! pgrep -f "[b]ash selftest.sh"; do sleep 3; done'` | ALLOW |
| `timeout 600 bash -c 'while ps aux \| grep -q "[p]ython3 platform/tests"; do sleep 10; done'` | ALLOW |
| `timeout 300 bash -c 'until ! pgrep bash; do sleep 3; done'` | ALLOW |
| `for f in a b c; do echo $f; sleep 1; done` | ALLOW |
| `ps aux \| grep python3` | ALLOW |
| `i=0; while [ $i -lt 5 ]; do pgrep -l bash; sleep 1; i=$((i+1)); done` | ALLOW |

(`\|` in the table is a literal `|` in the command.)

- `./joharness.sh verify` — `0 failed`; the topic's existing 80 cases
  unchanged, the perf row still at 0 external commands.
- `./joharness.sh ci` — `ci: pass`.
- The guard's diff reaches every consumer at its next sync: these are the
  rows a consumer's session meets, so they are the bar.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:judge` — the self-match branch and
  the bound check after it.
- `.agents/harness/pretool-bash-guard.sh:proc_re` — the predicate this
  replaces; the "SELF-MATCH: DECIDED" header block above it holds the
  measurements.
- `.agents/harness/pretool-bash-guard.sh:tkw` — reader B fills it only for
  `while`/`until`; the skip on empty `tkw` is why a `for` is never judged.
- `.agents/harness/selftest/pretool-bash-guard.sh:pbg_denied` — the helpers.

## Traps

- Capture `BASH_REMATCH` before ANY later `[[ =~ ]]`. A failed match unsets
  it; read under `set -u` that is exit 1, which this event reads as ALLOW.
  Measured on the scratch build that priced this plan: testing the bracket
  exemption before capturing the tool name turned every self-match into a
  silent allow.
- NO FORKS: builtins only, or the perf row reds.
- Never skip, disable or quarantine a pinned case to get green.
- The guard ships to consumers: no consumer repository, plan or item name in
  it (`.agents/docs/consumer-repos.md`).
