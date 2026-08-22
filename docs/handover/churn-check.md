---
workstream: churn-check
status: in-progress
branch: claude/churn-check-neiogl
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
agent: sonnet
updated: 2026-08-22
next: Derive the churn metric in ci and the handover hook, cover in selftest, backtest table into the PR
---

## Goal

The review-churn rule (docs/agent-selection.md, added in #16) asks the
session to notice that a fix undid an earlier fix and escalate to a research
step. The session inside the churn is the one least able to see it: the
sync-tool branch ran twelve consecutive "Harden per review round N" commits
over two hours before the pattern was named by a human afterwards. Git had
the evidence the whole time. Derive it: a churn measure in `joharness.sh ci`
(which that loop ran every round) and a per-branch churn line in the
handover hook, so both the session and the human orchestrator see the
pattern while it is still cheap.

## Decisions

- Metric = max commits touching one file since merge-base, excluding
  `docs/(handover|plans|product)/` — the protocol REQUIRES touching the
  workstream file every commit, so those paths are signal of compliance,
  not churn. The unfiltered metric flags #8's branch at 6 for exactly that
  reason; filtered it drops to 4.
- Threshold 5, `JOHARNESS_CHURN_THRESHOLD` to override. Backtested against
  all 17 merges on main: the sync-tool branch peaks at 13, every other
  branch at <= 4. Zero false positives on history; the real case trips at
  its 5th touch, ~2h before its 12th round.
- Warning, never a red gate. The rule's escalation lever is tier/effort,
  and whether churn is real is a judgment call - the check makes the
  pattern visible where the loop already is (ci runs each round), it does
  not take the decision.
- ci skips quietly with a note on shallow checkouts (GitHub's fetch-depth 1
  has no merge-base); the primary firing point is the local run the loop
  mandates before every PR.

## Rejected

- Detecting fix-undoes-fix by line-level diff intersection (git log -L).
  Precise but expensive and fragile; the file-touch proxy separated the
  real case from all history at 13 vs 4 without it. Revisit only if the
  proxy misfires in practice.
- Counting "review round" commit subjects. Free-text convention; the next
  churn will phrase it differently. File touches are not a convention.
- A stored per-branch counter. Derived state, rots; the whole point is
  that git already holds the record (docs/graph.md doctrine).

## Blockers

None.

## Where to look

- `joharness.sh:cmd_ci` — the churn section; `churn_top` helper.
- `harness/handover-context.sh` — per-branch churn line in the other-branch
  loop.
- `docs/agent-selection.md` — the rule this operationalizes.
