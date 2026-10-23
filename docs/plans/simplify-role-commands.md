---
plan: simplify-role-commands
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .agents/harness/AGENTS.md, .claude/commands/manage.md, .claude/commands/clerk.md, .claude/commands/scout.md, .claude/commands/conduct.md, .claude/commands/curate.md, .claude/commands/upstream-report.md, .claude/commands/plan.md, .agents/docs/manage-reference.md
---

## Goal

The user asked to simplify the protocol. The non-orchestrator role files
repeat the Loop step 7 merge gate, the block and `human-review` rules,
"holds no slot" and the comment-counting rules. They also carry history
the Status quo rule bans and one dead section reference. Give each rule
one home and delete the copies, without changing behaviour.

## Scope

- `.agents/harness/AGENTS.md` (always loaded, so each line costs most here):
  - Step 7 exemption: name clerk and conduct beside copy and sync tasks as
    work with no workstream file, matching their role files.
  - Leave the routing line and the step 7 gate as they are. The full
    routing table lives in start.md (plan simplify-orchestrator-commands).
- `.claude/commands/manage.md`, `clerk.md`, `conduct.md`, `curate.md`:
  - Replace each restated merge gate with "Loop step 7". curate.md's
    "`./joharness.sh ci` green" gate contradicts step 7 and goes.
  - Cut "holds no slot / beyond `JOHARNESS_MAX_MANAGERS`" to one clause.
- `.claude/commands/clerk.md`:
  - Delete the "known limits" design argument.
  - Stays the single home of THE SCOUT GATE and comment counting.
- `.claude/commands/scout.md`:
  - Replace its comment-counting copies with pointers to clerk.md.
  - Delete "(a written number, #461)".
  - Renumber the sections, which skip §1.
- `.claude/commands/conduct.md`:
  - Delete the issue #251 skeptics story, the "settled elsewhere" list of
    withdrawn designs, and the "why you exist" paragraph.
- `.claude/commands/upstream-report.md`:
  - Replace §1–2 (which restate `.agents/docs/feedback.md` §1–2) with a
    pointer.
  - Delete the "three reasons" and "usually weeks later" rationale.
- `.claude/commands/curate.md`: delete the "Why:" paragraph.
- `.claude/commands/plan.md`: replace the haiku-tier rule with a pointer to
  `.agents/docs/agent-selection.md`.
- `.agents/docs/manage-reference.md`: merge "Carried plan" and "Carried
  plan at retire", which both describe the RETIRED.md append. Keep the
  heading "Carried plan at retire": manage.md cites it, and
  `selftest/orchestrated.sh` checks the two-way pointers.

## Assumptions

- A1: Quotes are from origin/main 860a3f9c. Find each by its text — evidence: `git grep -n '#251\|#461\|known limits' .claude/commands` — confidence: high.
- A2: The clerk and conduct role files already say they write no workstream file — evidence: `grep -n 'workstream file' .claude/commands/clerk.md .claude/commands/conduct.md` — confidence: medium. Confirm before editing AGENTS.md.
- A3: Selftests may assert phrases in these files — evidence: `grep -rln 'clerk.md\|scout.md\|manage.md\|conduct.md' .agents/harness/selftest` — confidence: medium. Keep any phrase a hit asserts.

## Out of scope

- `.claude/commands/orchestrate.md`, `keeper.md`, `start.md` and
  `.agents/docs/orchestrate-reference.md`: plan simplify-orchestrator-commands
  owns them.
- Code changes such as a `role --noop` or `role --twin` flag that would
  replace the no-op record prose and twin-check prose. Record each as a
  `## Review` finding with `wontfix: code change, separate plan`.
- Any new rule. This plan removes text.

## Acceptance

- `git grep -nE '#251|#461|known limits' .claude/commands`: no output.
- `cat .agents/harness/AGENTS.md .claude/commands/{manage,clerk,scout,conduct,curate,upstream-report,plan}.md .agents/docs/manage-reference.md | wc -l`: at most 1220 (1381 today).
- `wc -l < .agents/harness/AGENTS.md`: at most 110. The always-loaded file must not grow by more than the exemption clause.
- `./joharness.sh ci`: `ci: pass`.
- Consumer-side check: the same `./joharness.sh ci` runs in every consumer after sync and lints these files (glossary, anchors).
- `./joharness.sh verify`: `0 failed`.
- The pull request body lists each deleted duplicate and the home that
  still states it.

## Where to look

- `.agents/harness/AGENTS.md:Finish`: the single home of the merge gate.
- `.claude/commands/clerk.md:THE SCOUT GATE`: the single home of comment counting.
- `joharness.sh:block_reason_ok`: the block reasons.
- `.agents/docs/caveman.md:Status quo`: the rule.

## Traps

- `.agents/harness/selftest/orchestrated.sh` pins exact phrases in these files. Before cutting a sentence, `grep -n` it in that selftest. A pinned phrase stays byte-exact. Never edit the selftest to fit.
- AGENTS.md is protocol text, not a core path, but every session loads it.
  Net growth is a regression.
- `ci` lint_glossary bans `handover file`, `model tier`, `env layer`,
  `rescope manager` and `bare role title`.
- Sibling plan simplify-orchestrator-commands cuts orchestrate-reference.md's
  comment rules to a pointer at clerk.md. Keep the THE SCOUT GATE heading
  text unchanged so that pointer resolves.
