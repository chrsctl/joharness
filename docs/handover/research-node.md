---
workstream: research-node
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: research-node
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Fold the verifier round in, then retire and open the PR.
---

## Goal

Give research the standing of a plan: a file shape, a row in the graph, a
line in the queue, a lint. Not a research methodology — the node is what
makes findings survive the session that made them.

## Decisions

- Recounted before building, as the plan tells its reader to: `ls
  docs/research/*.md | wc -l` on `origin/main` b482364, 2026-08-29 → **4**,
  the same four the plan names. Its "went stale within a day" warning has
  not fired again. Their frontmatter already agrees on five fields
  (`research`, `urgency`, `agent`, `effort`, `graduates`) — that is the
  template's first draft, not an invention.

## Decisions (continued)

- **Research counts as queue work at the EDGE, not only in the listing.**
  The plan's scope for the hook says "listed beside plans" and stops there.
  Listing alone leaves two false negatives: no plans plus open questions
  printed "edge reached: done", and no FREE plan plus open questions did the
  same — under unsupervised that reads as an order to invent a backlog while
  real queue work sits unclaimed. Both branches now check the question count.
- **Questions are not folded into the plan `rows` table.** They are ranked
  the same way (urgent, then oldest) but carry no `needs`, no `scope` and no
  claim, so a shared row would have four empty columns inviting somebody to
  fill them.
- **Verification records who and where, never when.** The plan names this
  collision (provenance rule against the requirement's "who checked") and
  says decide once, in the README. Decided there; the same commit removed
  the hand-written `Checked 2026-08-25` from all four instances and changed
  nothing else in them.

## Rejected

- (nothing yet)

## Review

Round 1, this session. Refutation: `git checkout origin/main -- joharness.sh
.agents/harness/queue-context.sh`, keeping the docs and the tests — 787
passed / 15 failed, against 802 / 0 with the code.

- r1: the queue hook LISTED questions and stopped there, which is all the
  plan's scope names. Two edges then lied: no plans plus an open question
  printed "edge reached: done", and no FREE plan plus an open question did
  the same. Under `JOHARNESS_MODE=unsupervised` that edge is an order to
  invent a backlog, so the hook would have ordered make-work while real
  queue work sat unclaimed. (fixed: both branches count questions)
- r2: the fixture cleanup ran `git rm` on the last file in `${lwork}/docs/plans`,
  and git removes a directory when its last tracked file goes. Every later
  case writes there with `cat >`, which then failed — and each case read the
  PREVIOUS state's lint output and reported a mismatch none of them named.
  Four green cases went red for the wrong reason. Third time this session for
  this exact shape (PR 123 r9). (fixed: `mkdir -p` after the cleanup commit,
  with the reason)
- r3: five of the twenty new cases pass with the code reverted. Four are
  refutes — a hook that knows nothing about research prints nothing about
  research, so they cannot fail there — and one is the second half of a pair
  whose first half does fail. Kept and labelled as what they are, because the
  alternative (deleting them) loses the quiet-when-unused guarantee, and the
  alternative to labelling is a reader counting them as evidence. (fixed:
  labels)
- r1 and r2 were recorded AFTER their fixes, in the commit after. The
  protocol says before, same commit. Noted rather than tidied away.

## Blockers

None.

## Where to look

- `.agents/docs/plans/README.md` + `TEMPLATE.md` — the shape to mirror.
- `.agents/docs/graph.md` Nodes/Edges — two tables gaining rows; Rules
  forbids a store, an index, a status field.
- `joharness.sh:lint_graph` — reuse, do not parallel.
- `.agents/harness/queue-context.sh` — where `blocked by:` is printed.
- `docs/research/*.md` — the four instances; `glossary-enforcement` has no
  `## Method` and is the one known divergence.
