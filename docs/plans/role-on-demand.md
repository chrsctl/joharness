---
plan: role-on-demand
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .claude/commands/retro.md, .claude/commands/retro-audit.md, .claude/commands/clerk.md, .claude/commands/orchestrate.md, .agents/docs/orchestrate-reference.md, .agents/docs/orchestrated.md, .agents/harness/selftest/role.sh
---

## Goal

The human wants the helper roles (clerk, retro audit, retro trace) to run
on demand, not only when their clock says due. Today scout already runs on
demand, and clerk's prelude ignores `not due`, but both retro modes refuse:
`./joharness.sh role retro` and `role retro --audit` print `STOP: retro :
not due …` / `STOP: cadence : not due …` before the window elapses, and
both command files (§0 step 3) forbid a human-started pass unless
`dispatch` prints `DUE: spawn`. Worse, the orchestrator's "human orders an
extra role session" path (`orchestrate-reference.md`, Role sessions) spawns
a retro session that STOPs at once, while its ledger still records
`retroed=<stamp>+human`. Make an ordered pass of any helper role run,
whether ordered through a live orchestrator or typed by the human as
`/clerk`, `/retro` or `/retro-audit` in a fresh session — with the
in-flight, twin and unreadable gates untouched, so on-demand never means
two of one role.

## Scope

- `joharness.sh:cmd_role` — accept `--ordered` for `clerk`, `retro`
  (both modes); usage line names it. `scout` rejects it (`STOP:` line):
  scout has no clock.
- `joharness.sh:role_start_stop` — under `--ordered`, skip ONLY the cadence
  gate (`audit`: the `cadence   : ` not-DUE line; `retro`: the `retro : `
  not-DUE line). Still STOP on `UNREADABLE`, `IN FLIGHT`, `sample    :
  UNREADABLE`, and on an EMPTY sample (nothing to review = nothing to do;
  name the line it prints). `held` and `suppressed` stay stops: they
  are not the clock.
- `.claude/commands/retro.md` and `.claude/commands/retro-audit.md`, §0 —
  step 1: prompt `/retro --ordered` / `/retro-audit --ordered` (the
  argument, nothing else) = run the prelude with `--ordered`. Step 3
  ("Started by a human … must print … DUE: spawn") is replaced: a human-
  started pass runs the prelude with `--ordered`.
- `.claude/commands/clerk.md`, §0 — say a human may start `/clerk` in a
  fresh session at any time; the prelude already ignores `not due`. No
  code change for clerk beyond `--ordered` being accepted and a no-op.
- `.agents/docs/orchestrate-reference.md`, Role sessions — the
  human-ordered extra spawn's prompt is the row's command plus `--ordered`
  for clerk and retro (either mode); the ledger stays `<key>=<stamp>+human`.
  Still never while dispatch shows that role in flight.
- `.claude/commands/orchestrate.md` — only if its text restates the
  extra-spawn prompt; make it match the reference, nothing more.
- `.agents/docs/orchestrated.md` — the Lineup rows for clerk and retro
  (audit, trace) add "or on the human's order (`--ordered`)" to "Started
  by"; the clock rows (lines for `./joharness.sh clerk`, `retro`, `retro
  --audit`) say the clock decides only unordered passes.
- `.agents/harness/selftest/role.sh` — cases below (Acceptance).

## Assumptions

- A1: `role retro` STOPs on `not due` — evidence:
  `joharness.sh:role_start_stop` (`role_line '^retro DUE:' >/dev/null ||
  role_line '^retro : '`) — confidence: high
- A2: `role retro --audit` STOPs on `not due` — evidence:
  `joharness.sh:role_start_stop` (`audit` case, `^cadence   : `) —
  confidence: high
- A3: clerk's prelude does not STOP on `not due` — evidence:
  `joharness.sh:role_start_stop` has no `clerk` case; `clerk.md` §0
  "(`not due` is no exit)" — confidence: high
- A4: the sample is computed when not due, so an ordered pass has work —
  evidence: `./joharness.sh retro` and `./joharness.sh retro --audit` on
  origin/main 313a4ec3 printed `not due` AND a 3-entry `sample    :` line —
  confidence: high
- A5: an ordered pass's merged ledger resets the clock like a due one
  (both clocks date from the ledger landing) — evidence:
  `joharness.sh:retro_due` ("since the ledger last landed"), conduct
  cadence likewise — confidence: medium; confirm, and record in
  `## Decisions` whether that is wanted (recommend yes: the clock measures
  time since the last review, whoever ordered it).
