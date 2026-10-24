---
workstream: hold-requirement
status: in-progress
branch: manage/hold-requirement
pr: none
plan: hold-requirement
issue: none
session: https://claude.ai/code/session_0113FB2pMoHuAQxSUYwpwV7o
agent: sonnet
updated: 2026-10-24
next: Run verifier at sonnet on the diff, record findings, retire workstream file and plan file, open PR.
---

## Goal

Give a requirement optional `needs:` and `hold:` frontmatter so dispatch holds it without a planning slot (plan docs/plans/hold-requirement.md).

## Decisions

- A1..A7: confirmed — hook `unplanned=` block is sole row producer, `drain_requirement` sole offerer, `unplanned_free` read by every go-plan sentence, label tokens trusted downstream (hold reason never enters a label), `lint_existed`/`gr_fields` as described.
- `needs` stems resolve in the hook against a separate `qc_need_stems` (plans, questions, requirements); `qc_item_stems` stays plans+questions because the claim-resolution rule reads it.
- `deferred` line skips rows carrying `claimed on` (in-flight row covers them).

## Rejected

## Review


## Blockers

None.

## Where to look

- `docs/plans/hold-requirement.md` — the plan.
