---
plan: catch-up-print-merge-count
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/docs/consumer-repos.md
---

## Goal

`checks_catch_up` bounds the base by commits. A consumer whose pull requests
carry several commits each cannot tell from the refusal line how many pull
requests that was. Print the first-parent merge count beside the commit count,
in both the refusal and the `CATCH-UP` line, so the bound can be tuned from
evidence. The knob and its meaning do not change.

## Scope

- `joharness.sh` — `checks_catch_up`: compute `m` = `git rev-list --count --first-parent --merges "${cb}..${ref}"` and print it with `n`.
- `.agents/harness/selftest/checks.sh` — the CATCH-UP block asserts the new text.
- `.agents/docs/consumer-repos.md` — the sentence naming what the refusal prints is already there; adjust if wording differs.

## Assumptions

- A1: the over-bound refusal text is asserted in the selftest — evidence: `.agents/harness/selftest/checks.sh` string `over JOHARNESS_CATCHUP_COMMITS=0` — confidence: high

## Out of scope

- A `JOHARNESS_CATCHUP_MERGES` knob or any change of what the bound counts: no evidence yet that merge count is the better bound; a wider bound widens the semantic-clash window.
- The no-shared-file condition, the one-catch-up-per-full-run rule.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Selftest asserts the refusal reads `... commit(s) (N first-parent merge(s)) of origin/main since, over JOHARNESS_CATCHUP_COMMITS=0` and fails without the change.

## Where to look

- `joharness.sh:checks_catch_up` — the `rev-list --count` bound and the two printf lines.
- `.agents/harness/selftest/checks.sh` — `catch-up: over JOHARNESS_CATCHUP_COMMITS is the full run, named`.

## Traps

- No hard-coded env names in `.agents/harness/`; no skipped tests.
