---
plan: compact-queue-docs
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/handover/README.md, .agents/docs/handover/TEMPLATE.md, .agents/docs/plans/README.md, .agents/docs/plans/TEMPLATE.md, .agents/docs/product/README.md, .agents/docs/product/TEMPLATE.md, .agents/docs/research/README.md, .agents/docs/research/TEMPLATE.md, .agents/docs/graph.md
---

## Goal

The user asked to simplify and compact the protocol. Cut the queue and
handover docs deeper than round one (#588-#593): one home per rule, no
history (`.agents/docs/caveman.md`, Status quo), caveman compression.
Behaviour does not change.

## Scope

Files: handover README and TEMPLATE, plans README and TEMPLATE, product
README and TEMPLATE, research README and TEMPLATE, graph.md. Together 1305
lines on origin/main 5adc5d0c. Target: 900 lines or fewer.

- `.agents/docs/handover/README.md` (368 → about 190):
  - Replace "What a workstream file looks like", a second filled-in TEMPLATE, with one line pointing at TEMPLATE.md.
  - Merge "How a session finds this", "Coverage" and "Overlap matters" into "Concurrent sessions".
  - Cut the liveness mechanics (`session_status`, `ToolSearch("+list_sessions")`) to a pointer at `.claude/commands/who.md`.
  - "Pull requests: link, never duplicate": keep only the recovery-command rule.
  - Delete the Review-form restatement. Loop step 5 and TEMPLATE own the form.
  - Compress "In-flight order" and the "Survives PR" bullet.
  - Status quo cuts: "A lock is deliberately **not** implemented."; "A branch visibly churning…"; "Split forced by platform…"; the "Orchestration sits above it" rationale.
- `.agents/docs/plans/README.md` (253 → about 150):
  - "field discipline fails exactly when someone hurries": point at graph.md, its home.
  - Delete "Why files, not issues" (rationale for a rejected design).
  - Keep the codejunkie99 citation, but drop the scaling-study story.
  - Halve the `shared:` and core-path paragraphs. Keep the strings `CORE ONLY` and `OVERLAP-BOUND`.
  - Compress "What identifies a plan" to the rule.
  - Keep "A human remainder" as about 3 lines. The procedure lives in manage-reference.md.
- `.agents/docs/plans/TEMPLATE.md` (81 → about 55): one comment line per frontmatter key. The README owns the explanations.
- `.agents/docs/product/README.md` (195 → about 110):
  - Shrink "Orchestration" to a pointer at orchestrated.md, dropping the "one merge in four" story and its git block.
  - Shrink "Reconciliation" to a pointer at consumer-repos.md.
  - Fold "A deleted requirement does not say WHICH" into the Retired unsatisfied bullet.
  - Compress "Claiming a requirement" to about 8 lines. Compress Held and Intake facts.
  - Cut "An epic branch buys…" and "Squash breakage…", plus the Branch flow lines AGENTS.md step 3/7 already state. Keep "Conflict at finish".
- `.agents/docs/research/README.md` (174 → about 95):
  - Merge "What makes a file a node" into "Which files are nodes".
  - Diamond rule: point at graph.md.
  - Shape: one line per section.
  - Status quo cuts: "A consumer synced before this protocol…"; "Both names are in use…"; "Three words, not two…"; "Known limits: a rename…"; "The failure the section exists to catch…".
- `.agents/docs/research/TEMPLATE.md`: drop the comment lines that repeat README Edges.
- `.agents/docs/graph.md` (79 → about 60): shrink the "No datastore" and "A harness that lives in the repo" rationale to one line each.
- `.agents/docs/handover/TEMPLATE.md`: drop "Highest-value section: …", which the README already says.

## Assumptions

- A1: The quotes above are on origin/main 5adc5d0c — evidence: `git grep -n 'Why files, not issues\|What a workstream file looks like\|A lock is deliberately' .agents/docs` — confidence: high.
- A2: `role_claim_write` copies the handover TEMPLATE body with `<!--` comment blocks stripped — evidence: `joharness.sh:role_claim_write` — confidence: medium.
- A3: research README sentences are asserted literally — evidence: `.agents/harness/selftest/review.sh` — confidence: high.

## Out of scope

- Code and selftests, including the stale "(handover/README.md, Status)" in `handover-context.sh`.
- `.claude/commands/who.md`, which plan compact-role-commands owns. Other docs belong to sibling plans.
- Renaming any heading or frontmatter key.

## Acceptance

```bash
cat .agents/docs/handover/*.md .agents/docs/plans/README.md .agents/docs/plans/TEMPLATE.md .agents/docs/product/*.md .agents/docs/research/*.md .agents/docs/graph.md | wc -l   # <= 900
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
git diff --name-only origin/main...HEAD | grep -v '\.md$'   # empty
```

- The pull request body lists each deleted duplicate and the home that still states it.
- Consumer side (SHIPS): after its next sync a consumer runs `./joharness.sh ci` → `ci: pass`; the files carry no canonical-only text.

## Where to look

- `.agents/harness/selftest/handover-context-review-line.sh:template`: the `## Review` placeholder in TEMPLATE must not start with `- `.
- `joharness.sh:review_count`: parses `## Review`. `joharness.sh:lint_anchors` parses `## Where to look`.
- `.agents/harness/selftest/review.sh:research`: pinned research README sentences.
- `.agents/NOTICE:codejunkie99`: attribution naming graph.md and plans/README.md.

## Traps

- Headings cited by code or docs stay word for word:
  - handover README: Reviewing, "When NOT to write one", Graduation, "Survives PR", "Compaction: task state survives, the rules decay", "Claiming an issue", Staleness.
  - plans README: "Fast lane", Shape, Lifecycle, "A human remainder".
  - product README: "Branch flow", "Conflict at finish", "Claiming a requirement", "A requirement no plan can serve", Reconciliation, "The scout's brief" (and its 4 headings).
  - research README: "Which files are nodes". graph.md: Rules.
- Template headings and frontmatter keys are parsed. Keep every one.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope manager`, `bare role title`.
- Never skip, disable or quarantine a test to get green.
