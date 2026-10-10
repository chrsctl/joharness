---
plan: late-finding-has-an-issue-route
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:.agents/docs/feedback.md, shared:.agents/harness/AGENTS.md
---

## Goal

Issue #339. A consumer session's harness finding is captured in the
workstream file's `## Review` or in a canonical pull request body
(`feedback.md`, "4. Inline or routed"), and the reporter reads it from the
retired workstream file. Loop step 7 deletes that file before the pull
request opens. A finding that surfaces later — the stop hook fires at the
end, after the retire commit by construction — has no route, and with
`JOHARNESS_UPSTREAM_FEEDBACK` off (the default) no reporter runs either.
Measured in `chrsctl/gx`, 2026-10-10: issue #338 reached canonical only
because the human read it in chat and said "file it". Give that window a
floor: an issue on the canonical, carrying the measurement. A route
available, never an order to file.

## Scope

- `.agents/docs/feedback.md`, section `### 4. Inline or routed`: extend the
  "Capture always, immediately" bullet with a third place, used only when
  neither a workstream file nor an open CANONICAL pull request exists (the
  consumer's own pull request may well be open — after the retire commit it
  usually is; it carries no `## Review` and does not count): an issue on the
  repo named by `CANONICAL_REPO` (`.github/workflows/update.yml`). Then one
  short paragraph saying:
  - why it is compatible with the default-off posture, argued, not denied:
    an issue IS a write to a repo the child does not own, but it carries no
    diff, merges nothing and asks canonical only to read; and it is one API
    call from the session already running, not a session beyond
    `JOHARNESS_MAX_MANAGERS`;
  - every mode, one bound: at most ONE such issue per session, and search
    canonical's open issues for the same finding first — a match gets
    nothing new filed. Unattended sessions (unsupervised, orchestrated) are
    included because they are where nobody reads the chat; the bound is
    what keeps a guard that fires at every stop from filing at every stop;
  - it satisfies the direction rule: nothing lands in the consumer;
  - the gate still holds: stage 1's question ("does the fact it states match
    what it measures?") clears each finding first, and the issue carries the
    command and the output that produced it — the bar Loop step 5 sets for a
    measured number. An issue without it is a preference; canonical closes
    it as one;
  - the session cannot reach the canonical (no access in its GitHub scope)?
    Hand the human the issue text in its reply. Never drop it silent.
  - #338 as the first instance.
- `.agents/harness/AGENTS.md`, Loop step 7, at the sentence that tells the
  session to delete the workstream file: one caveman line — finding after
  the retire commit, consumer repo: issue on the canonical, with the
  measurement (`.agents/docs/feedback.md`, Inline or routed). Keep it one
  line; this file is short on purpose.

## Out of scope

- `./joharness.sh upstream --issue` (#339's optional third bullet). A
  command that composes and files an issue is new code, a new network
  surface and a new selftest; the floor is a sentence. A later plan can add
  it once the route has been used and measured.
- Making the issue route the default for findings that DO have a workstream
  file. #339 names that a separate question; the reporter's pull request
  carries a diff an issue cannot.
- Any change to `JOHARNESS_UPSTREAM_FEEDBACK`, the reporter
  (`.claude/commands/upstream-report.md`) or `cmd_upstream`.
- Canonical itself: a finding here is already where its fix lands
  (`cmd_upstream`'s canonical branch says so). The new text says
  "consumer"; do not write a canonical route.

## Acceptance

- `sed -n '/^### 4. Inline or routed/,/^### The switch/p' .agents/docs/feedback.md | grep -c 'issue'`
  → 1 or more (0 on `main` at 944d0e8, 2026-10-10).
- `sed -n '/^7\. \*\*Finish/,/^Queue still/p' .agents/harness/AGENTS.md | grep -ci 'issue'`
  → 1 or more (0 on `main` at 944d0e8, 2026-10-10).
- `./joharness.sh ci` → `ci: pass` (glossary spelling, caveman lint,
  anchors, context budget — `context` counts what the AGENTS.md line adds).
- SHIPS: both files reach consumers at their next sync; the consumer check
  is the next late finding arriving at canonical as an issue that carries
  its command and output.

## Where to look

- `.agents/docs/feedback.md` — `### 1. Decide whether the harness is
  actually wrong` (the gate), `### 4. Inline or routed` (the edit), `### The
  switch that mechanizes 1 to 4` (the two off-by-default reasons to quote).
- `.agents/harness/AGENTS.md` — Loop step 7, "Deleting the FILES is not
  optional and is yours".
- `joharness.sh:upstream_canonical_repo` — where `CANONICAL_REPO` is read.
- `.agents/docs/caveman.md` — style for the AGENTS.md line.

## Traps

- `agents-chain-dedupe` marks both files `shared:`; `upstream-placement-defects`
  touches `feedback.md` unmarked; `clerk-role` and
  `orchestrated-only-docs` touch `.agents/harness/AGENTS.md`. Expect a
  reconcile at step 7.
- "Never relax a guard that just caught you": the text must say the route
  is available, never that every irritation is filed.
- Write numbers with the command and date that produced them (Loop step 5).
