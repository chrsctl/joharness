---
plan: retro-audit-and-trace
urgency: normal
agent: opus
effort: high
needs: conduct-recent-sample
research: conduct-c2-design
requirement: none
issue: none
scope: joharness.sh, .claude/commands/retro.md, .claude/commands/conduct.md, .claude/commands/retro-audit.md, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/docs/orchestrate-reference.md, .agents/docs/glossary.md, .agents/harness/AGENTS.md, README.md, .agents/harness/selftest/retro.sh, .agents/harness/selftest/scout.sh, .agents/harness/selftest/role.sh, .agents/harness/selftest/orchestrated.sh, .agents/harness/selftest/reading-budget.sh, .agents/harness/selftest.sh
---

## Goal

The user decided to merge conduct and retro into ONE role, retro, with two
modes:

- **audit** (today's conduct): samples recent merged work and records
  whether a defect got past the gates. It never fixes anything, so its
  CONCERN rate stays an honest measure of the gates.
- **trace** (today's retro): takes failures and files plans for the missing
  check. Its failures are sessions that did not come back clean, plus every
  audit CONCERN not yet traced.

Two reasons. The two roles are two copies of the same plumbing: clock,
ledger, `role` prelude, twin check, self-merged PR. And a CONCERN reaches
nobody today; inside one role it becomes trace's input. This replaces
research conduct-concern-to-retro.

## Scope

Decisions this plan fixes (the manager records each in `## Decisions`):

- **Names.** The role is `retro`. `/retro` runs trace. `/retro-audit` runs
  audit from the new `.claude/commands/retro-audit.md`, which is
  `conduct.md`'s text moved and renamed. `conduct.md` is deleted. Two
  command files stay because every session reads its command whole: one
  file holding both modes would make each run pay for the other.
- **What stays per mode:** read list, Never list, ledger, clock, knobs.
  - Audit keeps `docs/conduct-log.md` and `JOHARNESS_CONDUCT_HOURS` /
    `JOHARNESS_CONDUCT_SAMPLE`.
  - Trace keeps `docs/retro-log.md` and `JOHARNESS_RETRO_*`.
  - Renaming knobs or ledgers would break consumer confs and history for no
    gain. Out of scope.
- **What is shared (one copy in `joharness.sh`, mode as a parameter):**
  - the due clock dated from a ledger's landing;
  - in-flight detection of unmerged `<prefix>-<digit>…` branches;
  - the `role` prelude and twin check;
  - the branch naming. Audit branches become `retro-audit-<date>-<HHMM>`,
    and the reader also accepts old `conduct-<digit>…` branches as audit.
- **The hand-off.** Trace's sample (`retro_candidates`, `retro_sample`)
  adds each audit CONCERN stem not yet in `docs/retro-log.md`, after the
  sessions that did not come back clean.
  - The session URL is `session:` from the stem's workstream file at
    `<retire sha>^`.
  - Dedupe by that session URL, as today.
  - A CONCERN with no readable session URL is listed in trace's report as
    `untraceable`, never dropped silently.
  - Trace's read list gains the audit ledger's CONCERN rows only. Its rule
    "only sessions that did not come back clean" gains this one exception.
  - `retro_queue_block` must read the same rows unchanged. Prove it in a
    test.
- **dispatch.** One `retro    :` block with an `audit` line and a `trace`
  line, replacing the `conduct   :` and `retro     :` lines. Each line keeps
  its own DUE / not due / IN FLIGHT state, and audit's line keeps the C1
  rate that conduct-recent-sample adds. The orchestrator spawns at most one
  session per mode.
- **Words.**
  - glossary: the role-title row drops `🧐 conduct`; `🩺 retro` covers
    both modes. Edit its pinned needle in `orchestrated.sh` with the row.
  - AGENTS.md: "clerk, conduct or retro task" becomes "clerk or retro task".
  - README.md: the Conduct reviewer row folds into the Retro row.
  - orchestrated.md and orchestrate-reference.md: role, reads and knob rows.
  - orchestrate.md: spawn lines.

## Assumptions

- A1: conduct and retro already share their prelude path in `role` —
  evidence: `joharness.sh:cmd_role` cases `conduct|retro` — confidence: high.
- A2: retro's dedupe key is the session URL, and `retro_candidates` drops
  rows without a `claude.ai/code/session_` URL — evidence:
  `joharness.sh:retro_logged`, `joharness.sh:retro_candidates` — confidence:
  high.
- A3: a retired manager's workstream file at `<retire sha>^` carries
  `session:` — evidence: `.agents/docs/handover/TEMPLATE.md` frontmatter —
  confidence: medium. An older or hand-written file may lack it, which is
  why `untraceable` exists.
- A4: the knobs are dispatch-scoped, so no `conf-keys.sh` or
  `bootstrap-consumer.sh` change is needed if they keep their names —
  evidence: `joharness.sh` KNOBS rows `JOHARNESS_CONDUCT_*`,
  `JOHARNESS_RETRO_*` (scope `dispatch`) — confidence: high.

## Out of scope

- Renaming knobs, ledgers or the `docs/conduct-log.md` file.
- New audit questions: research conduct-c2-design and its follow-up.
- Letting audit act on anything.
- Core paths.

## Acceptance

```bash
test ! -e .claude/commands/conduct.md && test -s .claude/commands/retro-audit.md   # exit 0
./joharness.sh dispatch | grep -E '^ +(audit|trace) '   # two lines under the retro block; zero = not done
./joharness.sh dispatch | grep -c '^conduct'            # 0
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- Selftest cases, each failing without its change:
  - an audit CONCERN stem appears in trace's sample, after a blocked
    session;
  - a CONCERN already in `docs/retro-log.md` (by session) does not;
  - a CONCERN with no session URL is reported `untraceable`;
  - an old `conduct-<digit>` branch reads as audit in flight;
  - `retro_queue_block` output is unchanged by a CONCERN row;
  - each mode's clock is independent: one DUE, the other not.
- The existing conduct cases (in `selftest/scout.sh`) and retro cases
  (`selftest/retro.sh`) are moved or rewritten to the new names, never
  deleted to get green.
- Consumer side (SHIPS): after its next sync a consumer runs
  `./joharness.sh ci` → `ci: pass`, and its existing `docs/conduct-log.md`
  still tallies under audit.

## Where to look

- `joharness.sh:cmd_conduct`, `joharness.sh:conduct_due`,
  `joharness.sh:conduct_tally`: the audit half.
- `joharness.sh:cmd_retro`, `joharness.sh:retro_due`,
  `joharness.sh:retro_candidates`, `joharness.sh:retro_sample`,
  `joharness.sh:retro_queue_block`: the trace half and the hand-off.
- `joharness.sh:cmd_role`: the shared prelude.
- `.claude/commands/retro.md:Never read a diff body`: trace's read limit.
- `.agents/harness/selftest/orchestrated.sh:emoji`: the pinned role-title
  row.

## Traps

- Sync deletes a command file a consumer no longer receives only if the
  sync engine is told. Check how `.agents/scripts/sync-to-consumer.sh`
  handles a deleted `.claude/commands/` file. If it leaves a stale
  `conduct.md` behind, record that as a finding for canonical's sync,
  out of this scope.
- `knobs-declared.sh` compares the knob table to KNOBS exactly.
- Reading budgets: retro.md and the new retro-audit.md each need an
  `rb_bound` line. Move conduct.md's bound, never drop it.
- Never skip, disable or quarantine a test to get green.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope
  manager`, `bare role title`.
