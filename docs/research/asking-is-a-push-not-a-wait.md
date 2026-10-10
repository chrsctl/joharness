---
research: asking-is-a-push-not-a-wait
urgency: urgent
agent: sonnet
effort: high
graduates: .agents/harness/AGENTS.md
---

<!--
Issue #304. Reported from a consumer by the route
`.claude/commands/upstream-report.md` names; canonical decides. The 10h hold
is a control-plane and dispatch reading from a live run and could not be
taken here — it is the issue's, marked as such. Everything about what the
instruction files say was read from this repo's source at `cb0028e`, and one
of the issue's own supporting greps did not reproduce.

`urgency: urgent` because the cost recurs on every unattended run and is paid
in a held slot rather than in a wrong file — the reasoning is under
`## Consequence for the queue`, not asserted here.
-->

## Question

Where should the rule that a human decision is a PUSH and not a wait be
written, so that a manager meets it before it stops to ask?

## Echo

Two instruction files give a session near-identical lists of what only a human
decides, and opposite instructions for what to do about it. The file every
session loads says stop and ask. The file a manager loads says write the
question into the workstream file, mark the item blocked, push, exit — and
never wait for an answer in the session.

The manager's version is the correct one, and the harness is built around it:
blocked frees the slot, releases the plan holds, and relays the question to the
orchestrator's report. An in-session ask writes none of that, so the item is
counted as in flight with a frozen head, the plan behind it keeps waiting, and
the question reaches nobody.

What I am asking is not which verb is right — that is settled. It is where the
correct one has to be written to be read in time, and whether anything besides
instruction text is owed. The issue's own answer is one clause in the file every
session reads first, and it is probably right; what it does not establish is
whether the second half of the problem (a manager that asks anyway is
indistinguishable from a live one) belongs to this question or to the detector
questions beside it.

## Sweep

`goal-directed` — enough to establish that the two files disagree, that the
blocked route does what the manager's version claims, and which file a session
reads first. Not a survey of the decide-alone rules, and not an answer to how a
blocked-on-a-question manager should be DETECTED: that is
`docs/research/push-age-is-not-death.md` and
`docs/research/no-ceiling-on-one-item.md`, and the issue says so itself.

## What would settle it

- **Which file reaches a manager first, and whether one clause there is
  enough.** The root instruction file loads before any command file, so a
  clause in it arrives first. What is not settled is whether the clause belongs
  in the decide-alone list (where the categories are) or in the manager
  command's own `## Never` list (where the acts are) — or both, which costs the
  duplication the house style forbids. Settled by naming one and saying why the
  other reader is covered.
- **Whether a rule a session cannot be made to obey is worth the words.** The
  in-session ask is a tool call; no gate sees it. So the clause is advice, and
  the measure of a good answer is whether a literal reader meeting the
  decide-alone list would act on it — not whether something enforces it.
  Settled by reading the resulting sentence as a literal reader would.
- **Whether anything is owed in the mode's own file.** The mode already
  classifies a session asking a question as a finding rather than a stop, and
  its run table records an early run ended by exactly that. If the clause lands
  only in the root file, the mode's file still has the measurement and not the
  rule. Settled by deciding whether that split is correct or is how this came
  back.

Written before the reads below: a fix that adds "never ask" to a spawn prompt
has not answered this question, and the mode's own file forbids it in those
words — the prompt routes, the repository authorises.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    grep -n "Stop and ask ONLY for" .agents/harness/AGENTS.md
    sed -n '208,216p' .agents/harness/AGENTS.md
    sed -n '138,152p' .claude/commands/manage.md
    sed -n "$(grep -n '^## Never' .claude/commands/manage.md | cut -d: -f1),+8p" \
      .claude/commands/manage.md
    git grep -in "askuserquestion"    # zero AT cb0028e, not at this head
    grep -n "holds no slot" joharness.sh
    grep -n "re-asks the question" joharness.sh
    sed -n '8384,8392p' joharness.sh          # a blocked row releases its holds
    sed -n '50,56p'   .agents/docs/orchestrated.md
    sed -n '86,92p'   .agents/docs/orchestrated.md
    sed -n '547,552p' .claude/commands/orchestrate.md

