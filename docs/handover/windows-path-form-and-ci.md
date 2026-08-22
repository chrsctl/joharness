---
workstream: windows-path-form-and-ci
status: in-progress
branch: claude/windows-path-form-and-ci
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
agent: sonnet
updated: 2026-08-22
next: Normalize both sides of the nesting guard through pwd -P, add a windows-latest CI job
---

## Goal

`harness/selftest.sh` fails 33 cases on Windows, all in the
`sync-to-consumer.sh` block, all from one guard that compares two spellings
of the same directory:

```
ERROR: canonical '/tmp/tmp.9DK3pdhH4s/syncsrc' is nested inside another git
checkout (C:/Users/dnauj/AppData/Local/Temp/tmp.9DK3pdhH4s/syncsrc)
```

`git rev-parse --show-toplevel` answers in Windows form on Git Bash
(`C:/Users/...`); `pwd -P` answers in MSYS POSIX form (`/c/Users/...`). The
strings never match, so the tool concludes every checkout is nested inside
itself and refuses to run. The sync tool is therefore unusable on Windows —
including for its intended job, seeding the harness into a consumer repo.

Second half of the goal: this is the second Windows-only defect in two days
(#12 was CRLF). Both were invisible from macOS because CI only runs
`ubuntu-latest`. A platform nobody tests is a platform that breaks silently,
so the fix ships with the job that would have caught it.

## Decisions

- Normalize by routing the git answer through the same `pwd -P` the other
  side already uses: `cd "$top" && pwd -P`. Both spellings then come from
  one shell in one form. Needs no `cygpath`, no platform branch, and is a
  no-op where the forms already agree.
- CI gains a `windows-latest` job rather than a matrix over the existing
  one. The Linux job installs shellcheck and is the acceptance bar; the
  Windows job exists to answer "does this run on Git Bash", which is a
  different question and should read as a different check.
- Windows job runs `harness/selftest.sh`, not the whole `ci`. shellcheck on
  a Windows runner is a toolchain question already answered on Linux;
  re-asking it there buys nothing and adds an install path to maintain.

## Rejected

- `cygpath -u` on the git answer. Correct on Git Bash, absent everywhere
  else, so it needs a platform branch — and the whole defect is a platform
  branch that was not taken.
- Comparing with `-ef` (same file). Works in bash and reads well, but the
  message on failure still wants a printable path, so both forms are needed
  anyway; normalizing once gives both.
- Leaving CI alone and fixing only the guard. That is how #12 happened:
  fixed the instance, left the class. Two Windows defects in two days is
  the evidence that the class needs a gate.

## Blockers

None.

## Where to look

- `scripts/sync-to-consumer.sh:89` — the guard.
- `.github/workflows/ci.yml` — the new job.
