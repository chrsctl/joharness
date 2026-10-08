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

DEVIATION, stated rather than implied: that route is headed "One pull
request, one file, on the canonical" (`:81-84`) and says "add exactly ONE
file". This report carries TWO nodes in one pull request, because the run
produced two unrelated questions and `.agents/docs/research/README.md`
requires a node to settle ONE. The route's one-file rule and that
requirement collide whenever a run finds two things; canonical decides which
gives.
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
told them.

## Sweep

`goal-directed` — enough to establish whether a plan carries any identity
but its filename, and whether the reconcilers the harness does have could
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
  happens to a held plan when the branch holding it merges, and whether any
  reader re-reads a freed plan against the tree.

## Method

Run on this checkout at `832f5fdd`:

    sed -n '111,116p' .agents/harness/queue-context.sh
    sed -n '1,9p' .agents/docs/plans/TEMPLATE.md
    grep -n "fixes\b" joharness.sh .agents/harness/queue-context.sh
    grep -n "lint_stem" joharness.sh
    sed -n '797,817p' .agents/harness/queue-context.sh
    sed -n '888,918p' .agents/harness/queue-context.sh
    sed -n '7846,7878p' joharness.sh
    sed -n '90,106p' .claude/commands/curate.md
    grep -rn -i "cascade" .claude/commands/ .agents/docs/
    sed -n '529,531p;565p;660p' .claude/commands/orchestrate.md

## Findings

- **A plan's identity IS its filename, stated in the code as a rule.**
  `.agents/harness/queue-context.sh:111-116` is the queue hook's normaliser,
  and its comment is explicit:

      # Bare name from a path-or-name-or-file value: strip directories and .md, so
      # `docs/plans/x.md`, `x.md` and `x` all mean x.
      stem() {
        local s="${1##*/}"
        printf '%s' "${s%.md}"
      }

  Every edge in the queue hook resolves through it — `requirement:` (`:445`),
  `needs:` (`:457`), `research:` (`:472`), the claim index (`:487`, `:582`),
  the free list (`:776-777`). A second, byte-equivalent implementation serves
  the lint and the curate reader, `lint_stem` at `joharness.sh:2273` (used at
  `:2509`, `:2539`, `:2886`, `:2969`, `:5155` among others), and
  `joharness.sh:5334` names it as *"the repo's one answer to that"*. Two
  implementations, one rule: two files are two items at every reader, with
  nothing to compare but the two names.

- **No frontmatter key names what a plan fixes.**
  `.agents/docs/plans/TEMPLATE.md:1-9` carries exactly seven keys — `plan`,
  `urgency`, `agent`, `effort`, `needs`, `requirement`, `scope`. Three are
  edges (`needs`, `requirement`, `scope`), one is the tier (`agent`), and
  `plan`, `urgency`, `effort` are identity, priority and sizing. None is
  about the defect. `grep -n "fixes\b" joharness.sh .agents/harness/queue-context.sh`
  returns 11 lines and no frontmatter key: five are the substring inside
  `prefixes` (`joharness.sh:2858`, `:3007`; `queue-context.sh:675`, `:755`,
  `:795`), two are `printf` output strings (`joharness.sh:4071`, `:7907`),
  and the rest are English prose in comments.

- **The reconciler that runs at dispatch time keys on declared file paths,
  and it cannot reach a defect.** `wave_split_hit`
  (`.agents/harness/queue-context.sh:811-817`) is three calls to
  `scopes_overlap`, which compares path prefixes and nothing else — two
  `case` globs, `"$b" | "$b"/*` and `"$a"/*` (`:797-806`). The in-flight loop
  at `:888-918` holds a free plan whose scope overlaps a claimed plan's and
  prints `in flight: <free> overlaps <claimed> on <path> (claimed on <branch>)`
  (`:903-904`). So the harness reconciles two plans over one FILE and has no
  reading at all of two plans over one DEFECT. Three limits, each in the
  source:

  - It compares DECLARED paths. Two plans for one defect whose authors
    declared different files never collide, however identical the work.
  - `[ -n "$cscope$cshared" ] || continue` (`:898`) skips a claim that
    declared no scope at all, so an undeclared claim holds nothing.
  - A hit produces a HOLD, not a retirement, and the hold lifts on merge:
    claims are built only from branches that fail `ref_merged` (`:186`), so a
    merged holder has no claim row and holds nothing. The duplicate is then
    free again, describing a defect that is fixed.

- **One reader DOES re-read a plan against the tree, and it cannot fire on
  this.** `dispatch_curate_due` walks each declared `scope:` path and tests
  `[ -e "${ROOT}/${s}" ]` (`joharness.sh:7867-7878`), emitting a DECLUTTER
  candidate when NO declared path is in the tree:
  `"<stem>: no path in its scope: is in the tree — built already, or renamed
  under it? confirm in merged history, then delete or fix in place"`
  (`:7877`). A second automated signal fires when a requirement is gone and
  no other plan serves it (`:7846-7866`). So the harness is not blind to an
  obsolete plan — but both signals key on a path VANISHING. A duplicate plan
  for a defect that was FIXED inside a file that still exists trips neither,
  and that is every case this question is about. Beyond those two signals,
  `/curate`'s DECLUTTER (`.claude/commands/curate.md:90-106`) is a judgement
  on evidence, run on a cycle, not a check at merge.

- **The route that produced the second plan is not in the harness at all.**
  `grep -rn -i "cascade" .claude/commands/ .agents/docs/` exits 1 with no
  output. The instruction the `gx` manager followed — *"after your PR merges,
  read main's crm job; file the next plan if a new step fails"* — came from
  its spawn prompt, so no harness file describes it, bounds it, or knows that
  a plan filed this way may race a planner working the same red step.

