---
plan: conduct-audits-the-gates
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .claude/commands/conduct.md, .claude/commands/retro.md, .agents/docs/orchestrated.md, .agents/docs/orchestrate-reference.md, .agents/harness/selftest/scout.sh, .agents/harness/selftest/retro.sh, .agents/harness/selftest/role.sh, .agents/harness/selftest.sh, .agents/harness/selftest/reading-budget.sh
---

## Goal

The user asked whether conduct is necessary and chose to improve it, not
delete it. Conduct is the only independent measure of whether the gates
(plan-checker, verifier, ci) let defects through. Today it measures badly,
for three reasons:

1. It audits old work. `conduct_candidates` takes every retired branch in
   history, sorted by sha1 of the stem, so the sample is arbitrary and
   rarely recent.
2. It asks one narrow question, C1.
3. Nothing acts on a CONCERN. conduct.md forbids it, and the rate prints
   only on `./joharness.sh conduct`.

Make conduct an auditor of the gates. It samples recent, risky merges and
checks the rules the gates claim to enforce. Its findings reach retro, which
turns them into mechanism plans. Conduct itself still never fixes anything.

## Scope

1. **Measure C2 first.** Run one selftest topic against a pre-fix commit and
   time it. Record the measurement in `## Decisions`, naming the command and
   when it ran. If one sampled branch's C2 cannot finish inside the role
   prelude's 600 s bound, C2 ships as `NO EVIDENCE: too slow`. Record the
   bound you chose.
2. **Sample** (`joharness.sh:conduct_candidates`, `conduct_sample`):
   - Candidates: managers retired within `JOHARNESS_CONDUCT_HOURS` of now, not
     all of history.
   - Order the candidates by risk:
     - the plan's `agent:` is sonnet or haiku, so no plan-checker ran;
     - the diff touched `joharness.sh` or `.agents/harness/`.
   - Break ties so the sample stays deterministic for tests. `0` = off is
     unchanged.
3. **C2: a fix's test fails without it** (Loop step 5, "Test for a fix must
   FAIL without it"). For a sampled branch that adds or changes a selftest
   case:
   - Run that topic on a temporary worktree at the merge's first parent.
   - Overlay only the branch's test files.
   - The topic must go red.
   - Verdict: `FINE` (red as required), `CONCERN` (green, so the test proves
     nothing), or `NO EVIDENCE` (no test changed, too slow, or not runnable).
   - Conduct's read limits widen for C2 only: running tests and reading which
     test files changed. It still reads no diff body.
   - Running ONE topic needs a selector in `.agents/harness/selftest.sh`. Add
     one, or record why C2 runs the whole suite.
   - In a consumer repo, C2 has no selftest topic to run, so it records
     `NO EVIDENCE: no runner`. A per-repo runner is a follow-up, not this plan.
4. **Ledger:** `docs/conduct-log.md` gains a `C2` column.
   - `conduct_rows` and `conduct_tally` read columns by name.
   - Old rows have no C2 value and stay valid.
5. **CONCERN feeds retro.**
   - `retro_candidates`/`retro_sample` add conduct CONCERN rows not yet in
     `docs/retro-log.md`, after the sessions that did not come back clean.
   - retro.md: the "Never read … another role's ledger" line gains the one
     exception, conduct CONCERN rows. Retro traces each one to the gate that
     missed it.
   - conduct.md keeps "Act on a CONCERN" in `## Never`. Conduct records, and
     retro acts.
6. **Rate visible.** `dispatch`'s `conduct :` line prints the CONCERN rate of
   the last 4 runs. Make conduct due early when that rate is at least
   `JOHARNESS_CONDUCT_ALARM` (new knob, declared in the KNOBS table and the
   orchestrated.md knob table; default 25 percent, 0 = off).
7. Docs: the orchestrated.md role row, reads row and knob rows, and the
   conduct row in orchestrate-reference.md describe the new behaviour.

## Assumptions

- A1: The sample sorts all retired history by sha1 of the stem — evidence:
  `joharness.sh:conduct_candidates`, `joharness.sh:conduct_sample` —
  confidence: high.
- A2: selftest.sh has no single-topic selector today — evidence:
  `grep -n 'topic' .agents/harness/selftest.sh` — confidence: medium. Confirm
  before adding one.
- A3: One topic runs in well under 600 s — evidence: none yet, it is Scope
  step 1 — confidence: low.
- A4: The conduct selftest cases live in `.agents/harness/selftest/scout.sh`
  — evidence: `grep -c conduct .agents/harness/selftest/scout.sh` (106) —
  confidence: high.
- A5: Plan c1-at-the-gates touches only verifier.md and plan-checker.md, so
  the scopes are disjoint — evidence: its `scope:` — confidence: high.

## Out of scope

- C1 in the verifier and plan-checker (plan c1-at-the-gates).
- Letting conduct edit, comment, file issues or kill anything.
- A test runner for consumer repos.
- Core paths (`./joharness.sh protocol-paths`). The new knob gets a
  default in `joharness.sh` only, and stays out of `joharness.conf`.

## Acceptance

```bash
./joharness.sh conduct            # sample lists only stems retired within JOHARNESS_CONDUCT_HOURS, sonnet/haiku first
./joharness.sh dispatch | grep '^conduct'   # prints a CONCERN rate
./joharness.sh ci                 # ci: pass
./joharness.sh verify             # 0 failed
```

- New selftest cases, each failing without its change:
  - the recency window: an old retired stem is not sampled;
  - risk order: a sonnet-tier stem sorts before an opus one;
  - C2 verdicts on a fixture whose test passes without the fix (CONCERN) and
    one whose test fails without it (FINE);
  - an old ledger row without C2 still tallies;
  - retro samples a CONCERN row;
  - the alarm makes conduct due early.
- `## Decisions` names the C2 runtime with its command and date.
- Consumer side (SHIPS): after its next sync a consumer runs
  `./joharness.sh ci` → `ci: pass`, and `./joharness.sh conduct` records C2
  as `NO EVIDENCE: no runner`.

## Where to look

- `joharness.sh:conduct_candidates`: the sample source.
- `joharness.sh:conduct_sample`: the sha1 ordering.
- `joharness.sh:conduct_tally`: the rate, which reads columns by name.
- `joharness.sh:conduct_due`: the clock the alarm shortens.
- `joharness.sh:retro_candidates`: where CONCERN rows join retro's sample.
- `.claude/commands/conduct.md:The ONE question`: C1, which C2 joins.
- `.claude/commands/retro.md:Never read a diff body`: the read limit that
  gains one exception.
- `.agents/harness/selftest/scout.sh:conduct cycle`: the existing conduct
  cases.

## Traps

- conduct.md is under a reading budget (`reading-budget.sh`, 6668 + 10%).
  Put new detail in conduct.md only if it fits. Otherwise raise the bound in
  the same pull request, with its reason.
- Pinned needles in `.agents/harness/selftest/orchestrated.sh` and
  `retro.sh` quote conduct and retro text. Edit a needle together with its
  text; never skip it.
- A new knob row needs the shape `| \`KEY\` | default |` with the KNOBS
  default (`knobs-declared.sh`).
- Never skip, disable or quarantine a test to get green.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope
  manager`, `bare role title`.
