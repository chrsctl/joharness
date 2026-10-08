---
plan: scout-cycle
urgency: normal
agent: opus
effort: high
needs: none
requirement: scout-role
scope: shared:joharness.sh, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, joharness.conf, .agents/harness/selftest.sh, .agents/harness/selftest/scout.sh, shared:.agents/docs/orchestrated.md
---

## Goal

`docs/product/scout-role.md`, second bullet: a scout cycle with the shape
of the curate and janitor cycles — ONE reader both `dispatch` and `drain`
ask, a `scout : DUE` tail line, a cadence from git, at most one in flight —
plus the two conf keys the requirement names. This plan is the MACHINERY
(the reader, the lines, the keys, the selftest); what a scout does when
spawned is `scout-command`. Two things make this cycle different from the
two it copies, and both are decided here, not left to the implementer:

1. **It fires only at DRAINED.** Curate and janitor are orthogonal to the
   verdict. A scout proposes new work, and new work competes with real
   work — so `scout : DUE` prints under `DRAINED` and nowhere else, and
   `dispatch` says so when it is due but suppressed.
2. **A closed proposal leaves nothing on `main`.** The curate reader dates
   the cycle from the newest base-branch commit deleting
   `docs/handover/curate-*.md`; a scout whose pull request the human
   CLOSED retired nothing there. Date the scout cycle from the newest
   `scout-<stamp>` seen in BOTH places: a deletion on the base branch
   (merged) and any remote branch whose workstream file reads
   `workstream: scout-<stamp>` (open or closed — a session never deletes a
   branch, so the closed one's ref survives). Newest stamp wins; the stamp
   is a UTC date and sorts as text.

## Scope

- `joharness.sh` —
  - `scout_due`: `JOHARNESS_SCOUT_HOURS` via `num_knob`, default 168; `0`
    prints `off`; otherwise `due <reason>` / `not due <reason>` with the
    hours since the newest stamp, read as above. Reuse `cycle_landed_sha`
    / `cycle_age_h` with kind `scout` for the merged half (glob
    `docs/handover/scout-[0-9]*.md`, digit after the dash like janitor);
    the branch half is a new walk over `refs/remotes/origin/*` reading the
    workstream frontmatter with `git show`, the way `janitor_branches` does.
  - `scout_branches`: in-flight scouts — a remote branch whose workstream
    file reads `workstream: scout-<stamp>` and `plan: none` AND whose
    `status:` is not `done` and is not merged. One line per branch,
    `<branch>\t<stamp>\t<status>`.
  - `cmd_scout` (`./joharness.sh scout`): header `== scout (every %sh:
    JOHARNESS_SCOUT_HOURS; automerge: %s)`, the due state, in-flight lines,
    then the evidence pointers a scout reads — the commands by name
    (`upstream`, `scorecard`, `review`, `feedback`), open issues on the
    canonical, the control plane's cost reader — and `JOHARNESS_SCOUT_AUTOMERGE`'s
    resolved value (`on` only for the literal `on`; anything else `off`).
    Report-only, like `janitor`.
  - `drain`: a `scout :` block after the janitor block, SAME mode routing
    (orchestrated = the orchestrator's to spawn; else this session's item,
    read `.claude/commands/scout.md`), printed ONLY when the verdict is
    DRAINED. Not DRAINED and due: one line `scout     : due, suppressed —
    not DRAINED`.
  - `dispatch`: the tail line `scout DUE: spawn ONE scout (agent: fable) on
    /scout — beyond the cap, holds no slot, at most one in flight, only at
    DRAINED. It proposes; a human merges unless JOHARNESS_SCOUT_AUTOMERGE=on
    (JOHARNESS_SCOUT_HOURS)`, gated on the DRAINED verdict the way the
    curate line is gated on `curate_due`.
  - `help` text and the header comment block: two rows, beside janitor's.
- `.agents/scripts/conf-keys.sh` — two rows:
  `JOHARNESS_SCOUT_HOURS|168|Hours since the last scout before one is due, and only at DRAINED; 0 switches the cycle off.`
  `JOHARNESS_SCOUT_AUTOMERGE|off|off = a scout's proposal pull request waits for a human; on = the scout merges it itself. Money and product direction in one key.`
- `.agents/scripts/bootstrap-consumer.sh` — the seeded heredoc carries both
  (the selftest reds if conf-keys and the heredoc disagree). No interview
  question for either: a human at a fresh repo has no opinion yet.
- `joharness.conf` — the two keys as commented defaults in the orchestrated
  block, each with a one-line why, the automerge line saying it is the ONE
  exception to "nothing is invented" and why that still holds (a conf line
  is a human act).
- `.agents/harness/selftest/scout.sh`, registered in `selftest.sh` beside
  `janitor.sh` — cases: off; not due with no history; due after a merged
  retire older than the window; NOT due when a CLOSED proposal's branch
  carries a newer stamp (the case this cycle exists for); in flight; drain
  prints the block only under DRAINED; dispatch prints the tail only under
  DRAINED; automerge resolves `on` for `on` and `off` for `ON`, `yes`,
  unset.
- `.agents/docs/orchestrated.md` — "What the mode changes" table: one row
  for `./joharness.sh scout` + the tail line; "The numbers" table: the two
  keys, default and why.

## Out of scope

- `.claude/commands/scout.md`, the orchestrator's spawn rule, the roles
  table row — `scout-command`.
- The `fable` vocabulary — `fable-tier`. The tail line prints the WORD
  `fable`; nothing here lints it.
- Any merge logic. `AUTOMERGE` is resolved and PRINTED here; acting on it
  is the command's.
- Dating the cycle from the control plane. `drain` has none, and one reader
  for both callers is the rule (`joharness.sh:cycle_landed_sha` comment).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh scout` on this repo — prints the header, a due state, and
  the evidence pointers; exit 0.
- `JOHARNESS_SCOUT_HOURS=0 ./joharness.sh scout` — contains `off`.
- `bash .agents/harness/selftest.sh` — `0 failed`; the scout topic's cases
  all listed as pass (count them from the run).
- `bash .agents/harness/selftest/bootstrap-consumer.sh`-driven case in the
  suite green: seeded conf and `conf_keys_names` agree.
- SHIPS: `joharness.sh` syncs to every consumer; `.agents/scripts/` does
  not, and the sync's report names the two new keys to each consumer whose
  conf lacks them — the selftest `sync-to-consumer.sh` has the case shape.

## Where to look

- `joharness.sh:janitor_due`, `joharness.sh:janitor_branches`,
  `joharness.sh:cmd_janitor` — the three functions to mirror.
- `joharness.sh:cycle_landed_sha` — the one dating reader and its glob rule.
- `joharness.sh:cmd_drain` — the janitor block and its mode routing;
  the `DRAINED` printf is the gate this cycle hangs on.
- `joharness.sh:cmd_dispatch` — the curate / janitor tail lines on the
  verdict.
- `.agents/scripts/conf-keys.sh:conf_keys_rows` and
  `.agents/scripts/bootstrap-consumer.sh` lines reading
  `conf_key_default JOHARNESS_JANITOR_HOURS` — the key's two homes.
- `.agents/harness/selftest/janitor.sh` — fixture shape: a bare origin, a
  work clone, `env JOHARNESS_CONF=`.

## Traps

- Nothing is invented: this plan prints that a scout is due; it never
  lists a proposal.
- `pgrep -f` on your own pattern never exits; the selftest fixture must
  bound every wait.
- Trust counted numbers: no pass total written anywhere.
- `.agents/harness/` names no environment.
- Never a `= unsupervised` test: gate on `unattended()` / the mode word
  exactly as the janitor block does.
