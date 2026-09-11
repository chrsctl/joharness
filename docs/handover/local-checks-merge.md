---
workstream: local-checks-merge
status: in-progress
branch: claude/skip-github-actions-wait-jdd3bn
pr: 236
plan: none
issue: none
session: https://claude.ai/code/session_018BqX6Ux5hvSAm5AQ725mDe
agent: opus
updated: 2026-09-11
next: Review the ci.yml gate, record it, retire this file again.
---

## Goal

Second increment on an open pull request, at the requester's word: "if you
run out of GitHub action minutes you should be able to switch". The knob as
merged saves the WAIT and not the minutes — `ci.yml` still runs on every
pull request and every push to `main`, whatever a session does locally. So
the same name gets a second home: a GitHub repository variable the workflow
itself reads.

## Decisions

- One name, two homes, chosen over a second name. `JOHARNESS_CHECKS` in
  `joharness.conf` says what the SESSION does; `vars.JOHARNESS_CHECKS` in
  the repository's variables says whether GITHUB spends minutes. Two readers
  on two machines, one word for the question they both answer. A second name
  would let them disagree silently, and the only reason to want that
  disagreement is a case nobody has yet.
- Repository variable, not the tracked conf: the workflow cannot read a file
  from the branch before deciding whether to start, and a switch that needs a
  commit is no use to somebody who has already run out of minutes.
- The gate is on the `lint` job, not on `on:`. A workflow-level `if` does not
  exist, and gating the trigger would need a commit to restore.
- A skipped job reports SKIPPED, never success. Branch protection requiring
  this check therefore holds the merge button while the variable is set —
  named in the workflow and in the conf, because it is the trade, not a bug.
- Not read by `joharness.sh` at all. The entrypoint has no GitHub token and
  no business asking; the workflow is the only reader of the variable, the
  conf is the only reader of the key.

## Rejected

- Gating on `on:` or deleting the trigger. Both need a commit to undo, which
  is the thing the requester is trying to avoid at the moment minutes run out.
- A second switch name (`JOHARNESS_CI_RUNS`, say). Independence nobody has
  asked for, paid for in every document that then has to explain which is
  which.
- Having `finish` read the repository variable through the API to warn when
  the two disagree. A gate that needs a token is a gate a consumer without
  one cannot run — the same reason this command reads no checks today.

## Review

Pending — step 5 not reached for this increment.

## Blockers

None.

## Where to look

- `.github/workflows/ci.yml:lint` — the job the variable gates.
- `joharness.conf:JOHARNESS_CHECKS` — the other home of the same name.
- `.agents/scripts/bootstrap-consumer.sh:788` — ci.yml is SEEDED verbatim at
  bootstrap and never synced after, so a consumer older than this carries the
  ungated workflow.
