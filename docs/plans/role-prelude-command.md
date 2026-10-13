---
plan: role-prelude-command
urgency: normal
agent: opus
effort: xhigh
needs: scout-reviewer-trigger, scout-approval-by-comment, scout-budget-by-count, clerk-fetch-before-inflight
requirement: none
issue: none
scope: shared:joharness.sh, shared:.claude/commands/clerk.md, shared:.claude/commands/scout.md, shared:.claude/commands/curate.md, shared:.claude/commands/conduct.md, shared:.agents/docs/orchestrated.md, .agents/harness/selftest/role.sh
---

## Goal

Every role command opens with the same ritual written out in prose:
`authority` must read VERIFIABLE; the role's report must show nothing IN
FLIGHT; cut a branch from fresh `origin/main` under the role's naming rule;
push the claim; `git fetch --prune` every ref; re-read the report; carry on
only when your row is the one in flight (the twin check, with a tiebreak);
and at the end, the retire commit. Counted 2026-10-13: `authority` cited in
11 command files, the twin check in 3 roles, `fetch --prune` in 5; the scout's
copy carries 14 stop conditions and 10 `Never` bullets. Both harness defects
found that day sat in prelude prose: the clerk's reader probe (#459) and
the scout's §0.4 (#460). A model re-deriving procedure from prose per pass
is slower, costlier and less exact than one tested function. Make the
ritual a command that prints `GO` or `STOP: <reason>`, and leave the role
commands the judgement: what to read, what to produce.

## Scope

- `joharness.sh` — `cmd_role <clerk|scout|curate|conduct> [--retire]`:
  1. `authority` — not VERIFIABLE = `STOP: authority <verdict>`.
  2. the role's own report (`clerk`, `scout`, `curate`, `conduct`) — IN
     FLIGHT by another branch = `STOP: IN FLIGHT <branch>`; `off`,
     `UNREADABLE`, `NO BRIEF` where the role has them = `STOP: <line>`.
  3. branch: fetched `origin/main`, the role's naming rule
     (`clerk-<UTC date>` with `-b`, `-c` suffixes; `scout-<UTC date>`;
     `curate-<stamp>`; `conduct-<stamp>`), `git checkout -b`.
  4. claim: for roles with a workstream file (scout, curate) write it from
     `.agents/docs/handover/TEMPLATE.md` with the role's frontmatter and
     commit; clerk and conduct push the empty branch after their first
     commit, so for them step 4 is `GO` with the branch name and no push.
  5. push (`-u origin`), `git fetch --prune origin '+refs/heads/*:refs/remotes/origin/*'`
     (FAILED = `STOP: fetch failed`), the role's report again, the twin rule
     (scout: exactly one IN FLIGHT row, yours; clerk: yours sorts first by
     name among those in flight; conduct and curate: their stated rule).
  6. prints `GO <branch>` or `STOP: TWIN <other>` and, on STOP after a push,
     performs the retire (delete the claim file, commit, push) so the
     caller has nothing to undo.
  `--retire`: the retire commit and push for the current branch's role file.
  Every line it prints is one the role command used to spell out, so the
  report stays the same shape.
- `.claude/commands/clerk.md`, `scout.md`, `curate.md`, `conduct.md` — §0
  and §1 replaced by: run `./joharness.sh role <name>`; `STOP:` = report
  the line and exit; `GO` = continue at §2. The retire step becomes
  `./joharness.sh role <name> --retire`. Judgement stays prose: the clerk's
  gates, the scout's ceiling and reading rules, conduct's sampling.
- `.agents/docs/orchestrated.md` — the role table's "starts" column names
  the command; one paragraph on why the prelude is a command (the counts
  above, dated).
- `.agents/harness/selftest/role.sh` — fixtures: authority UNVERIFIED →
  `STOP: authority`; a twin branch already in flight → `STOP: TWIN` and the
  claim file retired; clean → `GO` and the branch pushed to the fixture
  remote with the right name; `--retire` deletes the file and pushes.

## Out of scope

- The orchestrator and manager preludes: the orchestrator holds no claim,
  the manager's is `/manage`'s own and plan-specific.
- Any gate that reads GitHub (the clerk's scout gate, the author gate):
  judgement, and `joharness.sh` reads no GitHub.
- Changing any role's naming rule, cadence or tiebreak: the command encodes
  what the four commands say after the plans in `needs:` have landed.

## Acceptance

- `bash .agents/harness/selftest.sh` — `role.sh`'s four cases pass;
  `./joharness.sh ci` — `ci: pass`.
- `wc -l .claude/commands/clerk.md .claude/commands/scout.md .claude/commands/curate.md .claude/commands/conduct.md`
  — each shorter than on `origin/main` at the plan's start; quote both
  counts in the pull request.
- `grep -c 'fetch --prune' .claude/commands/*.md` — `0` outside `who.md`.
- Plan `ci` calls SHIPS: the consumer check is the next gx clerk or scout
  pass's report opening with the command's `GO`/`STOP` line.

## Where to look

- `.claude/commands/clerk.md:## 0. Preconditions` and `## 1. Branch` — the
  clerk's copy, with the name tiebreak.
- `.claude/commands/scout.md:## 0. Preconditions` and `## 1. Claim` — the
  scout's copy, with the twin rule and the retire.
- `.claude/commands/conduct.md` and `.claude/commands/curate.md` — the
  other two copies.
- `joharness.sh:cmd_authority`, `joharness.sh:cmd_clerk`,
  `joharness.sh:cmd_scout`, `joharness.sh:scout_walk` — what the command
  calls.
- `.agents/docs/handover/TEMPLATE.md` — the claim file shape.

## Traps

- Research first: every prelude is read AFTER the four plans in `needs:`
  have changed it; the command encodes the text on `origin/main` that day.
- Never `push -f`; a STOP after a push retires by a new commit.
- Never checkout -B over a pushed branch: a name collision adds a suffix.
- Interface signatures are not yours: the role reports' lines keep their
  wording, the command reads them as the roles do.
