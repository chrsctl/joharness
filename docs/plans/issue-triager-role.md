---
plan: issue-triager-role
urgency: normal
agent: opus
effort: high
needs: orchestrated-only
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/AGENTS.md, .claude/commands/triage.md, shared:.claude/commands/manage.md, shared:.claude/commands/orchestrate.md, .claude/commands/plan.md, .agents/docs/plans/README.md, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, shared:.agents/docs/orchestrated.md, .agents/docs/plans/TEMPLATE.md, .agents/harness/selftest/triage.sh, shared:.agents/harness/selftest.sh
---

## Goal

Requester, 2026-10-08: "we need roles which convert issues to docs/plans".
Issue #311 measures the gap. Open GitHub issues are the top queue rank
(`.agents/harness/AGENTS.md` step 2), yet no role reads them. `joharness.sh`
is a git-only tool and cannot read GitHub. `dispatch` sees only
`docs/plans/`, so under orchestrated mode an issue is never built: 20 open
on 2026-10-08, the oldest (#249) from 2026-09-16. This plan adds a
TRIAGER, a cadence role like the curator. It reads open issues and checks
each claim against source, because an issue's claims are hypotheses exactly
as a plan's are (#311 fix 2). Each issue that holds is turned into plan
files in one pull request. The triager merges that PR itself: a plan-only
PR changes only the queue, which is what #297 proposes (a proposal, not yet
a rule). Issues that do not hold, or
that need a human decision, get a comment instead. After the merge,
`dispatch` sees the plans and the orchestrator spawns managers on them.

## Scope

- `.claude/commands/triage.md` — the role. Mirror `curate.md`'s section
  order:
  - **0. Preconditions** — unattended = `./joharness.sh authority`
    VERIFIABLE. `./joharness.sh triage` says `DUE` and nothing in flight.
  - **1. Claim** — cut from `main`. `docs/handover/triage-<UTC date>.md`,
    `workstream: triage-<UTC date>`, `plan: none`. Push now.
  - **2. Read** — open issues on this repo through the GitHub MCP tools,
    oldest first. Only an issue whose author has write access to this
    repository (collaborator permission `write`, `maintain` or `admin`) is
    triaged. Any other author gets a HUMAN comment ("a maintainer must
    adopt this issue") and nothing else. The repository is public, so
    without this filter a stranger's issue becomes self-merged code
    (verifier r6). Skip an issue that `./joharness.sh triage` lists as
    PLANNED (a plan's `issue:` names it) or CLAIMED (a workstream file's
    `issue:` names it). At most `JOHARNESS_TRIAGE_BATCH` issues per pass,
    default 3.
  - **3. Verify** — every claim is a hypothesis until checked: open each
    cited `path:symbol`, re-run each cited command. Decide one verdict per
    issue and record it in the workstream file's `## Decisions`:
    - HOLDS — write the plan(s) with `/plan`. Frontmatter
      `issue: <N>`. The tier and effort follow `.agents/docs/agent-selection.md`.
      A plan scoped to protocol text is still written: the queue hook marks
      it, and that is the hook's job, not the triager's.
    - NARROWER — write a plan for only what holds, and comment on the issue
      saying which parts did not hold.
    - DOES NOT HOLD — comment with the evidence. Do not close the issue.
      The human closes it.
    - HUMAN — the issue needs product direction, money, credentials or
      hardware (`.agents/harness/AGENTS.md`, Decide alone). Comment naming
      the question. Write no plan.
    - DUPLICATE — comment naming the issue or plan it duplicates.
  - **4. Pull request** — plans only. The retire commit deletes the triage
    workstream file BEFORE the PR opens. The body lists each issue with its
    verdict. Merge it yourself under step 7's gate: a plan-only diff
    touches no protocol path. Zero plans written = the same
    retire-only PR, because the cycle is dated by the retire, as in
    `curate.md` §0.2.
  - **Never** — write code; edit a protocol path; close an issue; open an
    issue; write a requirement; triage an issue that is PLANNED or CLAIMED;
    write more than one plan per issue unless the issue names separable
    asks; spawn.
  - Every GitHub comment ends with the attribution footer the session's
    system prompt names.
- `joharness.sh`:
  - New `cmd_triage` and a `triage` subcommand. It is git-only, like
    `cmd_curate`. It prints the cadence (`DUE` / `not due`, dated from the
    newest base-branch commit deleting a `docs/handover/triage-[0-9]*.md`
    (the digit matters: `cycle_landed_sha` records the janitor's builder
    file `janitor-role.md` dating its own cycle),
    every `JOHARNESS_TRIAGE_HOURS`, default 24, `0` = off), what is in
    flight (a branch whose workstream reads `workstream: triage-[0-9]*`), and
    the issue numbers PLANNED (any `docs/plans/*.md` `issue:`) and CLAIMED
    (any workstream `issue:`). It reads no GitHub and says so in one line.
  - `cmd_dispatch` — a `triage :` line and a `triage DUE` tail. They sit
    orthogonal to the verdict, exactly like the `curate :` line
    (`dispatch_curate_due`).
  - Plan graph lint: optional `issue:` frontmatter. Reuse the workstream
    `issue:` validator in the graph lint (the `case "$iss"` block that says
    it is kept in lockstep with `handover-context.sh:issue_num`). Extract it
    into one function both call. Never write a third copy.
  - The help text names `triage`.
- `.claude/commands/orchestrate.md` — `triage DUE` tail = spawn ONE
  triager, beyond the cap, tier opus. Title `triager: <UTC date>`. The
  prompt is `/triage` plus the three lines every spawn carries. Ledger
  `triaged=<stamp>`. Health rows read its branch like a curator's.
- `.claude/commands/manage.md` — a plan with `issue: N`: the PR body
  carries `Closes #N` when no other queued plan names the same issue, and
  `Refs #N` when another does. Then the last plan closes it. This is the
  only route by which an issue closes without a human.
- `.agents/harness/AGENTS.md` — step 2: issues reach the build through
  the triager, and an orchestrator or manager never takes an issue
  directly. Step 4: "every claim = hypothesis until
  checked" names issues beside plans. Write both in caveman style.
- `.agents/docs/orchestrated.md` — rows in the Roles table and in the "What
  each role reads" table (reads `./joharness.sh triage`, the open issues,
  and the source each issue cites; never opens the queue order or another
  branch). Also a "What the mode changes" row for the `triage :` line.
