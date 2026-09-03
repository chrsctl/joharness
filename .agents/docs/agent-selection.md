# Agent selection

Different plans, different agents. Each plan file under `docs/plans/` names
in frontmatter which agent tier implements it (`agent`) and at what effort
(`effort`). This document: the lineup, the selection rules, the model
behavior they rest on. Developed in `chrsctl/redoct` (its PR #3); facts from
Anthropic API reference cached 2026-06-24 — verify against Models API when
stale.

## Lineup

Tiers, not model IDs, in plan frontmatter — IDs change, tiers stay. Current
mapping:

| Tier | ID today | Context | $/MTok in/out | Use for |
| --- | --- | --- | --- | --- |
| haiku | `claude-haiku-4-5` | 200K | 1 / 5 | Mechanical, fully specified, acceptance executable |
| sonnet | `claude-sonnet-5` | 1M | 3 / 15 (intro 2 / 10 through 2026-08-31) | Default. Near-Opus coding + agentic quality |
| opus | `claude-opus-5` | 1M | 5 / 25 | Correctness-critical, invariant reasoning, irreversible-path code |

## Selection rules

- Rules run for EVERY unit of work, not only queue plans. Issue, direct
  ask, generated work — each decomposes into a plan first (Loop step 2),
  so each carries `agent` + `effort` before build. No tier = nobody
  matched a model to the work; do not build it.
- Default = sonnet, effort high.
- haiku when plan is mechanical AND fully specified AND every acceptance
  criterion is a runnable command. One unclear edge = sonnet.
- opus when wrong-but-plausible code is the failure mode: subtle bug passes
  review, ships broken guarantee. A repo's Part 2 prohibitions name these
  areas.
- effort xhigh when plan touches a Part 2 prohibition's territory — same
  reasoning, cheaper lever than a tier jump.
- Under-thinking observed: raise effort or tier, never prompt around it.
- Review depth scales with the plan's tier — the tier already encodes what
  a wrong-but-plausible outcome costs, so the review budget follows it:
  - haiku plan: one `/code-review` pass at default effort. Acceptance is
    executable by definition here; the commands catch what a second pass
    would. One pass, never zero.
  - sonnet plan: the default from the Loop — `/code-review` (high) on the
    full diff before PR.
  - opus plan: adversarial review, separate lenses (correctness, security,
    does-it-reproduce) as independent passes, not one combined read.
    Wrong-but-plausible is the failure mode that picked opus; one reviewer
    with one lens is how it survives.

  Depth is not the missing property, at any tier. Every review this repo
  recorded was written by the context that wrote the code, and PR54 shipped
  `cleanup`'s deletion bug through a 14-finding opus review at full depth —
  PR59, a session with no stake in it, found the same thing in one pass
  after the symptom recurred four times in one night. So each tier also
  spawns `.claude/agents/verifier.md` at its own tier: one reader that did
  not write the diff, findings tagged `(verifier)`.

  One reader, not three lenses. The labels correctness / security /
  does-it-reproduce already appear on findings written in-context (PR51 r12,
  r13; PR56 r4, r5), so lenses are not what was missing, and volume is no
  signal in either direction (`.agents/docs/feedback.md`, "Volume is not a
  score"). Three readers cost three times and buy nothing the numbers show
  absent. Independence is what the numbers show absent.

  Its output is not privileged. It read attacker-reachable text and it may
  be wrong; the session records, judges and fixes exactly as it would a
  self-finding.

  Findings land in the workstream file's `## Review` section, one line
  each, written BEFORE the fix and committed WITH it
  (`.agents/docs/handover/README.md`, Reviewing). Escalating tier mid-work
  escalates review depth with it; the reverse never happens — depth, like
  tier, never downgrades.

  Depth for this branch, printed rather than looked up:
  `./joharness.sh review`. It resolves the tier from the workstream file's
  `agent:` (else the claimed plan's, else sonnet), prints the matching
  recipe, and says whether the record exists — for every workstream file the
  branch carries, since each owes its own. Opt-in gate: `JOHARNESS_REVIEW=on`
  in `joharness.conf`. Off by default — silent, no check, `ci` output
  unchanged.

  Armed, it has two tiers, for the reason churn has two: `ci` runs all
  through the build, and a check that reds from the claim commit onward makes
  red the normal state of a working branch, which is how a gate stops being
  read. Below the edge it only says the record is still owed. At the edge —
  pull request open (`pr:` set), or the workstream's own `status:` review or
  done — an empty `## Review` fails `ci`, and so does one whose findings are
  all the branch's own: ONE must carry `(verifier)`, because step 5 spawns
  that reader at every depth. A FINDING, not a line — prose or a pasted red
  does not clear it. Only files the branch itself wrote; an inherited record
  is named, never redded. Edge is where the loop puts the review anyway
  (step 5, after the build), so the gate fires exactly when the rule already
  came due.

  It checks the RECORD, never the finding count, for the reason the churn
  rule gives below: finding counts are no signal in either direction. A gate
  on "N findings" buys invented findings. A clean pass records one line
  saying it was clean; an empty section is not a clean pass. What the gate
  cannot check, it says: a branch with no workstream file (copy, sync,
  plan-queue — the protocol forbids one there) prints that it checked
  nothing rather than passing quietly.
- Review churn = one round's fix breaks what earlier round's fix
  established. Means requirements conflict: no single rule in the code
  satisfies all of them at once. Not bad code — patching never converges,
  each round trades one requirement for another. Finding counts no
  signal, false both ways. Stop patching. Research step before next fix:
  list all requirements the code must satisfy, find the conflicting pair,
  resolve it — first try splitting the rule into one rule per case, so
  both requirements hold; a true either-or falls to the repo's stated
  correctness priority; none stated = product direction, ask human. Then
  fix once. Step runs at raised tier or effort — same lever as
  under-thinking. Session cannot switch own model: raise effort in place,
  or record wanted tier in workstream file and hand step to fresh session.
  Observed 2026-08-21, `chrsctl/redoct` verify matching rule: 5 review
  rounds of patching, findings per round 3, 5, 3, 5, 2 — oscillating, no
  floor; one conflict diagnosis (split into two per-case rules, both
  requirements kept) ended it.
  Measured, not just noticed: `joharness.sh ci` prints `== churn` — max
  commits touching one file since merge-base, protocol paths excluded,
  warning at `JOHARNESS_CHURN_THRESHOLD` (default 5; backtested over every
  merge on main: the twelve-round sync branch peaks at 13, all others <= 4).
  Two tiers, because the honest reading changes with the count. From the
  threshold up it is a warning and the lever is the session's to pull —
  whether the churn is real is its judgment call. From the ceiling up
  (`JOHARNESS_CHURN_LIMIT`, default 2x the threshold) it is not a call any
  more, so ci fails: no honest single edit rewrites one file that many times
  on one branch, and the session inside the churn is exactly the one that
  cannot see it — the one gate it cannot skip sees it instead. A genuine
  large rework lifts the gate with `JOHARNESS_CHURN_LIMIT=0`, a deliberate
  and visible act, not a silent skip. Session inside the churn sees it where
  ci already runs; the handover hook prints the warning line for other
  branches, so a resuming session inherits the signal too.
- Plan author assigns; implementing session may escalate tier or effort and
  record why in workstream file. Never downgrade to save cost — that
  decision is money, humans only (.agents/harness/AGENTS.md: stop and ask for
  money).
- Tier binds the builder. Session tier below the plan's `agent`: never
  implement — record wanted tier in the workstream file's `agent:`, push,
  hand off; hook prints that tier, so the next session starts on the right
  model. Session cannot switch its own model mid-run. Effort below the
  plan's `effort`: raise in place — effort is per-request, tier is not.
  Unenforced on purpose, decided 2026-08-27: a session cannot read its own
  tier reliably, so a gate would guess — and a gate that guesses at the
  answer is one sessions learn to route around (`finish` refuses to guess
  at "done" for the same reason). Hook printing the wanted tier at session
  start is the mechanism; the rule is what the reader obeys.

## Behavior findings (default worker, Sonnet 5)

Measured findings from Anthropic migration notes, each with harness
consequence:

1. **Literal instruction following.** Does not generalize instruction from
   one item to another; does not infer unstated requests. Strongest at low
   and medium effort. Consequence: plans state scope AND out-of-scope
   explicitly. Implicit "obviously also do X" never happens.
2. **Strict effort adherence.** At low effort scopes work to exactly what
   asked; risk of under-thinking on complex tasks. Fix = raise effort, not
   prompt around it.
3. **More agentic than predecessors.** Reaches for tools, runs
   self-verification loops unprompted. Consequence: verify commands with
   expected output in every plan get run, not skipped.
4. **Good progress updates by default.** Forced "summarize every N steps"
   scaffolding hurts more than helps. Harness has none; keep it that way.
5. **Conservative-reporting instructions lower recall.** In review-style
   tasks, "only report if certain" makes the model drop real findings.
   Consequence: review plans say report everything, filter later.

Findings also explain harness fit: caveman imperatives suit literal reader;
prohibitions-with-reasons = exactly what literal model follows best;
hook-injected state beats instruction to go look.

## Counting sessions that can read the count

`./joharness.sh scorecard` counts per-branch process facts. The sessions it
counts read this repo's rules, so they can read what is counted and optimise
for it. That is not a hypothetical: it is the defining condition here, and it
is why the command REPORTS and never gates.

**The mechanism is Goodhart's Law, and the attribution matters.** The sentence
everyone quotes — "when a measure becomes a target, it ceases to be a good
measure" — is Strathern's (1997, citing Hoskin), not Goodhart's. Goodhart's
1975 original is "Any observed statistical regularity will tend to collapse
once pressure is placed upon it for control purposes". Use the short form as
*commonly stated as*, never as his words. The academic anchor for the failure
under partial observability is Robert Austin, *Measuring and Managing
Performance in Organizations*; industry writing frames gaming as a design
failure rather than a discipline failure, which is a reasonable stance and NOT
a literature consensus — do not cite it as one.

**What DORA supports, and what it does not.** It supports metrics being team-
and system-level and not tied to individual performance review, and dora.dev
warns against isolating teams with specific metrics because that "can lead to
friction and finger-pointing". It does NOT say "individual metrics create
competition while team metrics create collaboration" — that sentence traces to
no DORA, Google Cloud or *Accelerate* source and was removed from this repo's
reasoning when a verification pass failed it.

So: report first. A number nobody is graded on is not yet a target, and
reporting is what keeps the counts honest long enough to backtest them. That
is the same bar `churn` cleared before it earned a ceiling, and the reason
`scorecard` has not earned one.

Both gaps the research named are now closed in `scorecard` itself, and how
they were closed is the part worth keeping:

- **A count wants a counterweight.** "Review findings recorded" alone rewards
  recording noise, so it prints paired with how many of those findings are
  UNMARKED — no fix, no decision, no reason. That is the cheapest kind to
  write, so noise lands there and the pair shows a shape the total hides.
  Marking everything to flatten it is a second act, and a visible one. The
  pairing prints even at zero: a parenthetical that appears only when
  something is wrong is one readers learn to skip.
- **Counts now carry a retirement condition.** Retire one when it stops being
  able to surprise anyone — once every branch scores the same it is a ritual,
  and reading it costs more than skipping it. Long-lived counts collect gaming
  strategies, so removal is maintenance rather than loss; history keeps what
  it measured. `scorecard` states this beside its own counts rather than in a
  field, because the judgment is prose and a field would invite a gate.

Both remedies are industry practice rather than sourced study, and both survive
the verification pass because neither rests on the DORA sentence that failed.

What did NOT change: `scorecard` still reports and never gates. Pairing exists
to survive pressure, not to create it — a gate here would manufacture the
target the pairing is built to withstand.

One method note, because it is the reason the attributions above are hedged so
precisely: of the claims in the research behind this section, the one its author
flagged as needing a check is exactly the one that failed. Flagging it was
right. Publishing it unflagged would not have been.

## Writing plans for agents

Rules in `.agents/docs/plans/README.md`. Core: an agent executes what the plan
says, precisely, and nothing else. Ambiguity does not get resolved in your
favor — it gets executed literally or asked back to human. Every plan pays
once at write time so sessions never pay at run time.
