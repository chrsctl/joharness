---
workstream: scout-market-research
status: in-progress
branch: manage/scout-market-research
pr: none
plan: scout-market-research
issue: none
session: https://claude.ai/code/session_01G96ZHwPamMESwrquuNoQxP
agent: fable
updated: 2026-10-12
next: Retire plan claim; plan-only pull request; merge
---

## Goal

Planning pass on `docs/product/scout-market-research.md`: the scout should
research outside the repository (market, competitors, gaps, extensions),
propose as GitHub issues the reviewer can talk on, and only an `approved`
label applied by the named reviewer lets a proposal reach plans. This branch
writes plans only; it implements nothing.

## Decisions

- Branch `manage/scout-market-research`, cut from `origin/main` at 75e27cc1
  (`git fetch origin main`, 2026-10-12).
- Five plans, exit 1 plus exit 2 of `.agents/docs/product/README.md`:
  `scout-backlog-clock` (code: conf keys, backlog trigger, report lines),
  `scout-brief-home` (code: `SCOUT.md` never scheduled), then
  `scout-proposes-on-issues` (role text) and `scout-approval-gate` (clerk
  and manage text) in parallel, then `scout-evaluated-on-gx` (verify plan,
  deletes the requirement).
- Dispatch stays git-only: it counts open plans; the scout session counts
  open `scout:` issues and finishes the sum. No GitHub read in `joharness.sh`.
- Every proposal is an issue; the scout opens no pull request any more.
  `JOHARNESS_SCOUT_AUTOMERGE` and its reader stay byte for byte (requirement
  constraint) and so govern nothing — flagged in the pull request body.
- After approval the path is the clerk (existing). A human may still write a
  requirement file from an approved issue by hand; no role does.
- Request versus proposal on one label: a proposal's title starts `scout:`,
  a research request's does not.
- Digest: one comment on each issue the pass opened (the requirement's first
  option); a summary issue would read as a research request.
- Backlog trigger re-arms 24h after the last scout retire, a written number
  in code, so `NOTHING TO PROPOSE` does not respawn a scout every health
  pass. N default 24 = 3 days x 8 merges/day (`git log --merges
  --first-parent --since=14.days --format=%h origin/main | wc -l` = 118,
  2026-10-12 after merging origin/main at 10017ad1).
- Approval event reader: the GitHub MCP `issue_read` has no timeline method
  (schema read 2026-10-12); `gh` here has an invalid token (`gh auth status`,
  2026-10-12). The clerk plan names both readers and fails closed
  (`APPROVAL UNREADABLE`) without one.

## Rejected

- A plan frontmatter key marking scout origin: a second copy of the issue's
  label; every pull request derives the mark from the issue at open time.
- Reading proposal issues from `dispatch`: a GitHub dependency every
  consumer would pay on every health pass.
- Keeping the proposal pull request path beside the issue channel: the
  requirement says each proposal is an issue; two channels, two gates.
- A template file for the brief under `.agents/docs/product/`: the README
  section is the shape; a file is a second copy.

## Review

- r1: throughput command quoted without `--format=%h` prints 1078 lines, not 118 (verifier) (fixed: command carries `--format=%h ... | wc -l` in the conf row, the report line and this file)
- r2: N=0 "clock only" meets a ceiling of `0 - open`, so a clock pass proposes nothing (verifier) (fixed: `backlog : off` = no ceiling, in both plans)
- r3: dispatch counts plans only, so an unreviewed pile re-spawns a fable scout each 24h (verifier) (fixed: ceiling computed in §0 before any outside read, `WAITING ON REVIEW` retire; cost named in scout-backlog-clock and accepted — dispatch stays git-only)
- r4: the 24h re-arm reads the unmerged-branch retire only past 168h, so a consumer gets a second scout 1h after the first (verifier) (fixed: backlog trigger reads `scout_retired_ts` on every call, fixture case added to acceptance)
- r5: "last revision" named the body's last edit, which no reader returns and `updated_at` conflates with the label event (verifier) (fixed: the scout's last comment is the marker; the scout never edits a body without one)
- r6: freezing `cmd_scout`'s and dispatch's AUTOMERGE sentences leaves two triggers telling two stories (verifier) (fixed: the key stays, the printed sentences change; acceptance quotes both lines)
- r7: `grep -c SCOUT joharness.sh` already reads 22 (verifier) (fixed: `SCOUT\.md` and the hook's alternation, counts given)
- r8: `sampling-conduct-reviewer` in flight edits the same conf-row and selftest hunks, unnamed in Traps (verifier) (fixed: named; the hold is the right behaviour)
- r9: branch 6 behind `origin/main`; `relayed-answer-is-quoted` merged, clerk.md §2 rewritten (verifier) (fixed: merged in, approval-gate Scope reads the merged §2, stale plan name dropped)
- r10: acceptance grep for "never ... approved" was not in the clerk.md Scope (verifier) (fixed: `## Never` line added to Scope, grep reads that section)
- r11: curate PROPOSEs product README claimed by two ordered plans (verifier) (fixed: `shared:` on both; `needs:` orders them)
- r12: one-line gx anchor thin for "the shape a record takes" (verifier) (fixed: agent-selection.md gx readings anchored too)
- r13: field spellings in the role plan (`brief :`) differ from the printed 10-char fields (verifier) (fixed: exact field names, acceptance counts them)
- r14: `issue_read` method list, `list_issue_types` on gx, `add_repo` — UNVERIFIED by the verifier, outside its reach; the method list was read from the tool schema in this session on 2026-10-12 (no change)

## Blockers

None.

## Where to look

- `docs/product/scout-market-research.md` — the requirement, requester's words.
- `.claude/commands/scout.md` — the scout role as it runs today.
- `joharness.sh:scout_due` — the clock the Backlog clause replaces.
