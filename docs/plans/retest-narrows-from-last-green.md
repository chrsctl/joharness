---
plan: retest-narrows-from-last-green
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/docs/consumer-repos.md
---

## Goal

`finish` under `JOHARNESS_CHECKS=local` starves on a busy base. The retest set
is measured from the certificate `C` every lap, so a path that both sides
changed ONCE stays in the set on every later lap, even when the base never
touches it again and the previous lap retested exactly that content green.
In a consumer whose shared path feeds every suite, each lap is a full-cost
retest (~22 min), the base moves inside it, and the loop never ends. Make a
lap retest only what changed since the last green retest of the same chain,
keeping `C` as the root and `JOHARNESS_CATCHUP_COMMITS` counted from `C`.

Measured (chrsctl/gx PR #1990, branch `claude/go-skeleton`, 2026-11-20):
certificate at `7c8eae1`; 9 merge laps 17:29-20:39 UTC, each ~23 min, none
merged. Every lap's set (`comm -12` of `mb..H0` and `mb..base`) holds
`platform/tests/served.py`, which gx's `tools/localcheck/scope.py` maps to
`crm` (every suite). Base changed `served.py` between laps only at `c0051f8`,
`690fe05` and `5947d1f`; at `2d1584d`, `8621c68` and `bdf25f3` it did not,
so those three laps re-ran the full CRM set on content already retested
green.

## Scope

- `joharness.sh` — `checks_gate` / `checks_local_check`: after a green
  SCOPED RETEST, write `<git-dir>/joharness-retest-green` (`from=<C head>`,
  `head=<pinned HEAD>`, `base=<pinned tip>`); remove it whenever a full run
  starts or `C` changes. `checks_catch_up`: when that file names the current
  `C` and its head is an ancestor of HEAD, drop from `R` every path `p` with
  BOTH (a) `git diff --name-only <green base> <ref> -- p` empty and (b) the
  blob of `p` at HEAD equal to its blob at the green head (absent at both
  counts as equal). Print the dropped count on the RETEST line
  (`… <k> path(s) to retest (<d> carried from <sha9>)`). An empty narrowed `R`
  is a CATCH-UP. Every existing refusal is unchanged and still measured from
  `C`.
- `.agents/docs/consumer-repos.md` § Local checks, "The finish loop" step 3:
  replace "measures from `C`, never from the previous retest" with the rule
  above and its why (the measurement in Goal). Consumer contract unchanged:
  same variables, same SCOPED marker; a scoped green still never moves `C`.
- `joharness.sh` selftest (where `checks_catch_up` is exercised): cases for
  (1) narrowed path dropped, (2) base changed `p` again → kept,
  (3) hand-edited `p` since the green head → kept, (4) green file from another
  `C` → ignored, (5) full run removes the file.

## Assumptions

- A1: the retest set is recomputed from `C` on every lap — evidence: `joharness.sh:checks_catch_up` (`mb = merge-base(ch, ref)`, `branch`/`base` from `mb`) — confidence: high
- A2: a scoped green writes no certificate and leaves no record of what it retested — evidence: `joharness.sh:checks_local_check` (`CHECKS_SCOPED=1`), `.agents/docs/consumer-repos.md` "A scoped green certifies nothing" — confidence: high
- A3: dropping `p` is as sound as RETEST itself: RETEST's premise is that only paths changed on both sides interact; a `p` whose HEAD content and base content both equal what the last green retest ran has no new interaction — evidence: reasoning on the doc's step 3 premise; the verifier must try to break it — confidence: medium

## Out of scope

- Moving `C` on a scoped green, or chaining the bound from a retest. The root
  stays the full run; `JOHARNESS_CATCHUP_COMMITS` stays counted from `C`.
- Any change to a consumer's `local-check` or `scope.py` (gx's own follow-up:
  `.md` paths under `platform/` mapping to `crm`).
- A merge queue / finish lock across sessions.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- The five selftest cases above, each FAILING with the narrowing reverted.
- Replay on gx: in a clone of chrsctl/gx with a certificate written for
  `7c8eae1` and a green-retest file for lap `2d1584d`, `finish`'s RETEST line
  on `8621c68` drops `platform/tests/served.py` (record the command and its
  output in the pull request).

## Where to look

- `joharness.sh:checks_catch_up` — the set `R`.
- `joharness.sh:checks_local_check` — `CHECKS_SCOPED`, where the green file is written.
- `joharness.sh:checks_gate` — certificate writes (`head=` / `base=`), where the file is removed.
- `.agents/docs/consumer-repos.md` — "The finish loop".

## Traps

- NEVER skip, disable or quarantine a test to get green.
- A green file from a red, killed or bounded run must never exist: write it
  only after the scoped green, remove it before every run.
- Harness fix lands here first, then syncs to consumers; never edit a
  consumer's copy.
