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
next: retire this file and the plan, open the pull request, merge when green
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

Sonnet depth: `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at sonnet — one reader that did not write it.
Findings written before their fix, committed with it.

- r1: (verifier) the guard that stops `write_decided_keys` rewriting
  `JOHARNESS_MODE` under reconfigure was unpinned: `mutate` on it reported
  NOTHING REDDED, and the verifier reproduced the consequence by hand —
  `--reconfigure --review off` against an unsupervised child wrote
  `JOHARNESS_MODE=supervised` while printing "nothing else touched". No
  case gave reconfigure a non-autonomy flag against such a child. (fixed —
  three cases do now, and `mutate` on the same line reds all three)
- r2: (verifier) the heartbeat reminder printed TWICE for
  `--reconfigure --mode unsupervised`, against the "said once" comment on
  the copy that already existed: the pre-existing warn fires on the
  resolved value for every run shape, so the one added in the reconfigure
  block was redundant. (fixed — removed, and a case counts the line)
- r3: (code-review) `--reconfigure --env <layer>` wrote a selection the
  child does not carry, said "nothing else touched" and exited 0 — leaving
  it reporting the layer as selected and falling back to none at every
  session start, which is the state `joharness.sh:cmd_env` already warns
  about, reached without a word. (fixed — a warning naming the sync, and
  the question's own wording now says the layer arrives at the next sync)
- r4: (code-review) `--env` was validated against canonical even under
  reconfigure, which ships nothing, so a consumer's OWN layer was refused
  by the flag while the question accepts it as the value in force. (fixed
  — one `layer_valid`, and under reconfigure the child's tree counts; a
  name neither side has is still refused, naming both)
- r5: (session) adding the r1 case turned a later assertion stale — the
  dry-run case asserted the review key was still `on` after the new case
  had set it `off`. A case that passes because of what ran before it is
  not pinning what it names. (fixed — the dry run now asks for the
  opposite of what the conf holds)

## Blockers

None.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh:interview`, `:write_decided_keys`.
- `.agents/docs/consumer-repos.md` — the two routes this adds a third to.