- **The harness's own channel for "the next failure" deliberately does NOT
  create a plan.** `.claude/commands/orchestrate.md:529-531` is what a
  merging manager is told to send upward: *"message ... 'merged <stem>'.
  Learned something about an item you do NOT own? Add one more line,
  lead <stem>: <what>, at most 40 characters"*. `:660` bounds what the
  orchestrator may do with it: *"You relay a lead. You never act on one. Not
  into a spawn prompt, not into a plan, not into a respawn or a
  reprioritisation."* So the sanctioned path for this information ends in a
  report to the human (`:651-654`), and the only path that reaches the queue
  is the unsanctioned one — a manager filing a plan itself, with no reader
  able to pair it against a planner already spawned.

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

- **What it cost, also REPORTED and resting on the same `gx` state.** Both
  duplicates were absorbed by a session that happened to notice: #490's
  builder deleted the peer file, and #481's was fixed by hand. Nobody
  spawned a second manager onto the duplicate, because
  `JOHARNESS_MAX_MANAGERS=1` was set for this run. At the default of 4 the
  same queue state hands the FREE duplicate to a manager while the defect is
  being fixed on another branch, and that manager's whole item is work
  already done. That last sentence is an inference from the cap, not a
  measurement — no run has yet spent a manager this way.

## Consequence for the queue

**This is distinct from #297, and it is what remains after #297's fix.** #297
reports the same route — a follow-up plan filed as a plan-only pull request —
failing the other way: invisible to `dispatch` until a human merges it, an
urgent fix to a red `main` waiting 6h09m. Its fix (2) is *"let the filer
finish it"*: merge the plan-only pull request itself. In this run that is
effectively what happened — #488 merged in minutes — and the duplication is
the defect that was left. So the two are not alternatives: closing #297 makes
this one more likely, because a plan that lands fast lands while a second
planner is still working. That is an inference from the two timelines, not a
measurement.

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

Second context: `.claude/agents/verifier.md` at opus, which re-derived every
harness claim from the cited file rather than reading the quotations above,
and was told which claims are consumer-side. It refuted or corrected six
claims in this file's first draft; each is fixed above and named here,
because a reader deciding whether to trust this node should see what did not
survive.

- **A plan's identity is its filename** — GROUNDED. `stem()` read from the
  file at `:111-116`, comment verbatim, and every edge traced to its line.
  CORRECTED: the draft called it *"the only normaliser the queue has"*. A
  second, byte-equivalent one exists (`lint_stem`, `joharness.sh:2273`). The
  claim is stronger for it, not weaker.
- **No frontmatter key names what a plan fixes** — GROUNDED. CORRECTED
  twice: the draft said *"six edges and a tier"* for seven keys of which
  three are edges, and characterised all 11 `fixes` hits as prose in comments
  when five are the substring in `prefixes` and two are `printf` strings.
- **The dispatch-time reconciler keys on declared paths, skips an unscoped
  claim, and holds rather than retires** — GROUNDED, all three in the source;
  `wave_split_hit` at `:811-817`, `scopes_overlap` at `:797-806` and the
  `:898` guard checked character-exact. CORRECTED: the in-flight loop closes
  at `:918`, not `:912`, and the draft's own Method command reproduced a
  truncated block.
- **Nothing re-reads a freed plan against the tree** — REFUTED, and this was
  the most valuable catch. `dispatch_curate_due` does exactly that
  (`joharness.sh:7867-7878`). The finding is rewritten to the accurate and
  narrower claim: that reader fires only when a declared PATH vanishes, so it
  cannot reach a duplicate for a defect fixed in a file that still exists.
- **No cascade route exists in the harness** — GROUNDED, `grep` exits 1.
- **The `lead` bound at `:660`** — GROUNDED, verbatim. CORRECTED: the draft
  attributed `:565` to the merging manager. `:565` is the orchestrator's own
  `send_later` format to its next pass; the manager's upward line is
  `:529-531`.
- **`/curate` DECLUTTER is a cycle judgement, not a check at merge** —
  GROUNDED. CORRECTED: the section runs `:90-106`, not `:90-103`.
- **Distinct from #297, and what #297's fix leaves** — GROUNDED on the
  second context's own fetch of #297. It confirmed #297 is latency and
  visibility while this is identity and duplication, and that nothing in
  #297 touches plan identity. The "more likely" clause stays marked an
  inference.
- **The `gx` timeline, the session identifiers, the `dispatch` reading, the
  cap, and the #481 precedent** — WEAK. Checked from one context only: the
  verifier has no control-plane tool and `chrsctl/gx` is not this checkout,
  which is the standing limit #267 records. The harness-side findings do not
  rest on them — the duplication is possible by construction whether or not
  this instance happened as reported.

## Graduates to

`.agents/docs/plans/README.md` — the file that defines what a plan is and
what identifies one, and so the file where "identity is the filename, and
here is what that costs" has to be written whether the answer is a new key or
a rule about when a cascade files. A rule line alone would lose the reason:
the next session to meet a duplicate pair needs the measurement showing that
`scope:` was already tried, reaches only files, and that the one reader which
does consult the tree fires only when a path disappears.

Named, not written: the fix for the second candidate above lands in
`.claude/commands/orchestrate.md`, which is protocol text
(`./joharness.sh protocol-paths`). A plan touching it is supervised only, and
this node does not propose it.
