---
workstream: windows-clone-crlf
status: review
branch: claude/windows-clone-crlf-n4tq7c
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
updated: 2026-08-21
next: Deleted in the next commit; PR body links to this blob
---

## Goal

A stock clone of this repo on Windows cannot run `./joharness.sh ci`. Git for
Windows ships `core.autocrlf=true` as its installer default, the repo carries
no `.gitattributes` to override it, so every `.sh` file lands in the worktree
with CRLF endings and shellcheck reports `SC1017 Literal carriage return` on
every line. Measured on a fresh clone: **520 findings, `ci: FAIL`, exit 1** —
before any work is done. The harness tells a session "run ci before opening
the pull request"; on Windows that instruction fails on contact.

## Decisions

- Fix belongs in `.gitattributes`, not in documentation telling contributors
  to set `core.autocrlf=input`. A repo that needs a machine configured before
  its own gate passes has moved the bug, not fixed it.
- `* text=auto` for normalization, then `*.sh text eol=lf` as the override —
  later patterns win, so the specific rule has to come second.
- The shellcheck-missing hint says `apt-get install -y shellcheck`, which is
  wrong on the two platforms most likely to hit it. Made platform-neutral in
  the same change: same class of defect, one line.

## Rejected

- `* text=auto eol=lf` for the whole repo. Wider than the evidence: only the
  shell scripts are consumed by tools that care. Checked whether CRLF also
  breaks the hook's frontmatter parsing — it does not; Git Bash's awk absorbs
  the `\r`, and both LF and CRLF fixtures produced identical hook output.
  Claim dropped rather than asserted.
- Telling `joharness.sh ci` to pass `shellcheck -e SC1017`. That hides the
  symptom and leaves the scripts genuinely CRLF for bash to execute.
- `grep -q $'\r'` as the selftest's CR probe. It reported clean on a genuinely
  CRLF file: Git Bash opens files in text mode and drops the CR before the
  pattern sees it, so the case was green on the one platform it exists for.
  Caught by running it with the fix removed. Byte-counting with
  `tr -dc '\r' | wc -c` is exact everywhere. Same trap as `grep -U`, which
  would have worked here but means something else to BSD grep on Chris's Mac.
- `cmp`-based comparison of stripped against original: correct, but reads the
  file twice in one pipeline and shellcheck answers SC2094. The bar is zero
  findings, so the probe was restructured rather than suppressed.

## Blockers

None.

## Where to look

- `.gitattributes` — the fix; the comment there carries the measurement.
- `joharness.sh:cmd_ci` — where the 520 findings surface, and the install hint.
- `harness/selftest.sh` — the regression case sets `core.autocrlf=true` on a
  scratch repo and re-checks out a committed script.