- A6: the twin check (`--twin`) and in-flight readings need no change to
  hold "never two of one role" under `--ordered` — evidence:
  `joharness.sh:cmd_role`, `retro.md` / `retro-audit.md` twin sections —
  confidence: medium; the twin rule "`not-due`" mention in
  `retro-audit.md` (`STOP: TWIN <other>` … `not-due`) must be read and
  adjusted if an ordered twin would read as `not-due`.

## Out of scope

- Turning any clock off or changing a `*_HOURS` default: those live in
  `joharness.conf`, a core path. If the human wants clocks off, that is a
  separate `human/<stem>` pull request.
- Scout: already on demand; do not touch `scout.md` or `cmd_scout`.
- Letting the keeper or dispatch spawn roles without an orchestrator, or a
  new trigger/schedule of any kind.
- Any "force" that bypasses IN FLIGHT, UNREADABLE, twin, `held` or
  `suppressed`.
- The surveyor: it is spawned by `OVERLAP-BOUND`, not a clock.

## Acceptance

- `./joharness.sh role retro --ordered` in a fixture repo whose ledger
  landed 1h ago with a non-empty sample — last line `GO retro-<date>-<HHMM>`.
  Same fixture without `--ordered` — last line `STOP: retro : not due …`
  (unchanged).
- Same pair for `role retro --audit --ordered` — `GO retro-audit-…` /
  `STOP: cadence   : not due …`.
- `role retro --ordered` with a `retro-<digit>…` branch in flight — `STOP:`
  naming IN FLIGHT (ordered never bypasses it).
- `role retro --ordered` with an empty sample — `STOP:` naming the empty
  sample.
- `role scout --ordered` — a `STOP:` line saying scout has no clock.
- `role clerk --ordered` when not due — `GO clerk-…`, same as without it.
- Each case lives in `.agents/harness/selftest/role.sh`, and each
  `--ordered` GO case FAILS on origin/main before the change.
- SHIPS: in a consumer after sync, `./joharness.sh role retro --ordered`
  when not due — last line `GO retro-…` (or a named `STOP:` for in
  flight / empty sample), never `STOP: retro : not due`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:role_start_stop` — the cadence gate to bypass.
- `joharness.sh:cmd_role` — argument parsing, usage `die` line.
- `joharness.sh:role_report` — what the prelude prints before deciding.
- `joharness.sh:retro_due` — RETRO_DUE `not-due` reading.
- `.claude/commands/retro.md:Preconditions` — step 3 to replace.
- `.claude/commands/retro-audit.md:Preconditions` — step 3 to replace;
  also its twin paragraph mentioning `not-due`.
- `.claude/commands/clerk.md:Prelude` — `not due` is no exit.
- `.agents/docs/orchestrate-reference.md:The human orders an extra role session` — extra-spawn prompt.
- `.agents/docs/orchestrated.md:JOHARNESS_RETRO_HOURS` — knob rows.
- `.agents/harness/selftest/role.sh` — existing prelude fixtures to extend.

## Traps

- Interface signatures are not yours alone: `--ordered` is a new CLI flag
  and a new prompt argument. Name it exactly `--ordered`; flag the choice in
  the pull request body for the human.
- The spawn prompt must never quote the human or assert their authority
  (`orchestrate-reference.md`, Role sessions): `--ordered` is a mechanical
  argument, nothing more.
- No commit to a core path (`./joharness.sh protocol-paths`): not
  `joharness.conf`, not `.github`, not `.claude/settings.json`.
- A test for the fix must FAIL without it. Never skip, disable or
  quarantine a test to get green.
- `local-check-required` also edits `joharness.sh` (`checks_gate`,
  disjoint functions): whichever lands second merges `origin/main` in.
- Glossary: contested terms have one spelling; `ci` fails on the others.
