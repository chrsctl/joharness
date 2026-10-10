---
plan: guard-before-a-harness-push
urgency: normal
agent: opus
effort: high
needs: janitor-apply-skips-a-deleted-branch
requirement: none
issue: 398
scope: shared:joharness.sh, .agents/harness/selftest/guard.sh, shared:.agents/harness/selftest.sh, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md
---

## Goal

Harness writes are decided on one read and pushed later, after the read
stopped being true (#397: janitor re-created a deleted branch). One shared
check, called right before every harness push onto a branch the session does
not own, makes "re-read live state before writing" a property of the write
path instead of a rule each author remembers (`.agents/docs/feedback.md`,
graduation).

## Scope

- `joharness.sh` — new report subcommand `guard <verb> <branch> [--expect
  <sha>]`, read-only, registered in header help and `main`. `<verb>` = label
  only (`janitor`, `kill`, `loop`). One line per check, what it compared:
  - `live` — `git ls-remote --exit-code --heads origin <branch>`; absent =
    refuse ("gone on origin: already released").
  - `head` — live sha vs `--expect` (default: `refs/remotes/origin/<branch>`,
    the decision's read); differ = refuse, re-decide.
  - `claim` — on `head` mismatch: workstream file `session:` and `status:`
    at decision read vs live head (fetch that one ref), printed both sides.
  - `protected` — base branch (`HANDOVER_BASE_BRANCH`, default `main`) or a
    workstream file with `pr:` set at live head = refuse.
  Exit 0 = all pass; non-zero = first refusal named.
- `joharness.sh:janitor_apply` — replace the inline live check landed by
  `janitor-apply-skips-a-deleted-branch` with a `guard janitor` call; keep
  its `--force-with-lease` push.
- `.claude/commands/orchestrate.md` — KILL and LOOP records: run
  `./joharness.sh guard kill|loop <branch> --expect <sha read at fetch>`
  right before `push`; refusal = no push, report it, re-decide next pass.
- `.agents/docs/orchestrated.md` — one paragraph: why guard exists, which
  writes call it.
- `.agents/harness/selftest/guard.sh` + `shared:.agents/harness/selftest.sh`
  `SELFTEST_TOPICS` entry — bare-origin fixture: deleted ref, moved head,
  re-claimed workstream file, `pr:` set, base branch: each refused with its
  check named; untouched live ref: all pass, exit 0.

## Out of scope

- `cleanup --apply`, `curate --apply`: edit local tree only, never push
  (`cmd_cleanup` uses `git rm`; `cmd_curate` no push). Issue's claim did not
  hold for them.
- Versioned wake message (#398 §2): plan
  `orchestrator-wake-carries-harness-version`.
- Fetch pruning (#398 §3): `cmd_dispatch` already fetches `--prune`; the
  orchestrate step lands in `janitor-apply-skips-a-deleted-branch`.
- A `core path` protected check: a ref is not a path. Core paths stay the
  Stop guard's job.

## Acceptance

- `./joharness.sh guard janitor main` — prints `protected` refusal, exit
  non-zero.
- `bash .agents/harness/selftest.sh` — guard topic passes; every refusal case
  FAILS if its check is removed from `guard`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS: consumer orchestrators call it; guard selftest runs in their
  `verify`.

## Where to look

- `joharness.sh:janitor_apply` — the push path.
- `joharness.sh:main` — subcommand registry; header comment = help text.
- `joharness.sh:gr_fields` — frontmatter reader for `session:`/`status:`/`pr:`.
- `.claude/commands/orchestrate.md` — KILL and LOOP paragraphs.
- `.agents/harness/selftest/janitor.sh` — bare-origin fixture to copy.

## Traps

- Test for fix must FAIL without it; prove guard able to fail AND pass.
- Never `git push --delete`; guard never writes.
- Never skip, disable or quarantine a test to get green.
- `.agents/harness/` names no specific environment.
- No commit under `./joharness.sh protocol-paths`.
