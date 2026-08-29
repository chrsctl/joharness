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

Round 2, `.claude/agents/verifier.md` at opus, fed round 1's results. 15
findings, 12 verified against fixtures it built. Every one below is a real
defect or a false claim of mine except r18, which did not reproduce as filed
and is recorded as checked.

- r4: **an unreadable research file made the hook report the edge as
  reached.** `research_count` counted rows, not files, so a zero-byte
  question was silently dropped — no counterpart to the `qc_unreadable`
  guard that exists on the plans path for exactly this. Under unsupervised:
  the full generate-work order over a queue holding an open question. (fixed:
  `qc_research_unreadable`, counted from the file list, suppresses the edge
  and says so)
- r5: **the new "not the edge" branch fell through to a tail naming a free
  plan that does not exist.** The unsupervised edge below it carries a
  comment about having made this exact mistake once; my branch made it again,
  ten lines above the comment. (fixed: the branch prints its own entrypoint
  and exits)
- r6: **unplanned requirements lost the entrypoint when a question was
  open.** I tested research before unplanned, so the hook said "settle a
  question" and then, as a footnote, "requirements outrank both" — an
  entrypoint sentence reversed by its own next line, against "planning
  outranks executing". (fixed: unplanned is tested first)
- r7: **a research file was queue-pickable but not claimable.** `plan:
  <question>` in a workstream was DEAD and reded `ci`; `plan: none` left the
  question listed free for a second session to pick up. That is #119's
  duplicate claim, rebuilt for the new node type, by the same session that
  fixed #119. (fixed: one claim field covers both directories — lint, hook
  and `.agents/docs/handover/TEMPLATE.md` in lockstep)
- r8: **`graduates:` naming a file the graduating pull request will create
  was red on arrival.** The README tells a graduating session to write a NEW
  why-explanation; the lint demanded the target already exist. The plan
  spec'd "names a file that exists" — spec and README cannot both be right,
  and the one that reds honest repos loses. (fixed: the DIRECTORY is the
  gate, a missing file is a warning; a root-level target reded too, because
  stripping the last segment off a name with no slash leaves the name)
- r9: **`./joharness.sh graph` did not render the node this diff adds to
  `graph.md`.** The same file calls that command "whole graph as a picture";
  a declared node type absent from it reads as "no open questions", which is
  the one wrong answer. (fixed: questions, `graduates` edges, and a plan
  blocked on a question rendered blocked)
- r10: **the README miscounted its own provenance** — "six sections from
  practice, three earn their place here". Counted: three instances carry all
  nine headings, one carries eight. Nothing came from here. (fixed)
- r11: **"removed the dates and changed nothing else" was false** — the same
  commit added a nine-line `## Method` to `glossary-enforcement`. Written
  before the migration was finished and never re-read. (fixed, in both places
  it was claimed)
- r12: **the template minted a verdict vocabulary the instances do not use**
  — GROUNDED or WEAK, while two instances mark claims UNGROUNDED, which is
  the verdict the README's own argument leans on. A filled template had no
  word for "refuted". (fixed: three words)
- r13: **the one migrated instance that does not meet the shape was
  unnamed.** `glossary-enforcement`'s Method says "Not recorded" while the
  template says a finding with no command is an opinion. The plan authorised
  the divergence; the README did not carry it, so shape and first fixture
  disagreed in the tree. (fixed: a section naming it, and saying a NEW file
  with an unrecorded method is a file that failed)
- r14: **two ordering answers shipped together** — the docs say questions
  rank beside plans, the hook tail only ever said "top free plan above". A
  question older than every free plan could not be reached from hook output.
  (fixed)
- r15: **a sixth new case passes with the code reverted and a seventh was
  unlabelled** — my r3 said five and four. Recounted. (fixed: labels; the
  count in r3 stands corrected here rather than edited there)
- r16: the shallow-history branch of the new lint had no case while its
  `needs` twin does. A consumer's depth-1 CI could red where no local run
  ever would. (fixed: a case, which cost r17)
- r17: found while fixing r16 — the `commit_all` I added before the shallow
  clone did `git add -A` and swept up a working-tree edit the neighbouring
  case depended on being UNCOMMITTED. Two green cases went red naming
  something else. (fixed: stage the one file)
- r18: **did not reproduce as filed.** "A consumer that already keeps
  freeform notes in `docs/research/*.md` goes red on first sync" was offered
  as context rather than a defect, and it is true — but it is the lint doing
  its job, and the README says what the directory now means. Recorded so
  nobody re-files it.
- r19: fourth occurrence this session of "git removes a directory with its
  last tracked file" (docs/plans twice, docs/handover, docs/research). A file
  that keeps drawing findings is a rule nobody wrote yet
  (`.agents/docs/feedback.md`), so it is code now: `fixture_rm` in the suite
  removes and puts the directories back. (fixed)

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
