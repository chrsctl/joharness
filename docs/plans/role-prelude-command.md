---
plan: role-prelude-command
urgency: normal
agent: opus
effort: xhigh
needs: scout-reviewer-trigger, clerk-fetch-before-inflight, shallow-clone-reaches-authority
requirement: none
issue: none
scope: shared:joharness.sh, shared:.claude/commands/clerk.md, shared:.claude/commands/scout.md, shared:.claude/commands/curate.md, shared:.claude/commands/conduct.md, shared:.agents/docs/orchestrated.md, .agents/harness/selftest/role.sh, shared:.agents/harness/selftest.sh
---

## Goal

Every role command opens with the same ritual written out in prose:
`authority` must read VERIFIABLE; the role's report must show nothing IN
FLIGHT; cut a branch from fresh `origin/main` under the role's naming rule;
push; `git fetch --prune` every ref; re-read the report; carry on only when
your row is the one in flight (the twin check, with a tiebreak); and at the
end, the retire commit. Counted 2026-10-13 on `origin/main`: `authority` on
11 lines in 8 command files, the twin check in 3 roles, `fetch --prune` in
5 files; the scout's copy carries 14 stop conditions and 10 `Never`
bullets. Both harness defects found that day sat in prelude prose: the
clerk's reader probe (#459) and the scout's §0.4 (#460). A model
re-deriving procedure from prose per pass is slower, costlier and less exact
than one tested function. Make the ritual a command that prints `GO` or
`STOP: <reason>`, and leave the role commands the judgement: what to read,
what to produce.

## Scope

- `joharness.sh` — `cmd_role <clerk|scout|curate|conduct> [--session <url>] [--agent <tier>] [--twin|--retire]`:
  - default (the start): (1) `authority`; not VERIFIABLE = `STOP: authority
    <verdict>`, after the one unshallow-and-retry
    `shallow-clone-reaches-authority` adds; (2) the role's own report
    (`clerk`, `scout`, `curate`, `conduct`); IN FLIGHT by another branch =
    `STOP: IN FLIGHT <branch>`; `off`, `UNREADABLE`, `NO BRIEF` where the
    role has them = `STOP: <line>`; (3) `git fetch origin main`, the branch
    under the role's naming rule as its command states it on `origin/main`
    the day this builds (`clerk-<UTC date>` with `-b`, `-c` suffixes;
    `scout-<UTC date>`; `curate-<stamp>`; `conduct-<stamp>`),
    `git checkout -b`; (4) for scout and curate, which claim by workstream
    file: write it from `.agents/docs/handover/TEMPLATE.md` with the role's
    frontmatter — `session:` and `agent:` from the flags, since only the
    caller knows them; missing flag = `STOP: --session and --agent are
    required for <role>` — commit, push `-u`, then the twin check below;
    for clerk and conduct, which claim by their first content push, stop
    at (3) and print `GO <branch>` — their twin check is the second form.
  - `--twin` (clerk, conduct, after their first push; scout and curate run it
    inside the start): `git fetch --prune origin '+refs/heads/*:refs/remotes/origin/*'`
    (FAILED = `STOP: fetch failed`), the role's report again, the role's
    rule — scout: exactly one IN FLIGHT row and it is yours; clerk: yours
    sorts first by name among those in flight; conduct: its stated rule;
    curate: none, the flag is refused — then `GO` or `STOP: TWIN <other>`;
    on STOP for a role that pushed a claim file, the retire below runs
    first so the caller has nothing to undo.
  - `--retire`: delete the current branch's own claim file, commit, push.
- `.claude/commands/clerk.md`, `scout.md`, `curate.md`, `conduct.md` — their
  §0 and §1 become: run `./joharness.sh role <name> …`; `STOP:` = report the
  line and exit; `GO` = continue at the first judgement step; the twin
  paragraph becomes `./joharness.sh role <name> --twin` where the role has
  one; the retire becomes `--retire`. Judgement stays prose: the clerk's
  gates, the scout's ceiling and reads, conduct's sampling.
- `.agents/docs/orchestrated.md` — the role table's "starts" column names
  the command; one paragraph with the counts above, dated.
- `.agents/harness/selftest/role.sh`, registered in `SELFTEST_TOPICS` in
  `.agents/harness/selftest.sh` — fixtures: authority UNVERIFIED →
  `STOP: authority`; scout with a twin in flight → `STOP: TWIN` and the
  claim file retired on the fixture remote; clean scout → `GO` with the
  claim pushed under the right name and frontmatter; clerk `--twin` with a
  same-day sibling sorting first → `STOP: TWIN`; `--retire` deletes the
  file and pushes.

## Out of scope

- The orchestrator and manager preludes.
- Any gate that reads GitHub (the clerk's scout gate, the author gate):
  judgement, and `joharness.sh` reads no GitHub.
- Changing any role's naming rule, cadence or tiebreak: the command encodes
  the four commands' text after the plans in `needs:` have landed.
- `orchestrate.md`'s own `git fetch --prune`: a different role.

## Acceptance

- `bash .agents/harness/selftest.sh` — `role.sh`'s five cases pass;
  `./joharness.sh ci` — `ci: pass`.
- `wc -l .claude/commands/clerk.md .claude/commands/scout.md .claude/commands/curate.md .claude/commands/conduct.md`
  — each shorter than on `origin/main` at the plan's start; quote both.
- `grep -c 'fetch --prune' .claude/commands/clerk.md .claude/commands/scout.md .claude/commands/curate.md .claude/commands/conduct.md` — `0` each.
- Plan `ci` calls SHIPS: the consumer check is the next gx clerk or scout
  pass's report opening with the command's `GO`/`STOP` line.

## Where to look

- `.claude/commands/clerk.md:## 0. Preconditions` and `## 1. Branch` — the
  clerk's copy: twin check after the first push, name tiebreak.
- `.claude/commands/scout.md:## 0. Preconditions` and `## 1. Claim` — the
  scout's copy: claim file, twin rule, retire.
- `.claude/commands/conduct.md` and `.claude/commands/curate.md` — the
  other two; curate has no twin rule.
- `joharness.sh:cmd_authority`, `joharness.sh:cmd_clerk`,
  `joharness.sh:cmd_scout`, `joharness.sh:scout_walk` — what the command
  calls.
- `.agents/docs/handover/TEMPLATE.md` — the claim file shape.
- `.agents/harness/selftest.sh` — `SELFTEST_TOPICS`, where a topic registers.

## Traps

- Research first: every prelude is read AFTER the three plans in `needs:`
  have changed it; encode the text on `origin/main` that day.
- Never `push -f`; a STOP after a push retires by a new commit.
- Never checkout -B over a pushed branch: a name collision adds a suffix.
- Interface signatures are not yours: the role reports' lines keep their
  wording; the command reads them as the roles do.
