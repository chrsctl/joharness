---
plan: sampling-conduct-reviewer
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 251
scope: joharness.sh, .claude/commands/conduct.md, .agents/docs/orchestrated.md, docs/conduct-log.md, .agents/harness/selftest.sh, .agents/harness/selftest/scout.sh, .agents/harness/selftest/dispatch.sh, .agents/harness/selftest/bootstrap-consumer.sh, .agents/scripts/conf-keys.sh
---

## Goal

Issue #251: nothing reviews how a manager works its item, only its diff
(the verifier) and its pulse (`dispatch`). The owner decided to fund a
sampling conduct reviewer (comment 6120525830 on the issue). Add the role:
a sonnet session, periodic on a clock like the scout and curator, that
reads a SAMPLE of recently merged managers' own artifacts and records, per
sampled branch and per question, `FINE` or `CONCERN`. Every run is the
owner's money, so the role text says it runs beyond the cap, and a ledger
plus a report subcommand lets the owner see after a few runs whether the
money is worth spending (the issue has no baseline; this builds one).

## Scope

- `.claude/commands/conduct.md` (new) — the role. Sonnet. ONE pass, one
  pull request adding ledger rows, exit. Says in its first paragraph: holds
  no slot, one session beyond `JOHARNESS_MAX_MANAGERS`, each run is the
  owner's money. Reads ONLY `./joharness.sh conduct`, and per sampled
  branch its workstream file as it stood at its last commit before retire
  (`git show <sha>:docs/handover/<stem>.md`), the branch's commit order
  (`git log --format=... --name-status`) and the plan file's `## Acceptance`.
  NEVER reads the diff body (`git diff`, `git show` of code): that is the
  verifier's job and re-reading it is the trap issue #251 names (three identical
  skeptics scored the same as one judge at triple the cost). ONE question,
  nothing else: **C1 criterion** — does the plan's or workstream's new
  acceptance criterion assert the behaviour the change was supposed to
  refuse (issue #251's example: a criterion that recorded a wrongly
  permitted request as intended)? Answerable from the plan's Goal vs its
  Acceptance text. Name no consumer repository in the role text
  (`.agents/docs/consumer-repos.md`). The issue's other open question, a
  commit touching a file a live worker owns, is NOT asked: the handover
  template records no worker ownership, so it could only read `NO EVIDENCE`
  and would swamp the tally. A later plan adds it once the protocol records
  it. Questions already settled elsewhere are NOT asked: findings-with-the-fix
  (withdrawn, #263), peer divergence (settled NO, #315), `next:` unchanged
  while commits land (the `LOOP?` row in `dispatch`). Each verdict is
  `FINE`, `CONCERN <one line, the artifact line cited>` or `NO EVIDENCE`
  (artifact missing or unreadable — never guessed `FINE`).
- `joharness.sh` — new `conduct` subcommand and a `conduct` line in
  `dispatch`, modelled on the scout cycle:
  - Clock: `JOHARNESS_CONDUCT_HOURS` (default 168; `0` = off; also off when
    `.claude/commands/conduct.md` is absent). Clock anchor: the
    commit time of the newest commit on the base branch touching
    `docs/conduct-log.md` (none yet = the repository's age, the scout's
    rule). The reviewer writes no workstream file, so the scout's
    `docs/handover/scout-*` glob does not apply; read how the clerk resolves
    its cycle (`cmd_clerk`, `scout_walk clerk`) and reuse that. In flight =
    an unmerged `conduct-*` branch, EXCEPT one a human closed unmerged
    (sessions never delete branches): such a branch older than
    `JOHARNESS_CONDUCT_HOURS`/7 is dropped, as `scout_branches` drops
    `abandoned` rows. Any misread (`cycle_unreadable`) fails closed —
    `UNREADABLE`, never a second reviewer.
  - Sample: `JOHARNESS_CONDUCT_SAMPLE` (default 3, `0` = off). Candidates =
    workstream files retired on the base branch (the retire commit
    deleted `docs/handover/<stem>.md`), excluding stems starting `scout-`,
    `curate-`, `clerk-`, whose stem is not already a ledger row. Membership
    by stem, never by date, so the same-day boundary cannot matter. Pick the N whose
    `sha1(<stem>)` sorts lowest — deterministic (a re-run picks the same
    set, a test can assert it), not biased to the newest. The command
    PRINTS the sample; the session does not choose it.
  - `dispatch` prints `conduct DUE: spawn ONE conduct reviewer (agent:
    sonnet) on /conduct — beyond the cap, holds no slot, at most one in
    flight` and suppresses it while a curate or clerk is due OR in flight
    (they go first), and holds it when the fetch failed (`fetch_failed`,
    `DISPATCH_FETCH=0`), exactly as the scout spawn line does. NOT gated on `DRAINED`: sampling merged work
    competes with nothing.
  - `conduct` report also prints the tally from the ledger: runs, branches
    sampled, per question `FINE`/`CONCERN`/`NO EVIDENCE` counts, and the
    CONCERN rate. This is how the owner judges whether the money is worth
    it. Report only, writes nothing.
- `docs/conduct-log.md` (new) — outside `.agents/docs/` on purpose: that
  directory is synced to consumers and would overwrite their ledger with
  canonical's. The ledger, a table header plus
  rows `date | stem | C1 | C2 | note`, appended only by the reviewer's pull
  request. The diff of a reviewer's pull request touches this file and
  nothing else; it merges itself under Loop step 7's gate (the clerk's
  rule), never under a core path.
