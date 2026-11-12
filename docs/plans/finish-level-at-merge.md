---
plan: finish-level-at-merge
urgency: normal
agent: opus
effort: high
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/checks.sh, .claude/commands/manager.md, .agents/harness/AGENTS.md, shared:.agents/docs/consumer-repos.md
---

## Goal

Under `JOHARNESS_CHECKS=local`, step 7's "branch 0 behind fresh-fetched
`origin/main`" is measured once, when `finish` starts. A 20-30 minute run
plus the pull request calls leave a window in which the base moves unseen,
and the merge lands base commits no check ran on (chrsctl/gx PR #1550, base
red for every branch, gx #1553). Make the level condition a measurement at
the end of `finish` and again at the merge call. Settled in
`.agents/docs/consumer-repos.md` § Local checks, "What a local pass
certifies" (research `finish-pass-certifies-level-at-merge`).

## Scope

- `joharness.sh:checks_gate`: after the suites, when `rc` is 0, fetch the base
  again (same `HANDOVER_FETCH` switch and `tmo` bound as the first fetch) and
  compare `rev-parse $ref` with the pinned `tip`. Moved and HEAD now behind:
  print `BEHIND` with the count and `checks_outrun`'s line (it reads the green
  this run just wrote, so it prints `OUTRUN`), and return red. The certificate
  and green file this run wrote stay: the next `finish` after the merge of
  `origin/main` is a CATCH-UP or RETEST from them. A fetch that fails prints
  that the end-of-run level is unmeasured, and stays green (as the first
  fetch does).
- `.agents/harness/selftest/checks.sh`: a fixture where the base gains a
  commit while `local-check` runs (the check itself commits to the fixture's
  origin) reds `finish` with `OUTRUN`; the next `finish` after merging the
  base prints `CATCH-UP`. Fails without the change.
- `.claude/commands/manager.md` §4 and `.agents/harness/AGENTS.md` step 7: right
  before `merge_pull_request`, `git fetch origin main && git merge-base
  --is-ancestor origin/main HEAD`; non-zero = behind, back to the finish loop
  (no merge). One line each.
- `.agents/docs/consumer-repos.md` § Local checks: replace "Plan
  `finish-level-at-merge` makes it a measurement" with what now holds.

## Assumptions

- A1: `checks_gate` fetches the base once, before the refusals, and nothing
  after the suites re-measures it. — evidence: `joharness.sh:checks_gate`
  (`fresh="fetched just now"`, the only `fetch` in the function) —
  confidence: high.
- A2: `checks_outrun` prints `OUTRUN` when the green file names HEAD itself,
  so the end-of-run check must run AFTER this run writes its green file. —
  evidence: `joharness.sh:checks_outrun` (`rev-parse HEAD` = `$gh`) —
  confidence: high.
- A3: The comment "a fetch mid-run would certify an untested one" is about
  the certificate's `base=`, which stays the pinned `tip`; a fetch after the
  certificate is written does not change it. — evidence:
  `joharness.sh:checks_gate` (`printf 'head=%s\nbase=%s\n' "$pin" "$tip"`) —
  confidence: high.

## Out of scope

- Branch protection or any `.github/` change (core path, a human's).
- CATCH-UP / RETEST conditions, `JOHARNESS_CATCHUP_COMMITS`, STARVED counting.
- github-mode `finish` (it measures no behind as a red).

## Acceptance

```
./joharness.sh ci          # ci: pass
./joharness.sh verify      # 0 failed
bash .agents/harness/selftest/checks.sh   # the new base-moved-mid-run case passes
```

## Where to look

- `joharness.sh:checks_gate` — the single fetch, the `tip`/`pin` pins, the certificate write.
- `joharness.sh:checks_outrun` — the OUTRUN/NOT OUTRUN line.
- `.agents/harness/selftest/checks.sh:kc_finish` — fixture helper for local-mode finish.

## Traps

- Never skip, disable or quarantine a test to get green.
- `.github/` and `joharness.conf` are core paths: not this plan.
