---
plan: retro-audit-and-trace
urgency: normal
agent: opus
effort: high
needs: conduct-recent-sample, c1-at-the-gates
research: conduct-c2-design
requirement: none
issue: none
scope: joharness.sh, .claude/commands/retro.md, .claude/commands/conduct.md, .claude/commands/retro-audit.md, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/docs/orchestrate-reference.md, .agents/docs/glossary.md, .agents/harness/AGENTS.md, README.md, docs/conduct-log.md, .agents/scripts/bootstrap-consumer.sh, .agents/scripts/conf-keys.sh, .agents/harness/selftest/retro.sh, .agents/harness/selftest/scout.sh, .agents/harness/selftest/role.sh, .agents/harness/selftest/orchestrated.sh, .agents/harness/selftest/reading-budget.sh, .agents/harness/selftest.sh
---

## Goal

The user decided to merge conduct and retro into ONE role, retro, with two
modes:

- **audit** (today's conduct): samples recent merged work and records
  whether a defect got past the gates. It never fixes anything, so its
  CONCERN rate stays an honest measure of the gates.
- **trace** (today's retro): takes failures and files plans for the missing
  check. Its failures are sessions that did not come back clean, plus audit
  CONCERNs not yet traced.

Two reasons. The roles are two copies of the same plumbing: clock, ledger,
`role` prelude, twin check, self-merged pull request. And a CONCERN reaches
nobody today; inside one role it becomes trace's input.

## Scope

The interface is fixed here. The builder does not choose it.

**Commands**

| Today | After | Notes |
| --- | --- | --- |
| `/conduct` | `/retro-audit` | new `.claude/commands/retro-audit.md` = conduct.md's text, renamed; conduct.md deleted |
| `/retro` | `/retro` (trace) | unchanged |
| `./joharness.sh conduct` | `./joharness.sh retro --audit` | `conduct` stays as an alias with identical output |
| `./joharness.sh role conduct [--twin]` | `./joharness.sh role retro --audit [--twin]` | `role conduct` stays as an alias |
| branch `conduct-<date>-<HHMM>` | `retro-audit-<date>-<HHMM>` | readers also accept `conduct-<digit>…` as audit |
| title `🧐 conduct: <UTC date>` | `🩺 retro: audit <UTC date>` | trace keeps `🩺 retro: <UTC date>` |

The aliases exist because sync never deletes a file a consumer already has
(`.agents/scripts/sync-to-consumer.sh`, "Removals are not handled"). A
consumer's stale `conduct.md` must keep working.

**Kept per mode:** read list, Never list, ledger, clock, knobs, and the
orchestrator's ledger tokens (`conducted=`, `retroed=`).

- Audit keeps `docs/conduct-log.md` and `JOHARNESS_CONDUCT_*`.
- Trace keeps `docs/retro-log.md` and `JOHARNESS_RETRO_*`.
- No renames: consumers' confs and history stay valid.

**Shared in `joharness.sh`, with the mode as a parameter:**

- the due clock dated from a ledger's landing;
- in-flight detection of unmerged branches;
- the `role` prelude and twin check;
- branch naming.

The open-PR check of each mode matches only its own branches:

- trace: `retro-<digit>…`
- audit: `retro-audit-*` and `conduct-<digit>…`

**dispatch**

- Status lines: `retro     : audit <state> — …` and
  `retro     : trace <state> — …`, keeping the 10-column label. They replace
  the `conduct   :` and `retro     :` lines. Audit keeps the C1 rate that
  conduct-recent-sample adds.
- Spawn, held and suppressed lines name `/retro-audit` and `/retro`.
- Suppression stays as today, renamed: one reviewer of either mode a pass,
  audit first.

**The hand-off**

- A new function lists audit CONCERN rows not yet traced. It is separate
  from `retro_candidates`, so `retro_sample` and `retro_queue_block` are
  untouched.
- Key: `concern:<audit row date>:<stem>`.
- A trace run takes up to `JOHARNESS_RETRO_SAMPLE` failed sessions as today,
  plus at most ONE CONCERN, the oldest untraced. A backlog of failures
  never starves CONCERNs, and CONCERNs never crowd out failures.
- `./joharness.sh retro` prints that CONCERN on its own `concern   :` line:
  `<stem>`, the audit row's date, and the session URL from the stem's
  workstream file at `<sha>^`, where `<sha>` is the latest retire of that
  stem dated on or before the audit row. No session URL prints `session
  none`; trace then works from the plan and workstream file alone.
- Trace logs it in `docs/retro-log.md` as a normal row, with `session` =
  the key. The existing session-keyed dedupe then retires it, and no
  CONCERN is dropped because its session was logged for another reason.

**retro.md wording.** In §2, a CONCERN is a failure of the gates: a plan
merged with an acceptance item that asserts what its Goal says must be
refused. Trace reads the plan and the workstream file `## Review` at
`<sha>^` and names which gate should have caught it: plan-checker, verifier
or ci. The transcript is optional. The read list gains the audit ledger's
CONCERN rows only. "Only sessions that did not come back clean" gains this
one exception.

**Words elsewhere**

- glossary: the role-title row drops `🧐 conduct`, and its pinned needle in
  `orchestrated.sh` changes with it.
- AGENTS.md: "clerk, conduct or retro task" becomes "clerk or retro task".
- README.md: the Conduct row folds into the Retro row.
- orchestrated.md and orchestrate-reference.md: role, reads, spawn and knob
  rows.
- orchestrate.md: spawn lines.
- bootstrap-consumer.sh and conf-keys.sh: the CONDUCT comments name
  `./joharness.sh retro --audit`.
- `docs/conduct-log.md` prose: names `retro-audit.md`. The table is
  untouched.
- reading-budget.sh: conduct.md's `rb_bound` (6668) moves to
  retro-audit.md.

## Assumptions

- A1: conduct and retro share the `role` prelude path — evidence:
  `joharness.sh:cmd_role` cases `conduct|retro` — confidence: high.
- A2: retro dedupes by its ledger's `session` column — evidence:
  `joharness.sh:retro_logged` — confidence: high.
- A3: 451 of 458 retired manager workstream files carry `session:` at
  `retire^` (verifier, 2026-10-25, on origin/main). Hence `session none` —
  evidence: `.agents/docs/handover/TEMPLATE.md` — confidence: high.
- A4: the knobs are dispatch-scoped — evidence: `joharness.sh` KNOBS rows
  `JOHARNESS_CONDUCT_*`, `JOHARNESS_RETRO_*` — confidence: high.
- A5: sync does not remove files canonical deleted — evidence:
  `.agents/scripts/sync-to-consumer.sh` header — confidence: high.

## Out of scope

- Renaming knobs, ledgers, ledger tokens or the conduct-log file.
- New audit questions: the C2 follow-up from research conduct-c2-design.
- Letting audit act on anything.
- Core paths.

## Acceptance

```bash
test ! -e .claude/commands/conduct.md && test -s .claude/commands/retro-audit.md   # exit 0
./joharness.sh dispatch | grep -c '^retro     : \(audit\|trace\) '   # 2
./joharness.sh dispatch | grep -c 'conduct DUE\|^conduct   :\|on /conduct'   # 0
diff <(./joharness.sh conduct) <(./joharness.sh retro --audit)   # no output
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- Selftest cases, each failing on origin/main:
  - an untraced CONCERN prints on `./joharness.sh retro`'s `concern   :`
    line, at most one per run, oldest first;
  - one logged under its `concern:` key does not print;
  - a CONCERN whose stem's session already has a retro-log row from a
    block still prints;
  - a stem retired twice resolves to the retire on or before the audit
    date;
  - no `session:` prints `session none`;
  - a `conduct-<digit>` branch reads as audit in flight;
  - an open `retro-audit-*` PR does not stop trace;
  - `role conduct` and `role retro --audit` print the same last line.
- The existing conduct cases (in `selftest/scout.sh`) and retro cases
  (`selftest/retro.sh`) are moved or rewritten to the new names, never
  deleted to get green.
- Consumer side (SHIPS): after its next sync a consumer runs
  `./joharness.sh ci` → `ci: pass`; its existing `docs/conduct-log.md`
  tallies under `retro --audit`, and its stale `conduct.md` still runs.

## Where to look

- `joharness.sh:cmd_conduct`, `joharness.sh:conduct_due`,
  `joharness.sh:conduct_tally`: the audit half.
- `joharness.sh:cmd_retro`, `joharness.sh:retro_due`,
  `joharness.sh:retro_logged`: the trace half.
- `joharness.sh:cmd_role`, `joharness.sh:role_twin_run`: the shared prelude.
- `.claude/commands/retro.md:Never read a diff body`: trace's read limit.
- `.agents/docs/orchestrate-reference.md:conducted=`: the spawn table rows.
- `.agents/harness/selftest/orchestrated.sh:emoji`: the pinned role-title
  row.

## Traps

- Pinned needles quote conduct and retro text in scout.sh, retro.sh,
  role.sh and orchestrated.sh. Edit each needle together with its text;
  never skip it.
- `knobs-declared.sh` compares the knob table to KNOBS exactly.
- Never skip, disable or quarantine a test to get green.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope
  manager`, `bare role title`.
