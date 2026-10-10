---
workstream: guard-self-match-keyed-on-the-reader
status: in-progress
branch: guard-self-match-keyed-on-the-reader
pr: none
plan: guard-self-match-keyed-on-the-reader
issue: none
session: https://claude.ai/code/session_01BVQg9yj1cxLrFRYNqwgz3M
agent: opus
updated: 2026-10-10
next: ci green on r2-r4 fixes, then retire plan + workstream file, PR, merge
---

## Goal

Guard denies a wait loop whose reader matches its own command line under
any reader (pgrep/pkill -f, ps | grep, /proc/*/cmdline) and any loop opener
(while, until, for, select) — plan guard-self-match-keyed-on-the-reader.

## Decisions

- No worker fan-out: one guard file plus its selftest, both shared and
  judgement-heavy regex; sequential by the plan's own scope.
- Exemption scope = any word of the reader's own simple command (pgrep) or
  the first grep stage's args (ps | grep, grep over /proc glob), quoted and
  opening `[c]`. Picking out "the pattern" positionally needs pgrep's
  option table; a bracket outside that command still exempts nothing.
- `for`/`select` reach judge() via tkw in reader B; judge returns after the
  self-match test for them, so the sleep test still precedes it.
- Acceptance rows run from a payload file (scratch runner): 24/24 on this
  guard, 15/24 wrong on origin/main's (2026-10-10).

## Rejected

- Patching via a shell heredoc: the live guard read the patch text as a
  loop and denied it. Edits go through files.

## Review

- r1: selftest structure check red — `bash .agents/harness/selftest.sh`
  (2026-10-10) printed 2497 passed, 1 failed: "this tree couples no harness
  file to a layer beyond the carve-out", naming the `docker ps` row and
  comment. Switched both to `podman ps`, the plan's other spelling of the
  same case. (fixed)
- r2: (verifier) regression: `while sudo|env|command|timeout 5 pgrep -f`
  and `/usr/bin/pgrep -f` exit 0 on 781a82e3, 2 on origin/main (probe.py
  payloads, 2026-10-10) — rpos took no prefix word or path. rpos now reaches
  through sudo/env/command/exec/nice/nohup/timeout N and a path; all five
  exit 2/SELF. (fixed)
- r3: (verifier) cost: 238 nested `for ... pgrep -l x;` loops, 7.9 KB, took
  8.15 s vs main 0.21 s (hook timeout 10 s) — selfmatch re-scanned each
  nested span. B now scans the command once and looks each loop's range
  up: 0.54 s (perf2.py, 2026-10-10). Pinned as a <= 4 s selftest row. (fixed)
- r4: (verifier) `ps -eopid,args | grep` allowed (onepid_re unanchored) and
  a `grep -v grep` in another `$(...)` exempted the reader (look-ahead did
  not stop at `)`). Both exit 2 now; pinned. (fixed)
- r5: (verifier) docker-to-podman row: the plan's table names `docker ps`;
  the selftest pins `podman ps`, which the plan's Scope names as the same
  case (r1). (no change)
- r6: (verifier) `ps -C nginx | grep`, `ps -e -o comm | grep`, `ps -e |
  grep` print no command lines but are denied — the plan's Scope says "ps
  piped into grep" with no format test. (wontfix: in-scope design as
  specified; a format test is a follow-up, named in the PR body)
- r7: (verifier) a reader in a `while true` body (monitoring) is denied
  with "the loop never exits" text. Main denied `pgrep -f` in a body the
  same way; plan says keep the while/until text. (wontfix: as specified)
- r8: (verifier) quoted text (`echo "pgrep -f is bad"`) and a bare
  `/proc/*/cmdline` glob (`ls`, a `for` list) deny under `for`. Quote as
  command position is main's breadth for while/until; the glob is the
  plan's reader as written. (wontfix: false deny is the side this text
  reader errs on; named in the PR body)
- r9: (verifier) a bracket on the first grep stage exempts a later
  unbracketed stage; `fgrep` unlisted. (wontfix: contrived; fgrep is out
  of the plan's reader list)

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:judge` — self-match branch.
