---
research: plan-identity-is-its-filename
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/plans/README.md
---

<!--
A report from a consumer (`chrsctl/gx`), filed by the route
`.claude/commands/upstream-report.md` names. Canonical decides. The
consumer-side measurements could not be re-taken here, because they are
about an orchestrated fleet running the harness against real work; they are
marked REPORTED below and every harness claim beside them was measured on
this checkout.
-->

## Question

Does the harness identify a plan by anything but its filename, so that two
plan files describing one defect can be distinguished from two plan files
describing two?

## Echo

A plan's name is its path stem, and the queue counts files. What I am asking
is whether anything downstream of that — the queue hook, `dispatch`, the
wave partition — ever asks what a plan is ABOUT, or whether every reader
takes two filenames as two units of work by construction. If identity is the
filename and nothing else, then one defect written down twice is two free
items, and the harness cannot be the thing that notices, because it has
nothing to compare.

Not asking whether the duplication in `chrsctl/gx` was somebody's mistake.
Two sessions each filed a correct plan for a defect each had independently
read off the same red CI step. The question is what the harness could have
told them, and the answer looks like nothing.

## Sweep

`goal-directed` — enough to establish whether a plan carries any identity
but its filename, and whether the one reconciler the harness does have could
reach this case. Not a survey of the wave partition, and not a proposal for
how the queue should key plans.

## What would settle it

- **A key other than the stem.** If any reader compares plans on something a
  second file could match — a declared defect, a failing criterion, a CI step
  — the answer is yes and this closes. Found in the plan frontmatter and in
  the readers that schedule, or it does not exist.
- **Whether `scope:` already covers it.** The harness does reconcile two
  plans over one FILE. If a declared-scope overlap would have held one of the
  two in `gx`, the gap is a declaration the sessions did not write and not a
  missing mechanism — a different, cheaper answer. Settled by reading what
  `wave_split_hit` compares and what it does on a hit.
- **Whether a hold is a reconciliation.** Even on a hit, the question is
  whether the duplicate is retired or merely delayed. Settled by reading what
  happens to a held plan when the branch holding it merges.

## Method

Run on this checkout at `832f5fdd`:

    sed -n '112,116p' .agents/harness/queue-context.sh
    sed -n '1,8p' .agents/docs/plans/TEMPLATE.md
    grep -n "fixes\b" joharness.sh .agents/harness/queue-context.sh
    sed -n '797,817p' .agents/harness/queue-context.sh
    sed -n '888,912p' .agents/harness/queue-context.sh
    grep -rn -i "cascade" .claude/commands/ .agents/docs/
    grep -n "lead" .claude/commands/orchestrate.md

## Findings

- **A plan's identity IS its filename, stated in the code as a rule.**
  `.agents/harness/queue-context.sh:111-116` defines the only normaliser the
  queue has, and its comment is explicit:

      # Bare name from a path-or-name-or-file value: strip directories and .md, so
      # `docs/plans/x.md`, `x.md` and `x` all mean x.
      stem() {
        local s="${1##*/}"
        printf '%s' "${s%.md}"
      }

  Every edge in the graph resolves through it — `needs:`, `requirement:`,
  `research:`, the claim index, the free list. Two files are two items at
  every reader, with nothing to compare but the two names.

- **No frontmatter key names what a plan fixes.** `.agents/docs/plans/TEMPLATE.md`
  carries `plan`, `urgency`, `agent`, `effort`, `needs`, `requirement`,
  `scope` — six edges and a tier, none of them about the defect.
  `grep -n "fixes\b" joharness.sh .agents/harness/queue-context.sh` returns no
  frontmatter key (eleven hits, all of them English prose in comments).

- **The one reconciler the harness has keys on declared file paths, and it
  cannot reach a defect.** `wave_split_hit`
  (`.agents/harness/queue-context.sh:811-817`) is three calls to
  `scopes_overlap`, which compares path prefixes and nothing else
  (`:797-806`). The in-flight loop at `:888-912` holds a free plan whose
  scope overlaps a claimed plan's and prints
  `in flight: <free> overlaps <claimed> on <path> (claimed on <branch>)`.
  So the harness reconciles two plans over one FILE and has no reading at
  all of two plans over one DEFECT. Three limits, each in the source:

  - It compares DECLARED paths. Two plans for one defect whose authors
    declared different files never collide, however identical the work.
  - `[ -n "$cscope$cshared" ] || continue` (`:898`) skips a claim that
    declared no scope at all, so an undeclared claim holds nothing.
  - A hit produces a HOLD, not a retirement. When the holder merges, the
    hold lifts and the duplicate is free again — now describing a defect
    that is fixed. Nothing in the harness re-reads a freed plan against the
    tree, and `/curate`'s DECLUTTER (`.claude/commands/curate.md:90-103`) is
    the only route that retires an obsolete plan: a cycle role, on evidence,
    not a check at merge.

- **The route that produced the second plan is not in the harness at all.**
  `grep -rn -i "cascade" .claude/commands/ .agents/docs/` returns nothing.
  The instruction the `gx` manager followed — *"after your PR merges, read
  main's crm job; file the next plan if a new step fails"* — came from its
  spawn prompt, so no harness file describes it, bounds it, or knows that a
  plan filed this way may race a planner working the same red step.

- **The harness's own channel for "the next failure" deliberately does NOT
  create a plan, which is why nothing reconciled these two.**
  `.claude/commands/orchestrate.md:565` defines the one line a merging
  manager may send upward, `lead <stem>: <40 chars>`, and `:660` bounds what
  the orchestrator may do with it: *"You relay a lead. You never act on one.
  Not into a spawn prompt, not into a plan, not into a respawn or a
  reprioritisation."* So the sanctioned path for this information ends in a
  report to the human, and the only path that reaches the queue is the
  unsanctioned one — a manager filing a plan itself, with no reader able to
  pair it against a planner already spawned.

