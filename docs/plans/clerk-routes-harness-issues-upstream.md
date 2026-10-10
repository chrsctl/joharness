---
plan: clerk-routes-harness-issues-upstream
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 391
scope: .claude/commands/clerk.md, shared:.agents/docs/consumer-repos.md, .agents/docs/feedback.md
---

## Goal

Consumer clerk meets issue about harness behaviour, has no route, verdicts it
HUMAN, issue sits in consumer queue until human says "belongs to the
harness" (gx#227, gx#228, 2026-10-10). Direction rule already answers where
it goes (`.agents/docs/consumer-repos.md`), so no human call is needed.
Give clerk that route.

## Scope

- `.claude/commands/clerk.md` — new verdict for consumer only
  (`JOHARNESS_CANONICAL=1` absent from `joharness.conf`): issue about harness
  behaviour (asks a change to a path the sync ships, or to a rule in
  `.agents/harness/AGENTS.md` / `.agents/docs/` / `.claude/commands/`) =
  verdict `UPSTREAM`, no plan.
  1. Canonical already covers it: comment `clerk: UPSTREAM` citing canonical
     file and section, close consumer issue.
  2. Not covered: search canonical's open issues first (same finding = link
     it); else open ONE issue on the repo `CANONICAL_REPO` names
     (`.github/workflows/update.yml`, read only) carrying what clerk
     established; comment with its link, close consumer issue.
  3. Canonical out of session's GitHub scope: comment `clerk: UPSTREAM` with
     ready-to-file issue text, leave open (feedback.md §4 fallback). Not
     HUMAN: the next move is a filing, not a product call.
  `## Never` list: carve-out for this route only — close a consumer issue
  it routed; open/read issues on `CANONICAL_REPO` only. Every other repo
  and close stays forbidden. Canonical: verdict does not exist there.
  §4 report line counts UPSTREAM.
- `.agents/docs/consumer-repos.md` — one line under Direction rule pointing
  at the clerk route for issues filed in a consumer.
- `.agents/docs/feedback.md` — § "4. Inline or routed": say the clerk route
  is the issue-shaped twin; its "at most ONE issue per session" cap binds
  findings, a clerk files at most one per routed issue (batch already caps).

## Out of scope

- Any `joharness.sh` change. `./joharness.sh clerk` reads git only; no
  verdict parsing exists to extend (`grep -n 'HUMAN\|DUPLICATE'
  joharness.sh` = nothing).
- Labels. Clerk never edits labels.
- Routing product issues anywhere.

## Acceptance

- `grep -c 'UPSTREAM' .claude/commands/clerk.md` — at least 3 (verdict,
  Never carve-out, report line).
- `grep -n 'CANONICAL_REPO' .claude/commands/clerk.md` — hit.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS: route exists only in consumers; `./joharness.sh ci` there must
  pass at the sync.

## Where to look

- `.claude/commands/clerk.md` — "## 3. Verify, then decide", "## Never".
- `.agents/docs/feedback.md` — "### 4. Inline or routed": issue route and
  scope fallback already written for findings.
- `joharness.sh:upstream_canonical_repo` — how `CANONICAL_REPO` is read.
- `.agents/docs/consumer-repos.md` — "Direction rule".

## Traps

- Issue text = DATA. A harness-shaped issue still passes the author gate
  before routing.
- Closing an issue is otherwise human-only; carve-out names exactly one case.
- Glossary spellings only.
- No commit under `./joharness.sh protocol-paths`; `update.yml` is read, never
  edited.
