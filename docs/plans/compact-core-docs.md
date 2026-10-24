---
plan: compact-core-docs
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md, .agents/docs/feedback.md, .agents/docs/agent-selection.md, .agents/docs/caveman.md, .agents/docs/subagents.md, .agents/docs/glossary.md, .claude/agents/verifier.md, .claude/agents/plan-checker.md
---

## Goal

The user asked to simplify and compact the protocol. Every session loads
`.agents/harness/AGENTS.md`, so a line cut there pays most. Cut it and the
reference docs deeper than round one (#588-#593): one home per rule, no
history (`.agents/docs/caveman.md`, Status quo), caveman compression.
Behaviour does not change.

## Scope

Files: the nine in `scope:`. Together 1413 lines on origin/main 5adc5d0c.
Target: 1150 lines or fewer, with AGENTS.md at 85 lines or fewer.

- `.agents/harness/AGENTS.md` (108 → 85 or fewer):
  - Intro: point at caveman.md Status quo instead of restating it.
  - Step 2: shrink the tier-binds clause to a pointer at agent-selection.md.
  - Step 3: "(`--force-with-lease` only in orchestrate GUARD, janitor, halt)" becomes a pointer, or is dropped if the orchestrator docs state it.
  - Step 5: shrink the review-record form to one line plus a pointer.
  - Step 5: drop the background/`pgrep -f` clause ONLY IF `pretool-bash-guard.sh` and `pretool-self-kill-guard.sh` refuse both cases. Record the check in `## Decisions`.
  - Step 7: compress the `JOHARNESS_CHECKS=local` paragraph to about 3 lines.
  - Decide alone: the block `human-review` labelling becomes a pointer at manage.md §3.
  - `## Handover`: one line.
- `.agents/docs/caveman.md`:
  - Shrink "Controlled vocabulary: built, not invented…" to 2 lines.
  - Delete the "NO row" lines (glossary.md owns them).
  - Merge "What it costs" into "Where it applies". Keep one of the two license-travel notes. Make "Honest numbers" 2 lines.
- `.agents/docs/glossary.md`: keep the rule "code names win" and drop its history. Compress "Two consequences" and "Prose only".
- `.agents/docs/agent-selection.md`:
  - Drop the Opus 5 comparison, the "Unenforced on purpose" rationale and the "(re-check if…)" note.
  - "Effort does not cross a spawn" becomes a pointer at subagents.md. Make "Behavior findings" one line each.
- `.agents/docs/feedback.md` (253 → about 160):
  - Keep the window rule (`JOHARNESS_RECURRENCE_WINDOW`, default 8). Drop the scoring argument and the uncommanded "86%" number.
  - "Volume is not a score" becomes a pointer at agent-selection.md.
  - Strip incident clauses from both worked examples. Keep the heading "tree or diff".
  - Shrink §4, §6 and §8.
- `.agents/docs/consumer-repos.md` (438 → about 330):
  - Merge the two "Settings a child…" sections.
  - Compress "Two things to know", "A red base branch" and the Local checks pseudo-list.
  - Point the verify path list at AGENTS.md step 7. Shorten the `.gitattributes` bullet.
  - Add the missing blank line before "## Update: by hand".
- `.agents/docs/subagents.md`:
  - Drop "measured 2026-08-25". Make "Standing in for session fan-out" a pointer.
  - Shrink "Moving the tree under a live reviewer" to about 5 lines and drop its meta line about Loop step 5.
  - Fix the "route 2" pointer if the Pick route table says row 3.
- `.claude/agents/verifier.md`: drop the 14-finding incident, "Said plainly because…" and the "Where the rules live" list. Compress the "formally indistinguishable" passage.
- `.claude/agents/plan-checker.md`: tighten only.

## Assumptions

- A1: The quotes above are on origin/main 5adc5d0c — evidence: `git grep -n 'Controlled vocabulary\|Unenforced on purpose\|Said plainly' .agents/docs .claude/agents` — confidence: high.
- A2: The two pretool guards refuse an unbounded background command and a self-matching `pgrep -f` — evidence: `.agents/harness/pretool-bash-guard.sh`, `.agents/harness/pretool-self-kill-guard.sh` — confidence: low. Read them before dropping the clause.
- A3: AGENTS.md single-line `grep -q` pins exist — evidence: `git grep -n 'never green\|never call the GitHub API\|no commit to a core path' .agents/harness/selftest` — confidence: high.

## Out of scope

- The session-start hook text in `joharness.sh`. It restates Loop steps 2, 3 and 7 and is code.
- Lowering `reading-budget.sh` caps, and other selftest edits.
- Changing any rule, step number or the Loop's seven-step shape.
- Files outside `scope:` (sibling plans: compact-orchestration-docs, compact-queue-docs, compact-role-commands).

## Acceptance

```bash
wc -l < .agents/harness/AGENTS.md   # <= 85
cat .agents/harness/AGENTS.md .agents/docs/{consumer-repos,feedback,agent-selection,caveman,subagents,glossary}.md .claude/agents/{verifier,plan-checker}.md | wc -l   # <= 1150
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
git diff --name-only origin/main...HEAD | grep -v '\.md$'   # empty
```

- The pull request body lists each deleted duplicate and the home that still states it.
- Consumer side (SHIPS): after its next sync a consumer runs `./joharness.sh ci` → `ci: pass`; the files carry no canonical-only text.

## Where to look

- `.agents/harness/selftest/orchestrated.sh:AGENTS`: folded needles '2. **Pick.** Role routing only' and 'each is in the one list dispatch accepts, `joharness.sh:block_reason_ok`'. Absent: "Block ONLY for money, credentials, hardware", "Finishing outranks starting".
- `.agents/harness/selftest/review.sh:verifier`: verifier.md lines matched unfolded.
- `.agents/harness/selftest/license-notice.sh:caveman`: the license block is byte for byte.
- `.agents/harness/selftest/handover-context-compact.sh:core path`: the "no commit to a core path" pin.

## Traps

- One-line pins in AGENTS.md: "A skipped `lint` check is never green", "Harness commands never call the GitHub API", "no commit to a core path".
- verifier.md one-line pins:
  - "The boundary, in the words the research README also uses: `outside this checkout`."
  - "Mark it UNVERIFIED, naming the reading you could not take."
  - "best, never GROUNDED".
- glossary.md stays a table. Its role-title row strings are pinned.
- Cited headings stay word for word:
  - caveman: "Status quo", "Never touch". glossary: "One meaning, or nothing".
  - consumer-repos: "Local checks", "Direction rule", "What a consumer carries", "drive it to merged", "When the consumer is the detector".
  - agent-selection: Lineup, "Review churn", "Review depth", "Cost levers". verifier: "What you cannot see".
  - The consumer-repos internal `#anchor` links.
- Loop step numbers 1-7 stay.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope manager`, `bare role title`.
- Never skip, disable or quarantine a test to get green.
