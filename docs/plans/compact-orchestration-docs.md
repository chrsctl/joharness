---
plan: compact-orchestration-docs
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/orchestrated.md, .agents/docs/orchestrate-reference.md, .claude/commands/orchestrate.md, .claude/commands/keeper.md, .claude/commands/start.md
---

## Goal

The user asked to simplify and compact the protocol. Round one (#588-#593)
cut protocol markdown about 6%. Cut the orchestration docs deeper: one home
per rule, no history (`.agents/docs/caveman.md`, Status quo), caveman
compression. Behaviour does not change.

## Scope

Files: the five in `scope:`. Together 1549 lines on origin/main 5adc5d0c.
Target: 1250 lines or fewer.

- `.agents/docs/orchestrated.md` (624 → about 380). Keep one home, point to it:
  - Cap: "`JOHARNESS_MAX_MANAGERS` caps managers only". The home is orchestrate.md §3. orchestrated.md keeps one sentence.
  - The GONE definition ("Gone is ARCHIVED, not found on the control plane"). The home is orchestrate.md.
  - The health table copy. The home is orchestrate.md step 2. Keep "two signals: git plus control plane".
  - "`updated_at`/`cost_usd` decide nothing" ("Nor frozen cost, at any floor"). The home is ref § Control plane fields.
  - `### Messaging`, "A refused stop reads as absent", "fresh session is cheaper". The home is orchestrate.md § Tools or the ref.
  - "Loops are not stalls" and the kill steps 1-4. The home is ref § KILL and LOOP. Keep "The branch is the claim and the claim survives the kill."
  - `### CEILING? is a report`, "`suspect a stopped fleet` decides nothing", `### Bounds, orchestrator`. The home is orchestrate.md (Never / table). Bounds, orchestrator keeps only its `env` line.
  - The "What each role reads" table. Each role command owns its reads.
  - The block-reason list "(money, credentials, product, …)". Point at `joharness.sh:block_reason_ok`.
  - The defect `PARKED` paragraph. The home is ref § Resume.
  - Keeper liveness. The home is keeper.md. Mind the needles under Traps.
  - The hook rule "A hook `.claude/settings.json` registers runs from". The home is manage.md §2.
  - Role table rows (curate, clerk, scout, conduct, retro): one line plus a pointer each.
  - Compress the plan-queue table row 4 and the `CORE ONLY` Bounds bullet. Keep Bounds as the home of the `human-review` label rule.
  - Drop the duplicate H1/H2 "How the harness runs". Merge "Periodic roles ride the heartbeat" into Heartbeat.
  - Delete "A carried plan reads as a leftover" (implementation detail of `dispatch_branch_plans`).
  - Status quo cuts:
    - Rewrite "Bound, not fresh" in present tense, dropping the measurement story and its date. Keep its pinned clauses.
    - Delete: "a long suspension reads every live manager as stalled"; "A floor would have to sit above…"; the "Guard makes…" rationale; "Tuning the prompt until a session stops refusing"; "Most such collisions are…"; "None of these is an `updated_at` threshold"; the "Hazard: once the owner's branch merges" narrative (keep the rule); "are unmeasured, so both rules fail toward"; "an operator may want it higher"; the "A frozen orchestrator still reading `RUNNING`… Unresolved." note.
- `.agents/docs/orchestrate-reference.md` (473 → about 420):
  - Compress § Resume RECHECK by about 30% and § Role sessions "The human orders an extra role session".
  - Drop the "(glossary, role title…)" parentheticals.
- `.claude/commands/orchestrate.md` (326 → about 300):
  - Merge the "Messaging: (1)…(2)…" list into the pinned sentence below it.
  - Delete "Retitling a session the keeper already retitled changes nothing."
- `.claude/commands/keeper.md`: shrink only. It is 1 byte under its reading budget.
  - Delete "'## 0. Start' is `orchestrate.md`'s." and the role-title parenthetical.
- `.claude/commands/start.md` (29 → about 12):
  - Drop L7-18 (restates `cmd_start` output and the orchestrate guard).
  - Drop the scout lines (scout.md owns them).

## Assumptions

- A1: The quotes above are on origin/main 5adc5d0c. Find each by text — evidence: `git grep -n 'Loops are not stalls\|Bound, not fresh\|What each role reads' .agents/docs/orchestrated.md` — confidence: high.
- A2: Selftest needles fold newlines to spaces, so reflowing is safe and rewording a needle is not — evidence: `.agents/harness/selftest/orchestrated.sh` needle helper — confidence: medium. Confirm before reflowing.
- A3: Every `## ` heading in orchestrate-reference.md must be named by a `ref § <name>` in orchestrate.md — evidence: `.agents/harness/selftest/orchestrated.sh` pointer test — confidence: high.

## Out of scope

- Code: `joharness.sh`, hooks and selftests. That includes moving prose into code comments, lowering `reading-budget.sh` caps, and fixing selftest/dispatch.sh's stale "orchestrated.md, Runs" comment.
- Any file outside `scope:`. Sibling plans own the rest: compact-queue-docs, compact-role-commands, compact-core-docs.
- New rules or behaviour. A rule whose deletion changes what a session does stays.
- The ref § 0. Start older-spec Routine branch: it is behaviour.

## Acceptance

```bash
cat .agents/docs/orchestrated.md .agents/docs/orchestrate-reference.md .claude/commands/orchestrate.md .claude/commands/keeper.md .claude/commands/start.md | wc -l   # <= 1250
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
git diff --name-only origin/main...HEAD | grep -v '\.md$'   # empty
```

- The pull request body lists each deleted duplicate and the home that still states it.
- Consumer side (SHIPS): after its next sync a consumer runs `./joharness.sh ci` → `ci: pass`; the files carry no canonical-only text.

## Where to look

- `.agents/harness/selftest/orchestrated.sh:needle`: the pinned phrases and the ordering pins (keeper SWAP 1 before 2; orchestrate.md `^RETIRE.`, `^RUN END.`, `^## Report, every pass`).
- `.agents/harness/selftest/reading-budget.sh:budget`: byte caps (keeper.md at its limit).
- `.agents/harness/selftest/knobs-declared.sh:knob`: the knob table shape `| \`KEY\` | default |`.
- `.agents/harness/selftest/retro.sh:RETRO_KILL_NOTE`: the KILL/LOOP note text in the ref.
- `.agents/docs/caveman.md:Status quo`: the rule.

## Traps

- Headings other files cite stay word for word: Bounds, Roles, Concurrency, "A plan the queue cannot see", Heartbeat, Health, "The one stop", Authority, "How the harness runs", "The numbers are the human's", "Start each run fresh", "The guard before a harness push", "A spawn the human orders carries the plan"; ref "## 0. Start", "A scout issue needs the scout", KILL, LOOP, Resume; orchestrate.md "step 2".
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope manager`, `bare role title`.
- Never skip, disable or quarantine a test to get green.
