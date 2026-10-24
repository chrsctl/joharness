---
plan: guard-one-shot-self-kill
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .agents/harness/pretool-self-kill-guard.sh, .agents/harness/selftest/pretool-self-kill-guard.sh, shared:.agents/harness/selftest.sh
---

## Goal

`pretool-bash-guard.sh` denies a `pgrep -f` / `pkill -f` self-match only inside
a `while`, `until`, `for` or `select` loop. A one-shot
`pkill -f 'timeout 1700 ./joharness.sh'` (branch manage/dispatch-held-merged-pr,
2026-10-24) matched its own shell, killed it with exit 144, and took the
backgrounded `ci; verify` run down with it. The rule against it was already in
`.agents/harness/AGENTS.md` (Loop step 5) and was broken anyway. Deny the
one-shot kill too.

## Scope

- NEW `.agents/harness/pretool-self-kill-guard.sh` — a PreToolUse Bash hook,
  same contract as `pretool-bash-guard.sh`: exit 2 with the reason on stderr
  = deny, exit 0 otherwise, fails open, no forks. Deny, in command position
  (reuse `pretool-bash-guard.sh`'s `rpos` construction, copied, not sourced):
  - `pkill` with `f` in a short-option cluster or `--full`;
  - `kill` whose arguments hold `$(pgrep …-f…)` or a backtick `pgrep -f`.
  Exempt the bracket-class pattern (`"[t]imeout 1700"`), as the loop check
  does, and name it in the deny as the remedy.
- NEW `.agents/harness/selftest/pretool-self-kill-guard.sh` — fixtures:
  the 2026-10-24 command verbatim (deny), bracket-exempt (allow),
  `pkill -x name` (allow), `pgrep -f pat` alone (allow), `kill $(pgrep -f pat)`
  (deny), a heredoc body holding `pkill -f` (allow), bad stdin (allow), and a
  0-external-commands perf row as `pretool-bash-guard.sh`'s topic has.
- `.agents/harness/selftest.sh` — list the new topic.
- Human remainder: registering the hook is a `.claude/settings.json` edit,
  a core path. Open it as the `human/guard-one-shot-self-kill` pull request,
  labelled `human-review` (`.claude/commands/manage.md` §2, ref § Human
  remainder). It holds one new `Bash` PreToolUse entry with the same
  `if bash -n S; then bash S; else exit 0; fi` wrapper `pretool-bash-guard.sh`'s
  entry uses.

## Assumptions

- A1: the loop-only check is `pretool-bash-guard.sh`'s `pg_re` reader, reached only from a loop condition — evidence: `.agents/harness/pretool-bash-guard.sh:pg_re` and its SELF-MATCH comment — confidence: high
- A2: a manager may not edit a registered hook — evidence: `.claude/commands/manage.md` §2 "Hook work" — confidence: high
- A3: the heredoc-body stripping `pretool-bash-guard.sh` does can be copied without a fork — evidence: `.agents/harness/pretool-bash-guard.sh` comment "being written may hold `while`, `sleep` and `pgrep -f` as text" — confidence: medium

## Out of scope

- Editing `pretool-bash-guard.sh` or any hook `.claude/settings.json` registers.
- `pgrep -f` used alone outside a loop (wrong count, no harm).
- `ps | grep` readers outside loops.

## Acceptance

- `./joharness.sh ci` — `ci: pass`; the new topic's cases among the passes.
- `printf '%s' '{"tool_input":{"command":"pkill -f '"'"'timeout 1700 ./joharness.sh'"'"'"}}' | bash .agents/harness/pretool-self-kill-guard.sh; echo $?` prints a reason naming the bracket remedy, then `2`.
- The 2026-10-24 fixture is denied by the new hook and allowed by `pretool-bash-guard.sh` (shows the gap is real).
- `human/guard-one-shot-self-kill` pull request open, labelled `human-review`, its `ci` run green.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:rpos` — command position.
- `.agents/harness/pretool-bash-guard.sh:pg_re` — the pgrep/pkill reader and bracket exemption.
- `.agents/harness/selftest/pretool-bash-guard.sh` — how the topic feeds stdin and checks exit 2.
- `.claude/settings.json` — the `Bash` PreToolUse entry to copy (read only; the edit is the human PR's).
- `.claude/commands/manage.md` — §2 Hook work, human remainder.

## Traps

- Never edit a hook `.claude/settings.json` registers; build unregistered, fixtures only.
- No commit to `.claude/settings.json` outside the `human/guard-one-shot-self-kill` worktree.
- The hook sits in front of every Bash call once registered: fail open on anything it cannot read.
- Test for a fix must FAIL without it.
