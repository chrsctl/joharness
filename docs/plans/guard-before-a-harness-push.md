---
plan: guard-before-a-harness-push
urgency: normal
agent: opus
effort: high
needs: janitor-apply-skips-a-deleted-branch
requirement: none
issue: 398
scope: shared:joharness.sh, .agents/harness/selftest/guard.sh, shared:.agents/harness/selftest/janitor.sh, shared:.agents/harness/selftest.sh, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md
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
  <sha>]`, registered in header help and `main`. `<verb>` = `janitor`,
  `kill`, `loop`; it selects which checks run (below). One line per check,
  what it compared, in this order; first refusal stops:
  1. `protected` (base) — `<branch>` = base branch (`HANDOVER_BASE_BRANCH`,
     default `main`) = refuse. Name only, no network: runs first so a base
     branch refuses here whatever its refs say.
  2. `live` — `git ls-remote --exit-code --heads origin <branch>`; absent =
     refuse ("gone on origin: already released").
  3. `head` — live sha vs `--expect` (default: `refs/remotes/origin/<branch>`,
     the decision's read); differ = refuse, re-decide.
  4. `claim` — on `head` mismatch: workstream file `session:` and `status:`
     at decision read vs live head (fetch that one ref), printed both sides.
  5. `protected` (pr) — verb `janitor` only: workstream file with `pr:` set
     at live head = refuse. Settled: `kill`/`loop` skip this check. A
     stalled manager with an open PR must stay killable; its KILL/LOOP
     record is a handover write, not a release.
  Exit 0 = all pass; non-zero = first refusal named. Guard never writes:
  no push, no commit, no file in the tree. The `claim` fetch updates only
  `FETCH_HEAD` and the remote-tracking ref — local, and the next read
  anyway.
- `joharness.sh:janitor_apply` — replace the inline live check landed by
  `janitor-apply-skips-a-deleted-branch` with a `guard janitor` call; keep
  its `--force-with-lease` push.
- `.agents/harness/selftest/janitor.sh` — the `gone` assertion matches
  guard's `live` refusal line, which replaces janitor_apply's inline `gone`
  line.
- `.claude/commands/orchestrate.md` — KILL and LOOP records, and any other
  orchestrator workstream-file push present at build time (e.g. the block
  answer write-back from `a-block-names-its-reason`, if that plan landed
  first): run `./joharness.sh guard kill|loop <branch> --expect <sha read
  at fetch>` right before `push` (`kill` for any other orchestrator write). Refusal = no push, report it,
  re-decide next pass; the archive and respawn the record precedes wait for
  the next pass too (a record not pushed = no handover = no replace).
- `.agents/docs/orchestrated.md` — one paragraph: why guard exists, which
  writes call it.
- `.agents/harness/selftest/guard.sh` + `shared:.agents/harness/selftest.sh`
  `SELFTEST_TOPICS` entry — bare-origin fixture: deleted ref, moved head,
  re-claimed workstream file, `pr:` set (verb `janitor`), base branch: each
  refused with its check named; `pr:` set under verb `kill`: passes;
  base branch with a stale local `refs/remotes/origin/main`: refused at
  `protected`, not `head`; untouched live ref: all pass, exit 0.

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

- `./joharness.sh guard janitor main` — first line names `protected`
  (check 1 runs before any network read, so a stale or moved `main` cannot
  refuse at `head` first), exit non-zero.
- `bash .agents/harness/selftest.sh` — guard topic passes; every refusal case
  FAILS if its check is removed from `guard`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS. Selftest does not ship (`sync-to-consumer.sh`
  `CANONICAL_ONLY` / `CANONICAL_ONLY_DIRS`). Consumer check: in a consumer
  after sync, `./joharness.sh guard janitor main` — `protected` refusal,
  exit non-zero; `grep -c 'joharness.sh guard' .claude/commands/orchestrate.md`
  — non-zero.

## Where to look

- `joharness.sh:janitor_apply` — the push path.
- `joharness.sh:main` — subcommand registry; header comment = help text.
- `joharness.sh:gr_fields` — frontmatter reader for `session:`/`status:`/`pr:`.
- `.claude/commands/orchestrate.md` — KILL and LOOP paragraphs.
- `.agents/harness/selftest/janitor.sh` — bare-origin fixture to copy.

## Traps

- Test for fix must FAIL without it; prove guard able to fail AND pass.
- Never `git push --delete`; guard never pushes, commits or edits a file.
- Never skip, disable or quarantine a test to get green.
- `.agents/harness/` names no specific environment.
- No commit under `./joharness.sh protocol-paths`.
