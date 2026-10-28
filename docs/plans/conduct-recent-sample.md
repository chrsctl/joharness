---
plan: conduct-recent-sample
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .claude/commands/conduct.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/scout.sh, shared:.agents/harness/selftest/orchestrated.sh, shared:.agents/harness/selftest/retro.sh, shared:.agents/scripts/conf-keys.sh
---

## Goal

The user chose to keep conduct as the independent audit of the gates
(plan-checker, verifier, ci) and make it useful. Today its sample is every
retired branch in history, ordered by sha1 of the stem, so it audits
arbitrary old work. Its CONCERN rate prints only on `./joharness.sh conduct`.
Make conduct sample the work merged since its last run, riskiest first, and
show its rate where the orchestrator reads. Questions beyond C1 (research
conduct-c2-design) and routing CONCERNs to retro (plan
retro-audit-and-trace) are not this plan.

## Scope

1. **Window** (`joharness.sh:conduct_candidates`):
   - Candidates are managers whose retire commit is no ancestor of the
     base-branch commit the last ledger branch was cut from (where that
     reviewer drew its sample; a ledger written straight on the base branch:
     that commit), not the merge `conduct_age_h` dates. A run that comes late leaves no gap, and
     neither does one in flight: a retire merged while its pull request was
     open is still offered next time. Stems past the cap are not carried:
     the sample is of recent work, never a backlog.
   - No ledger on the base branch: the window is the last
     `JOHARNESS_CONDUCT_HOURS` hours, cut at the newest first-parent commit
     dated at or before then; everything that landed after it is in. Both
     windows are a commit range from that cut point, never a date compare
     per retire. `JOHARNESS_CONDUCT_HOURS`'s rows (KNOBS, orchestrated.md,
     `.agents/scripts/conf-keys.sh`) say it also sets this reach.
   - Stems already in the ledger, still standing, or a role session's dated
     stem stay excluded as today.
2. **Risk order** (`joharness.sh:conduct_sample`). Sort the candidates by
   these keys, compared in order:
   1. Tier: the plan's `agent:` read at `<retire sha>^:docs/plans/<plan>.md`,
      with `<plan>` taken from the workstream file's `plan:` at
      `<retire sha>^`. `haiku` and `sonnet` sort first (no plan-checker ran),
      `opus` and `fable` next. `plan: none`, research, requirement, or no plan
      file at that commit sort last.
   2. Touched harness code: the retire range changed `joharness.sh` or a path
      under `.agents/harness/` (`git log --first-parent --name-only` over the
      `claim^..retire` range conduct.md §2 already uses, so a reconcile
      merge of the base branch counts nothing) sorts before one that did not.
   3. Tie-break: lowest sha1 of the stem, as today, so a re-run picks the same
      set and a test can assert it.

   `JOHARNESS_CONDUCT_SAMPLE` still caps the count; `0` is still off.
3. **Rate on the dispatch line.** Every dispatch `conduct   :` line but
   `UNREADABLE` (off, IN FLIGHT, DUE, due nothing to sample, not due) ends
   with the tally's C1 rate: `; C1 CONCERN <n>% of <m>`. `<m>` counts FINE
   plus CONCERN only, because NO EVIDENCE is not a verdict on the gates.
   `conduct_tally`'s `CONCERN rate` takes the same `<m>`, so the two never
   disagree, and prints it: `CONCERN rate <n>% of <m> (NO EVIDENCE is no
   verdict)`. With no ledger rows the lines end with `; no runs yet`; rows
   but no FINE or CONCERN = `0% of 0`; a ledger that cannot be read adds
   nothing (its own UNREADABLE is the tally's).
4. **Text that names the old order:**
   - the `JOHARNESS_CONDUCT_SAMPLE` row in orchestrated.md;
   - `cmd_conduct`'s printed "lowest sha1(<stem>) first";
   - conduct.md, if it describes the sample.

   Each now states the window and the three keys. The knob default and
   meaning are unchanged.

## Assumptions

- A1: The sample is all retired history sorted by sha1 of the stem —
  evidence: `joharness.sh:conduct_candidates`, `joharness.sh:conduct_sample`
  — confidence: high.
- A2: `conduct_age_h` dates the ledger's last landing on the base branch's
  first-parent line — evidence: `joharness.sh:conduct_age_h` — confidence:
  high.
- A3: `conduct_rows` reads verdict columns by header name, so the rate can
  reuse `conduct_tally`'s parse — evidence: `joharness.sh:conduct_rows` —
  confidence: high.
- A4: The conduct selftest cases sit in scout.sh. One needle pins the old
  order: "the sample is the three lowest sha1(<stem>)" — evidence:
  `grep -n 'lowest sha1' .agents/harness/selftest/scout.sh` — confidence: high.

## Out of scope

- New questions (C2) and any test running: research conduct-c2-design.
- Retro reading conduct rows: plan retro-audit-and-trace.
- A due-early alarm on the rate. Its back-to-back cost needs the research
  first.
- `docs/conduct-log.md` format: unchanged.
- Core paths, new knobs.

## Acceptance

```bash
./joharness.sh dispatch | grep '^conduct   :'   # ends with "C1 CONCERN <n>% of <m>" as origin/main's ledger counts (3 FINE rows at writing: "0% of 3"); no rate = not done
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- New selftest cases in `.agents/harness/selftest/scout.sh`, each failing
  without its change:
  - a stem retired before the ledger's last landing is not sampled;
  - with no ledger, a stem retired outside `JOHARNESS_CONDUCT_HOURS` is not
    sampled;
  - a sonnet-tier stem sorts before an opus one;
  - between two of the same tier, a stem that touched `joharness.sh` sorts
    first;
  - a `plan: none` stem sorts last;
  - the dispatch line prints the rate, and excludes NO EVIDENCE from `<m>`.
- The old sha1 needle is rewritten to the new order, never deleted.
- The existing conduct fixture dates its retires 2026-02-10 and lands its
  ledger after them: under the window those cases sample nothing. Re-date
  `cretire` to recent hours and retire stems after the ledger lands, so each
  existing case still asserts what it did. A later fixed-date commit on the
  first-parent line moves the no-ledger cut point past them: date it now
  too (scout.sh's foxtrot, retro.sh's zulu retire). The tally's `CONCERN rate 33%`
  needle becomes `50% of 2` (NO EVIDENCE out of `<m>`).
- Consumer side (SHIPS): after its next sync a consumer runs
  `./joharness.sh ci` → `ci: pass`.

## Where to look

- `joharness.sh:conduct_candidates`: the candidate source.
- `joharness.sh:conduct_sample`: the ordering.
- `joharness.sh:conduct_age_h`: the ledger landing the window starts at.
- `joharness.sh:conduct_tally`: the rate's parse.
- `.claude/commands/conduct.md:Read, per sampled stem`: how a stem's plan
  is found at `retire^`.
- `.agents/harness/selftest/scout.sh:conduct cycle`: the existing cases.

## Traps

- `.agents/harness/selftest/orchestrated.sh` folds orchestrated.md into
  needles. Change a pinned row's needle with the row, never skip it.
- `knobs-declared.sh` compares the knob table's default to KNOBS exactly:
  leave the `| \`JOHARNESS_CONDUCT_SAMPLE\` | 3 |` cells intact.
- conduct.md is under a reading budget (6668 + 10%).
- Never skip, disable or quarantine a test to get green.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope
  manager`, `bare role title`.