## Findings

- **The two files disagree, verbatim.** `cb0028e`,
  `.agents/harness/AGENTS.md:214`, in the `## Decide alone` block that loads
  for every session:

      - Stop and ask ONLY for: money, credentials, hardware, product direction,
        merge conflict into `main` that does not resolve clean.

  And `.claude/commands/manage.md:144-148`:

      - Stuck on a decision only a human takes (money, credentials, product
        direction, interface, protocol text, conflict that does not resolve
        clean): `status: blocked`, `next:` = the question, push, exit. Never
        wait for an answer in the session — the orchestrator reports it and
        never respawns a blocked item.

  Same categories, opposite instruction. The correct one sits in prose under a
  heading about push cadence, not in `manage.md`'s `## Never` — which at
  `cb0028e` lists a second item, a session of its own, protocol text, a
  requirement, another session's pull request, downgrading tier or effort,
  skipping a test, kicking CI, and trusting a worker's "done". Waiting in the
  session for an answer is not among them.

- **The blocked route does everything the manager's version claims.**
  `cb0028e`: the row prints `BLOCKED: the human's, holds no slot`
  (`joharness.sh:8353`); `n_blocked` is subtracted from the in-flight count the
  verdict uses; and a blocked row's holds are released rather than attributed —
  *"A `blocked` row carries none, because its holds are RELEASED further down"*
  — so the plan behind it stops waiting. The question itself travels: the row
  prints the claim's `next:` line, which is how a blocked manager's words
  reach the orchestrator's report.

- **And a respawn cannot substitute for it, by the code's own account.**
  `cb0028e`, `joharness.sh:8344`: *"respawning it re-asks the question it
  stopped on."* That is why a blocked item is never respawned — and it is also
  why a question-blocked manager that instead ages into the stall path gets a
  successor that asks again: the kill path writes `## Blockers` and a resume
  instruction, never `status: blocked`.

- **The issue's grep did not reproduce, and the claim is STRONGER without it.**
  The issue reports `git grep -i AskUserQuestion` returning one hit at
  `.agents/harness/selftest/bootstrap-consumer.sh:76`, described as an
  unrelated comment about closing stdin. At `cb0028e`, `git grep -in
  "askuserquestion"` returns **zero** hits in the whole tree (re-run against
  any tree carrying this node it returns this node's own lines and nothing
  else, which is why the commit is named); lines 74-78 of
  that file are a comment about the bootstrap asking for a mode when it has a
  terminal, which never names the tool. So the tool is named nowhere in the
  harness at all — the substantive point — and the issue's citation for it was
  a near-miss.

- **The fix cannot be the spawn prompt, and the file says so with a
  measurement under it.** `cb0028e`,
  `.claude/commands/orchestrate.md:547-550`: *"Nothing else: no 'no human is
  watching', no 'never ask', no 'keep going'. The prompt routes; the repository
  authorises."* The reason is in `.agents/docs/orchestrated.md`: measured
  2026-08-31, two sessions spawned with a prompt saying *never ask a human,
  merge your own pull requests, keep going* refused it as a suspected
  injection — *"They were right — that is the shape an injected task has, and a
  claim cannot be its own evidence."*

- **The mode has already classified the event, and has the measurement without
  the rule.** `cb0028e`, `.agents/docs/orchestrated.md:54`: *"Anything else
  that ends a run — a rate limit, a session asking a question, a generation
  that failed to spawn — is a finding, not a stop."* Its run table records
  attempt one, 2026-08-31, 48s, ended with *"no repository attached; both
  sessions asked a human"* — quoted whole, because an earlier draft kept only
  the second half and the first half is a different cause for the same run. So
  what is missing is not the judgement; it is the judgement reaching the file
  where a manager meets the decision.

