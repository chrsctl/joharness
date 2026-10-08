---
research: first-copy-of-the-exit-rule
urgency: normal
agent: sonnet
effort: low
graduates: .claude/commands/orchestrate.md
---

<!--
Issue #303. Reported from a consumer by the route
`.claude/commands/upstream-report.md` names; canonical decides. The verdict
line the issue opens with is a consumer run's output and is marked
reported-not-re-measured there and here. Every claim about where the rule is
written was read from this repo's source at `cb0028e` — and the one
observation about WHEN a session sees the description was taken in this
session.
-->

## Question

Should `orchestrate.md`'s `description` carry the qualifier its body carries —
exit at DRAINED only with nothing in flight?

Whether a selftest should pin it is under `## What would settle it`: it is the
one part still open, not a second question.

## Echo

The exit rule has two readings and the file is right about both: an empty queue
with managers still running is not the exit; an empty queue with nothing
running is. The body says so, the verdict string says so, the session-start
banner says so, and a selftest pins it. One line does not: the command file's
own `description`, which stops at *"exit at DRAINED"*.

What makes this more than a typo is WHEN each copy arrives. A command file's
`description` is handed to a session in its available-skills listing before the
session opens any file; the qualified rule is hundreds of lines into a file the
role reads afterwards. So the unqualified rule is first and the qualified one is
second, and a role that acts on the first copy exits with its fleet running.

What rests on the answer is small and the question is not whether the fix is
right — it is whether the gate is worth its line, and the issue already
establishes that the obvious gate cannot be used.

## Sweep

`goal-directed` — enough to confirm every place the rule is written, that one
of them disagrees, that the disagreeing one is read first, and which gate can
hold it. Not a survey of command descriptions, and not a re-opening of whether
`DRAINED` is the right token: the issue declines that and so does this.

## What would settle it

- **Whether the description is read before the body, in fact rather than in
  principle.** Settled by an observation of a real session's listing, not by
  reasoning about how listings work.
- **Whether a gate is owed.** The repo's practice for a string whose exact
  wording is load-bearing is a selftest `expect`, and one already exists for
  the verdict. Settled either by a case pinning the description's qualifier, or
  by the finding that an unpinned one-line fix is enough here because the
  string has no other reader.
- **That the glossary is NOT the gate.** The issue's third point is a negative
  result worth keeping: the lint matches literally and as a substring, and the
  canonical phrase CONTAINS the phrase that would be banned. Settled by reading
  the lint's own rule rather than by trying it.

Written before the reads below: a fix that qualifies the description and leaves
the body, the banner and the verdict untouched is the whole fix if and only if
all three already agree — so the first thing to check is that they do, and not
that the description is wrong.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    sed -n '1,5p' .claude/commands/orchestrate.md
    grep -n "nothing in flight" joharness.sh .claude/commands/orchestrate.md \
      .agents/harness/selftest/dispatch.sh
    sed -n '8678,8682p' joharness.sh          # the comment over the verdict block
    sed -n '8731p'      joharness.sh          # DRAINED with managers in flight
    sed -n '9111p'      joharness.sh          # the session-start banner
    sed -n '638,642p'   .claude/commands/orchestrate.md
    grep -n "not the exit" .agents/harness/selftest/dispatch.sh
    sed -n '2084,2090p' joharness.sh          # GLOSSARY_PATHS
    sed -n "$(grep -n 'What ci checks' .agents/docs/glossary.md | cut -d: -f1),+8p" \
      .agents/docs/glossary.md

And one observation that is not a source read, recorded because it is the
evidence for the first bullet above: this session's own available-skills
listing, 2026-10-08.

## Findings

- **The rule is written four times and agrees three times.** At `cb0028e`:
  `joharness.sh:8731` prints `DRAINED — nothing free; %s manager(s) in flight:
  keep the health pass going`; the comment over that block says it outright —
  *"DRAINED with managers in flight is NOT the exit: the queue is empty, the
  work is not"* (`joharness.sh:8679-8681`); `joharness.sh:9111` is the banner,
  *"exits at DRAINED with nothing in flight"*; and
  `.claude/commands/orchestrate.md:638` splits the readings, `DRAINED —
  nothing free, nothing in flight: exit` against *"`DRAINED — … in flight` …
  = schedule, no spawn"*. A selftest pins the verdict:
  `.agents/harness/selftest/dispatch.sh:465`, named *"nothing free with a
  manager in flight is not the exit"*. Every line number in the issue that I
  could check still resolves at `cb0028e`.

- **The fourth copy is unqualified, verbatim.** `cb0028e`,
  `.claude/commands/orchestrate.md:2`:

      description: Orchestrator loop — dispatch the queue to manager sessions under the cap, watch their health, exit at DRAINED

