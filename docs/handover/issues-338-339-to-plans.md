---
workstream: issues-338-339-to-plans
status: in-progress
branch: claude/issues-338-339-to-plans
pr: none
plan: none
issue: 338
session: https://claude.ai/code/session_018Bhrz7Uhy2ypK1sVw779nP
agent: opus
updated: 2026-10-10
next: Retire this file, open PR, merge when checks green
---

## Goal

Human ask: "Convert issues to tasks." Of 22 open issues, 20 already have a
plan or an earlier decomposition (checked by grepping `docs/plans/` and
`main`'s log for each number). #338 (guard counts a `.mcp.json` server as
abandoned background work) and #339 (no route for a harness finding that
surfaces after the retire commit) have none. Decompose each into a plan.

## Decisions

- One plan per issue: different files, different readers, no shared result.
- `issue:` holds one number (ci rejects a list), so it claims #338; #339 is
  claimed by its plan `late-finding-has-an-issue-route` once that lands.
- #338 discriminator: count only shell-rooted direct children of the agent.
  Measured 2026-10-10 here: a `run_in_background` job is `bash` under the
  agent; #338's server is `node` under it. Not `.mcp.json` matching — `comm`
  is the bare binary, so that needs full command lines plus JSON in shell.
- #339: docs-only floor; the optional `upstream --issue` command left out.

## Rejected

- Re-planning #251, #254, #258: decomposed and answered on `main` already
  (`.agents/docs/orchestrated.md`, `.agents/docs/feedback.md`); no new plan.

## Review

- r1: (verifier) #338 `etimes` window excludes the real-tree fixture's own leftover (agent and `sleep` both etimes 0), so the existing case reds with no instruction (fixed — window dropped; fixture now `bash -c 'sleep 300; :'`, the measured real shape)
- r2: (verifier) new fact text dropped "background", so five refutes on `background process(es)` would pass whether or not the guard fires (fixed — text keeps both pinned substrings)
- r3: (verifier) `spawn_window=30` had no measurement; pre-warmed agent (`--preload …spare.sock`) is minutes older than its servers, window never fires (fixed — shell-root rule instead)
- r4: (verifier) window hides a real wait loop started in an unattended session's first seconds (fixed — same, shell rule has no time component)
- r5: (verifier) `ps` lacking `etimes` makes the one read fail and the guard silent (fixed — no new column)
- r6: (verifier) fact text held `;`, which `add_fact` uses as separator (fixed)
- r7: (verifier) `expect "1 process(es)"` also matches 11; SHIPS check not runnable (fixed — anchored grep, check names the output to read)
- r8: (verifier) #339 "no open pull request" is false after the retire commit, the consumer's PR is open (fixed — "no open canonical pull request", said why)
- r9: (verifier) #339 plan denied that "a repo the child does not own" applies to an issue; it does (fixed — argued as difference: no diff, merges nothing)
- r10: (verifier) #339 silent on unattended modes (fixed — every mode, one issue per session, dedupe search first)
- r11: (verifier) both #339 acceptance greps already passed on `main` (fixed — section-bounded `sed | grep`, 0 on `main` at 944d0e8, measured 2026-10-10)
- r12: (verifier) round 2: new leftover `bash -c 'sleep 300; :'` is two processes, so the existing `expect "1 background process(es)…"` reds 5/5 runs (fixed — anchored `[12]` match, race named)
- r13: (verifier) r7 anchoring applied to the new case only, existing substring still matches 11 (fixed — same line as r12)
- r14: (verifier) process-group kill unworkable for a non-interactive job; `kill` before `pkill -P` orphans `sleep` (fixed — `pkill -P "$bg"; kill "$bg"`, order stated)
- r15: (verifier) macOS `comm` is a full path (`/bin/zsh`), so the shell match counts 0 for ever (fixed — basename and leading `-` stripped first)
- r16: (verifier) a background command that `exec`s escapes the count; hook/statusLine shells still counted; other shells unlisted (fixed — all named as accepted costs in the header comment)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — background-child count (#338).
- `.agents/docs/feedback.md` — "Inline or routed" (#339).
