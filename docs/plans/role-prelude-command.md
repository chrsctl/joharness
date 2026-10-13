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
5 files; the scout's copy carries 14 lines matching
`grep -c -i -E '= stop|stop,|stop and|and exit|= retire|exit\.|exit:'`
(gx's copy of `scout.md`, that day) and 10 `Never` bullets. Prelude prose
is where this week's two harness defects sat (#459, the clerk's reader
probe; #460, the scout's §0.4); other plans fix those two, and this one
removes the class: a model re-deriving procedure from prose per pass is
slower, costlier and less exact than one tested function. Make the ritual a
command that prints `GO` or `STOP: <reason>`, and leave the role commands
the judgement: what to read, what to produce.

## Scope

- `joharness.sh` — `cmd_role <clerk|scout|curate|conduct> [--session <url>] [--agent <tier>] [--twin|--retire]`.
  The command encodes each role command's §0–§1 as they read on
  `origin/main` the day this builds, after the three plans in `needs:`; the
  steps below are that text's shape, and where they differ the text wins:
  - the start (no flag), in order: (1) `./joharness.sh authority`, with the
    one unshallow-and-retry `shallow-clone-reaches-authority` adds; not
    VERIFIABLE = `STOP: authority <verdict>`; (2) `git fetch --prune origin
    '+refs/heads/*:refs/remotes/origin/*'` (the fetch `clerk-fetch-before-inflight`
    puts before the report; FAILED = `STOP: fetch failed`); (3) resume,
    BEFORE any cadence read: the current branch already carries this role's
    own claim file = `GO <branch> (resumed)`, nothing cut, nothing pushed,
    no report consulted (scout §0.2: a resumed scout skips §0.3–4, and
    `cmd_scout` prints `off` or `UNREADABLE` before it lists rows); (4) the
    role's own report (`clerk`, `scout`, `curate`, `conduct`), and
    `STOP: <line>` on every line that role's §0 treats as a plain exit — IN
    FLIGHT by another branch for all four; `off`, `UNREADABLE` for the
    scout; `not due` and `nothing to sample` for conduct; curate's "no
    PROPOSE findings" exit — the command's list is the role's list, read
    from the command text. The scout's `NO BRIEF` is not a plain exit
    (`scout.md` §0.5: claim, report, retire): the command claims as in (6),
    retires at once, and prints `STOP: NO BRIEF (claimed and retired)`;
    (5) `git fetch origin main`
    and the branch under the role's naming rule as its command states it
    (clerk `clerk-<UTC date>` with `-b`, `-c` suffixes on collision; scout
    `scout-<UTC date>`; conduct `conduct-<UTC date>-<HHMM>` as its command
    gives; curate's command names only its workstream stem `curate-<UTC
    date>` and no branch, so the command uses that stem as the branch name
    too, and `curate.md` gains the sentence saying so), `git checkout -b`;
    (6) roles that claim by workstream file (scout, curate): write it from
    `.agents/docs/handover/TEMPLATE.md` with the role's frontmatter,
    `session:` and `agent:` from the flags (missing = `STOP: --session and
    --agent are required for <role>`), commit, push `-u`; then the scout
    runs the twin check below and prints its verdict; curate has no twin
    rule and prints `GO <branch>`. Roles that claim by their first content
    push (clerk, conduct) stop at (5) and print `GO <branch>`; their twin
    check is `--twin`, run by the role command after its first push.
  - `--twin`: `git fetch --prune` as above, the role's report again, the
    role's rule (scout: exactly one IN FLIGHT row and it is yours; clerk:
    yours sorts first by name among those in flight; conduct: its stated
    rule), then `GO` or `STOP: TWIN <other>`; on STOP for a role that pushed
    a claim file, the retire below runs first, so the caller has nothing to
    undo. `curate --twin` = `STOP: curate has no twin rule`.
  - `--retire`: delete the current branch's own claim file, commit, push.
- `.claude/commands/clerk.md`, `scout.md`, `curate.md`, `conduct.md` — their
  §0 and §1 become: run `./joharness.sh role <name> …`; `STOP:` = report the
  line and exit; `GO` = continue at the first judgement step (curate's
  `curate --apply` step is judgement and stays where it is); the twin
  paragraph becomes `./joharness.sh role <name> --twin` where the role has
  one; the retire becomes `--retire`. Judgement stays prose: the clerk's
  gates, the scout's ceiling and reads, conduct's sampling, curate's
  proposals.
- `.agents/docs/orchestrated.md` — the Roles table's "Runs as" column for
  the four roles names the command; one paragraph with the counts above,
  dated.
- `.agents/harness/selftest/role.sh`, registered in `SELFTEST_TOPICS` in
  `.agents/harness/selftest.sh` — fixtures: authority UNVERIFIED →
  `STOP: authority`; scout with a twin in flight → `STOP: TWIN` and the
  claim file retired on the fixture remote; clean scout → `GO` with the
  claim pushed under the right name and frontmatter; scout re-run on its
  own branch, with `JOHARNESS_SCOUT_HOURS=0` set so the report reads
  `off` → `GO … (resumed)` all the same; scout with no brief on the fixture
  main → `STOP: NO BRIEF (claimed and retired)` and the claim file created
  then deleted on the fixture remote; clerk `--twin` with a same-day sibling
  sorting first → `STOP: TWIN`; conduct `not due` → `STOP: not due`;
  `--retire` deletes the file and pushes.

## Out of scope

- The orchestrator and manager preludes.
- Any gate that reads GitHub (the clerk's scout gate, the author gate):
  judgement, and `joharness.sh` reads no GitHub.
- Changing any role's naming rule, cadence, exits or tiebreak: the command
  encodes the four commands' text after the plans in `needs:` have landed.
- `orchestrate.md`'s own `git fetch --prune`: a different role.

## Acceptance

- `bash .agents/harness/selftest.sh` — `role.sh`'s eight cases pass;
  `./joharness.sh ci` — `ci: pass`.
- `wc -l .claude/commands/clerk.md .claude/commands/scout.md .claude/commands/curate.md .claude/commands/conduct.md`
  — each shorter than on `origin/main` at the plan's start; quote both.
- `grep -c 'fetch --prune' .claude/commands/clerk.md .claude/commands/scout.md .claude/commands/curate.md .claude/commands/conduct.md` — `0` each.
- Plan `ci` calls SHIPS: the consumer check is the next gx clerk or scout
  pass's report opening with the command's `GO`/`STOP` line.

## Where to look

- `.claude/commands/clerk.md:## 0. Preconditions` and `## 1. Branch` — the
  clerk's copy: the fetch before the report, twin check after the first
  push, name tiebreak.
- `.claude/commands/scout.md:## 0. Preconditions` and `## 1. Claim` — the
  scout's copy: the resume rule, claim file, twin rule, retire.
- `.claude/commands/conduct.md` and `.claude/commands/curate.md` — their §0
  exits; curate has no twin rule.
- `joharness.sh:cmd_authority`, `joharness.sh:cmd_clerk`,
  `joharness.sh:cmd_scout`, `joharness.sh:scout_walk` — what the command
  calls.
- `.agents/docs/handover/TEMPLATE.md` — the claim file shape.
- `.agents/harness/selftest.sh` — `SELFTEST_TOPICS`.

## Traps

- Research first: every prelude is read AFTER the three plans in `needs:`
  have changed it; encode the text on `origin/main` that day, and where
  this plan's step list and that text differ, the text wins.
- Never `push -f`; a STOP after a push retires by a new commit.
- Never checkout -B over a pushed branch: a name collision adds a suffix.
- Interface signatures are not yours: the role reports' lines keep their
  wording; the command reads them as the roles do.
- `knobs-declared-once` and `orchestrator-hands-off-at-context-ceiling` also
  edit `orchestrated.md` and `joharness.sh`: name them at reconcile.