- `.agents/docs/orchestrated.md` — one Roles-table row (conduct, sonnet,
  "a session on `conduct DUE`, beyond the cap"), one row in "What each role
  reads", the two knobs in the Bounds table with their "why this number"
  cell (written number, as `JOHARNESS_CURATE_PLANS` is), the sentence after
  the Roles table ("... count against `JOHARNESS_MAX_MANAGERS` together")
  amended to exempt the conduct reviewer (and the scout, which the code
  already runs beyond the cap), and one paragraph on the scheduler (below).
- `.agents/harness/selftest.sh` and the topic files
  `.agents/harness/selftest/scout.sh` (cycle, sample, tally cases),
  `.agents/harness/selftest/dispatch.sh` (spawn-line cases): cycle off,
  not-due, due, in-flight, closed-unmerged branch, fetch-failed,
  unreadable, deterministic sample, tally. Add
  `JOHARNESS_CONDUCT_HOURS JOHARNESS_CONDUCT_SAMPLE` to the conf-key list
  at the top of `selftest.sh` where the scout's are named.
- `.agents/scripts/conf-keys.sh` and the seeded heredoc compared against it
  in `.agents/harness/selftest/bootstrap-consumer.sh` — declare the two new
  knobs, as the scout's are, so a syncing consumer is told they exist.

## Scheduler (settled, do not reopen)

#249's question — the scheduler must not be a session that can freeze with
the fleet — is settled in `e120a794`: firing and delivery are separate; a
`create_new_session_on_fire` Routine creates its target at firing, so
nothing can be gone. Under orchestrated the fresh session it starts is an
orchestrator pass, and that pass reads `dispatch` and spawns the reviewer.
This plan adds NO new scheduler and no new Routine: `conduct DUE` rides the
existing orchestrator pass. The paragraph in `orchestrated.md` says so and
cites `e120a794`.

## Out of scope

- Re-reading any diff, or a verifier-like review: the trap issue #251 names.
- The three settled questions above (#263, #315, `LOOP?`). Reopening one
  is a different issue.
- Writing a Routine, `.github` workflow or any scheduler. Core path, and
  already settled.
- Acting on a CONCERN: the reviewer records, a human reads the ledger. It
  does not edit a plan, kill a session, comment on a pull request or open
  an issue.
- Gating or auto-adjusting the sample rate from the tally. The owner
  decides after reading the tally.
- `joharness.conf`, `.claude/settings.json`, `.github`
  (`./joharness.sh protocol-paths`): never touched; knob defaults live in
  `joharness.sh`, as the scout's do.

## Acceptance

- `./joharness.sh conduct` on a checkout with no ledger rows — prints the
  header, a `due`/`not-due` line, a sample of at most
  `JOHARNESS_CONDUCT_SAMPLE` stems, and a tally of zero runs; exit 0.
- Run twice with no merge between — identical sample both times
  (the selftest asserts this).
- `JOHARNESS_CONDUCT_HOURS=0 ./joharness.sh conduct` — prints `off`, no
  sample. Same with `conduct.md` absent.
- `./joharness.sh dispatch` — with the cycle due, prints the `conduct DUE`
  line; with a curate or clerk due or in flight, prints `conduct due,
  suppressed`; with an unmerged `conduct-*` branch, `IN FLIGHT`; with a
  closed-unmerged old one, not in flight; with `DISPATCH_FETCH=0`, held. A misread prints
  `UNREADABLE` and spawns nothing.
- `grep -c 'owner.s money' .claude/commands/conduct.md` — at least 1;
  `grep 'git diff' .claude/commands/conduct.md | grep -vci never` — 0 (every
  mention is a prohibition).
- Ledger path: `./joharness.sh ci` ship-scope output does not list
  `docs/conduct-log.md` as SHIPS.
- Each selftest case FAILS on the pre-change tree and passes after.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- SHIPS: the plan's scope lists `joharness.sh` and `.claude/`, which the
  sync ships, so a consumer gets the role at its next sync. Acceptance
  includes one command a consumer runs: `./joharness.sh conduct` exits 0 in
  a consumer checkout (it has no ledger, so it prints zero runs).
- The PR that builds this says `Refs #251` or `Closes #251` per
  `manage.md` §4 (this is the only plan naming it).

## Where to look

- `joharness.sh:scout_due` — the clock, the off switches, the fail-closed
  `unreadable` state and the `SCOUT_ROWS` walk to copy.
- `joharness.sh:cmd_scout` — report subcommand shape.
- `joharness.sh:cycle_age_h` and `joharness.sh:cycle_unreadable` — how a
  cycle's age is read from git.
- `joharness.sh:cmd_dispatch` — the cycle lines and the spawn-line
  suppression chain (`scout_due`, the `curate_due` and `clerk_due` locals, `n_curate_inflight`, `n_clerk`, `fetch_failed`).
- `joharness.sh:num_knob` — how a knob is read with a default.
- `.claude/commands/scout.md` — the beyond-the-cap role text to mirror.
- `.agents/scripts/sync-to-consumer.sh:DIRS` — why the ledger is not under `.agents/docs/`.
- `.agents/docs/orchestrated.md` — Roles table, "What each role reads",
  Bounds table.
- `.agents/harness/selftest.sh` — the conf-key list near the scout's keys.

## Traps

- Two plans editing `joharness.sh` or `orchestrated.md` at once: the
  reconcile is routine there; if another plan in flight names either,
  read it before you start and merge `origin/main` in.
- No second spelling for a contested term: check
  `.agents/docs/glossary.md` before naming the role or ledger terms; `ci`
  fails the others.
- A reader that fails open spawns a second reviewer. Every unreadable git
  state is `UNREADABLE`, never `due`.
- Never hard-code a tally or a count in docs; the command prints it.
- Caveman style for the role file and docs (`.agents/docs/caveman.md`).
- Do not read or edit another plan; this one is self-contained.