- **Reported, not re-measured here: the hold.** A manager in a consumer's
  unattended run on 2026-10-07 called an in-tool question and was blocked on it
  for 10+ hours. `dispatch` printed `STALL? no push for 9h` on that row the
  whole time, the slot stayed held, and the one plan waiting behind it never
  started. The issue does not claim which question it asked, or that this
  manager would have written `status: blocked` had the root file said so — and
  neither does this node. Also not claimed there or here: why no kill fired
  across 9h; the stall default is 45 minutes and the health table takes two
  passes, which makes that a different question.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

**Marked `urgent`, and here is the reason rather than the adjective.** Every
other node in this batch costs a wrong reading, a duplicate session or a
re-measurement. This one costs a held slot for as long as the run lasts, it
fires on the file every session in every mode loads, and the measured instance
held one slot for 10+ hours while the item behind it never started. The fix is
also the cheapest in the batch — one clause — so the ratio is what the mark is
about, not the severity alone. Canonical may disagree; the mark is a claim and
this paragraph is its argument.

Two cautions for whoever takes it:

- **Do not touch the spawn prompt**, whatever shape the fix takes. The
  prohibition is explicit and the measurement behind it is two sessions
  correctly refusing their own instructions.
- **Do not widen into the detector.** A manager blocked inside a tool call
  looks exactly like a live one with a frozen head, and that is the signal
  `push-age-is-not-death` and `no-ceiling-on-one-item` are already arguing
  over. This question is about the instruction. A node that answers both
  answers neither.

Note for a parallel wave: a research node has no `scope:`, so the overlap guard
cannot see that this node touches `.agents/harness/AGENTS.md` — the file every
other node's reader also loads. It is the one file in this batch where two
simultaneous answers would collide on the same paragraph.

`.agents/harness/` and `.claude/commands/` are both protocol paths
(`./joharness.sh protocol-paths`), so the branch that answers this is
a human's — whichever of the two files it lands in.

## Verification

Second context: `.claude/agents/verifier.md` at opus.

- **The two files disagree, verbatim** — GROUNDED, both quoted exactly.
- **The blocked route frees the slot, releases the holds and relays the
  question** — GROUNDED, all four source citations re-run.
- **A respawn re-asks the question** — GROUNDED.
- **The issue's grep returns zero hits here** — GROUNDED, and independently
  confirmed in the stronger direction: the reader checked that the issue's
  cited line does not exist and that lines 74-78 are a comment about the
  bootstrap prompting for a mode. Now pinned to `cb0028e`, because this node's
  own text matches the pattern.
- **The spawn prompt is forbidden as the fix, with its measurement** — GROUNDED;
  the reader found the quotation of the run table cut in a way that dropped the
  other cause of that run, now quoted whole.
- **The mode has the measurement without the rule** — GROUNDED.
- **The 10h hold** — WEAK.

Standing limit on every claim below that came from the issue rather than from
this tree: `.claude/agents/verifier.md` declares `tools: Read, Grep, Glob,
Bash` and has no control-plane call, so a reported fleet reading can be
re-read against the issue and never re-sampled. That is issue #267, planned as
`docs/plans/verifier-cannot-read-the-plane.md`. Every such claim is marked
WEAK for that reason and not because anything contradicted it; the second
context did confirm each number against the issue it came from, and found no
invented one anywhere in this batch.

## Graduates to

`.agents/harness/AGENTS.md` — the `## Decide alone` block, because that is the
file a session loads before any command file and the line that currently says
the wrong thing. The house style's own test applies and should be applied
rather than waved at: this file is paid by every session in every mode at every
tier, so the clause has to be shorter than the confusion it removes, and the
WHY (a blocked row frees the slot, relays the question, and is never respawned)
belongs under `.agents/docs/` where it costs nothing until opened. A rule line
alone is what the mode's file already has without the rule, which is how this
arrived.
