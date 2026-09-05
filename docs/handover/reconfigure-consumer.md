---
workstream: reconfigure-consumer
status: in-progress
branch: claude/unsupervised-orchestrated-mode-tzdvw2
pr: none
plan: reconfigure-consumer
issue: none
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
agent: sonnet
updated: 2026-09-05
next: Build the flag, the third mode and the cases; then ci, review, retire, pull request
---

## Goal

A switch that re-asks every question in an existing child, so a consumer's
operator can change a decision without hand-editing `joharness.conf`.
Requester's words, 2026-09-05: "Add switch mode option to reask all question
in child".

## Decisions

- The flag goes on `bootstrap-consumer.sh`, not the sync engine. That script
  already owns the interview, the validator and the writer; putting a second
  interview in the sync is the copy `conf-keys.sh` exists to prevent, and its
  own header says a third copy is how two readers of one fact disagree.
- `--reconfigure` is a third `MODE`, conf-only: interview, then
  `write_decided_keys`. No sync, no seed, no purge — so the refusal that
  protects a consumer's live work is not relaxed, only routed around for a
  run that cannot touch that work.
- Under reconfigure the autonomy question offers the CHILD's own value; at
  first contact it still offers supervised. The always-supervised rule exists
  because a clone carries canonical's mid-attempt flip; an established child's
  line was written by its own bootstrap, so it is that repo's answer.
- Branch re-cut from `main` after PR 213 merged: a merged pull request is
  finished and cannot carry new work.

## Rejected

- Re-asking from the sync engine. Its conf-keys stage answers "this key is
  ABSENT, write the default?"; re-deciding a key that is already answered is
  a different question and wants the interview's explanations.
- Allowing a re-bootstrap. The refusal exists because whole-clone's purge
  would eat a consumer's live plans and handover; nothing here needs that.

## Review

## Blockers

None.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh:interview`, `:write_decided_keys`.
- `.agents/docs/consumer-repos.md` — the two routes this adds a third to.
