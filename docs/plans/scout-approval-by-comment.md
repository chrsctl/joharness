---
plan: scout-approval-by-comment
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 459
scope: shared:.claude/commands/clerk.md, shared:.claude/commands/scout.md, shared:.agents/docs/orchestrated.md, shared:.agents/scripts/conf-keys.sh
---

## Goal

The clerk's scout gate approves a proposal only through the `approved`
LABEL EVENT, read from the issue timeline. In a cloud session the reader
is gated on `gh auth status`, which fails while `gh api` works (#459,
reproduced 2026-10-13: `gh auth status` rc=1, `gh api
repos/chrsctl/joharness/issues/453/timeline --paginate` rc=0), and behind the
proxy `--paginate` past page one fails (403 on a numeric-ID path, measured
2026-10-13). And "any later comment stales the approval", so a reviewer
cannot ask and approve in one thread (#460 §1, #461 item 2).

Decided by the owner in the clerk session, 2026-10-13 (issue #461 item 2,
answered "Comment approval"): approval = the reviewer's newest counting
comment, read with `issue_read get_comments`, which every session has.
The label `approved` stays as a visible marker only. The PR closes #459,
#456 and #461's item 2 (`Closes #459`, `Closes #456`; `Refs #461` while
other plans name #461).

## Scope

- `.claude/commands/clerk.md` THE SCOUT GATE — rewrite items 1–4: a proposal is approved when its NEWEST counting comment (author = the `reviewer  :` login; no Claude Code attribution footer; not opening `clerk:` or `scout:`) has `approved` as its first word, and is newer than the newest `scout:` comment on the issue (footed, by an author with write access). Read with `issue_read get_comments` (all pages). Unreadable comments = skip, report `APPROVAL UNREADABLE: <error>`; never fall back to the label. Remove the timeline reader, both fallbacks, the label-event rule and the "any later comment stales" rule. The gate keeps fail-closed, the author gate, `reviewer : none` = no proposal, CLOSED = declined. Target under 15 lines (#461); count it at merge.
- `.claude/commands/scout.md` §5 Revise — the `scout: revising` / body edit / `scout: revised` bracket collapses to: edit the body, then post ONE `scout: revised` comment (newer than `approved`, so approval is needed again). Every place in scout.md that says the label is the gate says the comment is.
- `.agents/docs/orchestrated.md` — the scout approval text and the `JOHARNESS_SCOUT_REVIEWER` row ("whose approved label gates") say the comment.
- `.agents/scripts/conf-keys.sh` — the `JOHARNESS_SCOUT_REVIEWER` description, if it names the label.

## Out of scope

- The trigger, the budget, the digest: plans `scout-reviewer-trigger` and `scout-budget-by-count`.
- `joharness.conf`: a core path; the human edits it.
- Any automatic `approved` labelling.

## Acceptance

- `grep -c -i 'timeline\|gh auth\|labeled event' .claude/commands/clerk.md` — `0` (non-zero on main today).
- `grep -c 'get_comments' .claude/commands/clerk.md` — at least `1` in THE SCOUT GATE.
- `sed -n '/THE SCOUT GATE/,/AUTHOR GATE/p' .claude/commands/clerk.md | wc -l` — under 15, recorded in the workstream file with the date.
- `grep -c 'scout: revising' .claude/commands/scout.md` — `0`.
- `grep -n 'fall back' .claude/commands/clerk.md` — the "never fall back to the label" rule present.
- Walk the gate in the workstream file `## Review` on four cases: reviewer comments `approved` after `scout: revised` → taken; `scout: revised` after `approved` → skipped; a stranger's `approved` → skipped; a footed `approved` by the reviewer's login → skipped.
- `./joharness.sh ci` — `ci: pass`.
- Plan ships: consumer check = on `chrsctl/gx` after sync, the clerk pass takes gx #645 once its reviewer comments `approved` there.

## Where to look

- `.claude/commands/clerk.md` — "THE SCOUT GATE" through "Then the AUTHOR GATE"; §2's footer and counting-comment rules (reuse their wording).
- `.claude/commands/scout.md` — "## 5. Revise", and every `approved` mention.
- `.agents/docs/orchestrated.md` — scout section and the knob table.
- Issue #461 item 2 — the proposed definition.

## Traps

- Fail closed: an unreadable comment list is a skip, never "the label is there".
- A Claude-footed comment never approves, whatever login posted it.
- Never edit `joharness.conf` (core path).
- clerk.md, scout.md, orchestrated.md are `shared:`: merge `origin/main` in before the pull request.
