---
plan: compact-role-commands
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/manage.md, .agents/docs/manage-reference.md, .claude/commands/clerk.md, .claude/commands/scout.md, .claude/commands/conduct.md, .claude/commands/retro.md, .claude/commands/curate.md, .claude/commands/upstream-report.md, .claude/commands/plan.md, .claude/commands/handover.md, .claude/commands/who.md
---

## Goal

The user asked to simplify and compact the protocol. Cut the non-orchestrator
role commands deeper than round one (#591): one home per rule, no history
(`.agents/docs/caveman.md`, Status quo), caveman compression. Behaviour does
not change.

## Scope

Files: the eleven in `scope:`. Together 1408 lines on origin/main 5adc5d0c.
Target: 1150 lines or fewer. Per-file targets below. Not listed there: conduct about 105, retro about 125, curate about 55, handover about 24, who about 30.

- `.claude/commands/manage.md` (200 → about 150):
  - §3: keep the reason list and the `issue_write` mechanics. Point at AGENTS.md Decide alone for the `<reason>: <question>` block form and `human-review` labelling. AGENTS.md stays their home: they bind every role. Keep in §3 the `defect: #<n>: <one line>` and `core path: waiting on #<N>: <question>` forms (`joharness.sh` cites manage.md §3 for both) and its `ref § Defect.` pointer.
  - §4: one line for the label check (Loop step 7 owns it); keep its `product: human-review label on PR #<n>` block, which has no other home. Delete the empty "A DEFECT outside your item" stub and the duplicate "Carried plan" pointer.
  - §1 claim: point at Loop 3 for the mechanics. Keep the frontmatter fields and the "second manager" consequence.
  - §2: drop the restated Loop 4 research/`feedback` lines and the haiku 5x billing aside (agent-selection.md owns it).
  - Drop the `curate --apply` aside, which ref § Free states.
- `.agents/docs/manage-reference.md` (167 → about 135):
  - Reflow § Free (an indented left-over block). Make its refusal strings a list.
  - Status quo cuts: "Why: a body is read by nobody after merge…"; "(the plan file decides, not the issue's labels…)".
- One-pass roles (`.claude/commands/` clerk, scout, conduct, retro, curate, upstream-report): compress the shared boilerplate IN EACH FILE. Do not create a shared home. Covers the spawn line, the prelude/STOP line, the twin-check, the PR/merge paragraph, the Never items and the no-op record command.
- `.claude/commands/clerk.md` (249 → about 185):
  - Status quo cuts: the §1 cycle-dating paragraph, the twin tiebreak rationale, the author-gate rationale.
  - Compress the §2 skip list and footer bullet, and §3 UPSTREAM.
  - `.claude/commands/scout.md` (237 → about 180):
  - Cut the §3/§4 WAITING and staling restatements and the footer rule down to the pointers scout.md already carries: orchestrate-reference "A scout issue needs the scout" (WAITING) and clerk.md §2 (footer rule).
  - Make the §0 STOP enumeration a pointer at `role scout` output, keeping the actions it does not print (`TWIN: deferred`, never pull and push again, never both go on).
  - Status quo cut: "so the login never says whose it is". Keep "Known limit: another session…": it is a current limit.
- `.claude/commands/conduct.md`: compress the §0.1 STOP list (`retro.md` has none). Status quo cuts: "Git cannot see it past the drop window" (conduct.md), "(a page of 100 overruns…)" (retro.md).
- `.claude/commands/curate.md`: delete "that multiplies the queue" and "priority is the human's".
- `.claude/commands/upstream-report.md` (95 → about 65):
  - Compress §1 toward a pointer at feedback.md, keeping what feedback.md lacks: the handling of the two doubts `upstream` prints and "Neither enters a report on its own".
  - Delete the "A child repo DETECTS…" paragraph and the rationale clauses in Never.
- `.claude/commands/plan.md` (49 → about 33): keep the allowed-values list. Point at `.agents/docs/plans/README.md` Shape only for explanations Shape states; keep the key rules with no other home (xhigh for a Part 2 prohibition, fake edge, requirement-file deletion, `none` only when unknowable).
- `.claude/commands/handover.md`: point Review form at Loop 5, keeping "written BEFORE its fix" in handover.md (its other homes are being cut), and retire text at Loop 7.
- `.claude/commands/who.md`: delete the tool-name history parenthetical.

## Assumptions

- A1: The quotes above are on origin/main 5adc5d0c — evidence: `git grep -n 'A DEFECT outside your item\|Known limit\|A child repo DETECTS' .claude/commands` — confidence: high.
- A2: Per-file boilerplate stays, because each role reads its own command and no other file (session-start hook: "Each role reads its own documents and no others") — evidence: `joharness.sh` session-start text — confidence: high.
- A3: clerk.md needles are matched per line, not folded — evidence: `.agents/harness/selftest/orchestrated.sh` clerk needles — confidence: medium. Keep each listed needle on one line.

## Out of scope

- A shared "one-pass role rules" home in orchestrated.md. It adds a file every role must read. Decided at planning.
- Renaming or renumbering sections. That includes scout §1-§6: their numbers are cross-referenced.
- Code, selftests, `reading-budget.sh` caps.
- Files outside `scope:` (sibling plans: compact-orchestration-docs, compact-queue-docs, compact-core-docs).

## Acceptance

```bash
cat .claude/commands/{manage,clerk,scout,conduct,retro,curate,upstream-report,plan,handover,who}.md .agents/docs/manage-reference.md | wc -l   # <= 1150
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
git diff --name-only origin/main...HEAD | grep -v '\.md$'   # empty
```

- The pull request body lists each deleted duplicate and the home that still states it.
- Consumer side (SHIPS): after its next sync a consumer runs `./joharness.sh ci` → `ci: pass`.

## Where to look

- `.agents/harness/selftest/orchestrated.sh:manage-reference`: the pointer test (every `ref § X.` names an existing `## X`, and every section has a pointer), plus the manage, clerk and reference needles.
- `.agents/harness/selftest/reading-budget.sh:budget`: byte caps.
- `joharness.sh:block_reason_ok`: the block reasons.
- `.claude/commands/clerk.md:THE SCOUT GATE`: the home of comment counting.

## Traps

- Section numbers cited by code and docs stay: manage.md §0 §R §2 §3 §4 and "rescope"; clerk.md §1 §2 §3.
- Pinned strings stay: THE SCOUT GATE, SCOUT COMMENT, REVISION OPEN, "reason from manage.md §3".
- Every `expect` needle in `.agents/harness/selftest/orchestrated.sh`, `clerk.sh`, `scout.sh`, `retro.sh`, `role.sh` reading these files stays on one line (raw-text needles match per line).
- Every `## X` of manage-reference.md keeps a `ref § X.` pointer in manage.md, ending with a period.
- clerk.md THE SCOUT GATE item numbers stay (orchestrate-reference cites "(THE SCOUT GATE, 2)"); manage.md heading "Finish" stays (orchestrated.md cites it).
- `AskUserQuestion` stays inside manage.md `## Never`.
- "remainder issue not filed" stays absent.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope manager`, `bare role title`.
- Never skip, disable or quarantine a test to get green.