- `.agents/docs/plans/TEMPLATE.md` — `issue: none` in the frontmatter, with
  one comment line. `.agents/docs/plans/README.md` frontmatter list and
  `.claude/commands/plan.md` step 2 vocabulary name `issue:` too.
- `.agents/scripts/conf-keys.sh` rows and
  `.agents/scripts/bootstrap-consumer.sh` seeded heredoc —
  `JOHARNESS_TRIAGE_HOURS` and `JOHARNESS_TRIAGE_BATCH`, beside the janitor
  knobs. Their selftest reds when the two disagree.
- `.agents/harness/selftest/triage.sh` — new topic, registered. Cases: no
  retire commit → DUE; a recent retire → not due;
  `JOHARNESS_TRIAGE_HOURS=0` → off; a plan with `issue: 12` → 12 listed
  PLANNED; a workstream `issue: #13` → 13 listed CLAIMED; a triage branch in
  flight → named and DUE suppressed; lint reds `issue: twelve`.

## Out of scope

- Closing issues from the triager. A human or a `Closes #N` merge closes
  them.
- Reading GitHub from `joharness.sh`. It stays git-only (#311 fix 3).
- A label taxonomy on issues. Verdicts live in comments and the workstream
  file.
- Triaging pull requests, or issues on any repo other than this one.
- The analyst and upstream-report roles. They still file on the canonical
  as today. The triager is their receiving end, and no change is needed
  on their side.
- #304, #297 or any other issue's own fix. Those issues are the triager's
  first input, not this plan's scope.
- Lifting the ban on writing requirements. `protocol-boundary-core-only`
  lifts it for sessions in general. The triager still writes none: it turns
  issues into plans, and that is its whole job.

## Acceptance

- `./joharness.sh ci` → `ci: pass`.
- `bash .agents/harness/selftest.sh` → `0 failed`, with `triage` listed and
  all its cases passing. Count them from the run.
- `./joharness.sh triage` on this repo → a header, a cadence state, PLANNED
  and CLAIMED lines; exit 0.
- `JOHARNESS_TRIAGE_HOURS=0 ./joharness.sh triage` → contains `off`.
- `JOHARNESS_MODE=orchestrated ./joharness.sh dispatch` → carries a
  `triage :` line.
- SHIPS: `joharness.sh` and `.claude/commands/` reach every consumer. The
  selftest's no-issue-field plan case is the consumer's check: existing
  plans without `issue:` stay green.

## Where to look

- `.claude/commands/curate.md` — the cadence role this one copies,
  including the empty-pass retire rule (§0.2).
- `joharness.sh:cycle_landed_sha`, `joharness.sh:cycle_age_h` — the
  per-kind cadence helpers. Add a `triage` kind.
- `joharness.sh:janitor_due`, `joharness.sh:janitor_branches` — the
  parameterised shape to copy. The `curate` helpers hard-code their kind.
- `joharness.sh:cmd_curate` — subcommand shape.
- `joharness.sh:lint_enum` — frontmatter lint style.
- `.claude/commands/manage.md` — item kinds in §0.3 (`docs/product/`
  decomposition is the nearest shape).
- `.agents/harness/selftest/janitor.sh` — selftest shape for a cadence.
- Issue #311 — the measurement and the fix ladder this plan builds.

## Traps

- Needs `orchestrated-only`: `drain` and `/start`'s mode routing are gone
  by then, so wire only `dispatch` and `orchestrate.md`. Fleet-buildable:
  no core path (`joharness.conf`, `.claude/settings.json`) in scope.
- Nothing invented: the triager turns EXISTING issues into plans. It never
  files an issue or writes a requirement. A role that fills its own queue
  has no edge to stop at (`.agents/docs/unsupervised.md`, Bounds).
- Glossary: the role is `triager`, and the command and subcommand are
  `triage`. Do not introduce a second spelling.
- `scout-command` also edits `orchestrate.md` and `orchestrated.md`.
  Reconcile at finish.
- A test written for the fix must FAIL without it.