- **It is read before any file, and this is the one claim I could measure
  directly.** The description above appears verbatim in THIS session's
  available-skills listing (observed 2026-10-08, in a session whose mode banner
  is orchestrated), delivered with the system prompt — so before the role
  opened `orchestrate.md`, before `dispatch` ran, and before the body's
  qualifier at line 638 was reachable. The issue's claim that the unqualified
  copy arrives first does not rest on the consumer's run; it reproduces in any
  session of this repo that is handed the listing.

- **The glossary cannot gate it, and the reason generalises.** `cb0028e`:
  `.claude/commands/*` IS inside `GLOSSARY_PATHS`, so a row there would be
  scanned — but `.agents/docs/glossary.md`, "What ci checks", says each `Not
  this` entry is matched *"LITERALLY, as a SUBSTRING, case-blind"*, and *"A
  bare word bans every phrase containing it."* The fixed spelling
  (`exit at DRAINED with nothing in flight`) contains the phrase that would
  have to be banned (`exit at DRAINED`), so the row would red the correct
  sentence. The issue reached this conclusion and it holds against the lint's
  own text.

- **Reported, not re-measured here: the run that occasioned it.** A consumer's
  orchestrated run on 2026-10-07 printed `verdict   : DRAINED — nothing free;
  4 manager(s) in flight: keep the health pass going` while four managers were
  running, and by its own report kept the health pass going — which is what
  the verdict told it to do. Nothing here claims a session exited on the word.
  The defect is that the first copy of the rule a session is handed is the
  unqualified one.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

**This one is a plan in all but frontmatter, and it should be said plainly
rather than dressed as a question.** The fix is the banner's own wording copied
into the description — one line, no behaviour change, nothing to measure after.
What is genuinely open is only the second bullet of `## What would settle it`:
whether a selftest `expect` on the description earns its line. Two readings,
both defensible — the repo pins the verdict string because a role branches on
it, and nothing branches on a description; against that, the description is the
copy that arrives first, which is the whole finding.

So whoever takes this should expect to spend its time on the gate and not on
the sentence. If the answer is "no gate", that is a result and belongs in the
graduation, because the next reader will otherwise re-derive the glossary dead
end the issue already walked.

**The independent reader's position, recorded because it is stronger than this
node's own flag: this should be a PLAN, not a node.** Its argument —
`effort: low`, `agent: sonnet`, a one-line fix copied from a string already in
the tree, and a gate question that *"Implementation yours"* under
`## Decide alone` already assigns to the implementer. It also counted the
precedent this conversion cites: `605557b7` routed FOUR of five issues to
plans and two to research, where this batch routed nine of nine to research.
That ratio is the fact canonical should weigh; the conversion was asked for as
nodes, so nothing here was converted, and this paragraph is the flag rather
than a decision.

`.claude/commands/` is a protocol path (`./joharness.sh protocol-paths`), so the
branch that answers this is supervised.

## Verification

Second context: `.claude/agents/verifier.md` at opus, which checked every line
number and every quoted string against source.

- **The rule is written four times and three agree** — GROUNDED. All six
  citations exact.
- **The fourth copy is unqualified** — GROUNDED.
- **It is read before any file** — WEAK, and the reason is structural rather
  than doubtful: the evidence is this session's own available-skills listing,
  and the second context has no way to observe another session's listing. The
  reader flagged exactly this, noting that the `## What would settle it` bullet
  demands an observation rather than reasoning, and that the Method marks it as
  not a source read. It also confirmed the one checkable part — `joharness.conf`
  does carry `JOHARNESS_MODE=orchestrated`. Anyone can re-take the observation
  in one session of this repo; no verifier can.
- **The glossary cannot gate it** — GROUNDED, including
  `.claude/commands/*` being inside `GLOSSARY_PATHS` and the substring rule.
- **The reported verdict line** — WEAK.
- **That this should be a plan rather than a node** — the second context's
  judgement, recorded in `## Consequence for the queue` rather than resolved
  here.

Standing limit on every claim below that came from the issue rather than from
this tree: `.claude/agents/verifier.md` declares `tools: Read, Grep, Glob,
Bash` and has no control-plane call, so a reported fleet reading can be
re-read against the issue and never re-sampled. That is issue #267, planned as
`docs/plans/verifier-cannot-read-the-plane.md`. Every such claim is marked
WEAK for that reason and not because anything contradicted it; the second
context did confirm each number against the issue it came from, and found no
invented one anywhere in this batch.

## Graduates to

`.claude/commands/orchestrate.md` — its own `description` line is the defect,
and its body already holds the correct sentence to copy. The negative result
about the glossary belongs with it in one comment or one line of the pull
request that lands the fix: it is the kind of fact that costs a session an hour
to rediscover and one sentence to keep, and the file it would be rediscovered
from (`.agents/docs/glossary.md`, "What ci checks") already states the rule
that makes it true, so nothing new is owed there.