- **REPORTED from `chrsctl/gx`, orchestrated run of 2026-10-08, not
  re-measured here.** Two plan files for one defect — CRM1799's drift guard
  splitting on `const KIND_WORD` after PR #486 moved it:

  | | plan file | session | pull request | merged |
  | --- | --- | --- | --- | --- |
  | cascade manager | `docs/plans/crm-notifications-kind-word-literal-check.md` | `session_01Rcr8viiFAsDtu9GA2QfGhc` | #488, plan only | 03:56Z |
  | planner + builder | `docs/plans/crm-c2-acceptance-after-localization.md` | `session_01EPCMdSUshmLbb2kWjq9nGj` | #490, plan + fix | 04:32Z |

  The cascade manager was told *"after your PR merges, read main's crm job;
  file the next plan if a new step fails"*. The orchestrator, reading the
  same red CI step, had already spawned the planner and builder.
  `./joharness.sh dispatch` listed the first as a FREE wave-1 item while the
  second was being built. Nothing in the harness would have reconciled them;
  the builder happened to delete the duplicate in #490. Earlier in the same
  run, a `mappingproxy` duplicate was reconciled by hand in `gx` PR #481 —
  so this is the second instance, and the first cost a human the reconcile.

- **What it cost, and why the cost is small this time and not in general.**
  Both duplicates were absorbed by a session that happened to notice:
  #490's builder deleted the peer file, and #481's was fixed by hand. Nobody
  spawned a second manager onto the duplicate, because
  `JOHARNESS_MAX_MANAGERS=1` was set for this run. At the default of 4 the
  same queue state hands the FREE duplicate to a manager while the defect is
  being fixed on another branch, and that manager's whole item is work
  already done.

## Consequence for the queue

**This is distinct from #297, and it is what remains after #297's fix.** #297
reports the same route — a follow-up plan filed as a plan-only pull request —
failing the other way: invisible to `dispatch` until a human merges it, an
urgent fix to a red `main` waiting 6h09m. Its fix (2) is *"let the filer
finish it"*: merge the plan-only pull request itself. In this run that is
effectively what happened — #488 merged in minutes — and the duplication is
the defect that was left. So the two issues are not alternatives: closing
#297 makes this one more likely, because a plan that lands fast lands while a
second planner is still working.

Which harness file changes depends on the answer, and both candidates are
outside this node:

- **A plan identity that is not the filename.** A frontmatter key naming
  what the plan fixes — a failing acceptance criterion, a CI step — which the
  queue hook dedupes on, the way it already partitions on `scope:`. This is
  the larger answer and it owes a question the measurement above does not
  settle: whether two sessions reading one red step would write the same
  value for it. If they would not, the key buys nothing.
- **A rule that a cascade's next plan is filed BEFORE its fix merges**, so
  `dispatch` carries a row for it before any second planner is spawned. This
  needs no new key and no new lint, and it has a prerequisite the harness
  does not meet: there is no cascade route in the harness to put the rule in.
  Writing one is where it would land, and `.claude/commands/orchestrate.md`'s
  `lead` bound (`:660`) is the rule it has to be reconciled with — a lead is
  relayed and never acted on, by measurement recorded there.

No plan should be written from this node that adds a dedupe to `dispatch`
alone. `dispatch` reads `main`; both plans were on `main` only after both
were written, and the second was already built by then. The reconciliation
has to happen where the second planner is SPAWNED, which is the
orchestrator's pass, or not at all.

## Verification

**Pass IN FLIGHT at this commit.** The verdicts below are the reporting
session's own reading and are not yet a second context's. The next commit on
this branch carries the pass's result and corrects any verdict it refutes.

Second context: `.claude/agents/verifier.md` at opus, which re-derived every
harness claim from the source rather than reading the quotations above, and
was told which claims are consumer-side and unverifiable here.

- **A plan's identity is its filename** — GROUNDED. `stem()` read from the
  file, and the readers that resolve edges through it traced.
- **No frontmatter key names what a plan fixes** — GROUNDED. Template key
  list enumerated; the `fixes` grep hits are prose.
- **The one reconciler keys on declared paths, skips an unscoped claim, and
  holds rather than retires** — GROUNDED, all three in the source.
- **No cascade route exists in the harness** — GROUNDED, and the `lead`
  bound that replaces it was read in place.
- **This is distinct from #297 and is what #297's fix leaves** — GROUNDED on
  the reading of #297; the claim that closing #297 makes this MORE likely is
  an inference from the two timelines, marked as such above and not measured.
- **The `gx` timeline, the session identifiers, the `dispatch` reading and
  the #481 precedent** — UNVERIFIABLE HERE, and reported as such. Canonical
  has no consumers and the verifier cannot read a control plane (#267). The
  harness-side claims above do not rest on them: the duplication is possible
  by construction whether or not this instance happened as reported.

## Graduates to

`.agents/docs/plans/README.md` — the file that defines what a plan is and
what identifies one, and so the file where "identity is the filename, and
here is what that costs" has to be written whether the answer is a new key or
a rule about when a cascade files. A rule line alone would lose the reason:
the next session to meet a duplicate pair needs the measurement showing that
`scope:` was already tried and reaches only files.

Named, not written: the fix for the second candidate above lands in
`.claude/commands/orchestrate.md`, which is protocol text
(`./joharness.sh protocol-paths`). A plan touching it is supervised only, and
this node does not propose it.
