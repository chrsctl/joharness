---
plan: scout-approval-by-comment
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 461
scope: shared:.claude/commands/clerk.md, shared:.claude/commands/scout.md, shared:.agents/docs/orchestrated.md, shared:.agents/scripts/conf-keys.sh, shared:joharness.sh, shared:.agents/harness/selftest/scout.sh, shared:.agents/scripts/bootstrap-consumer.sh
---

## Goal

The clerk's scout gate approves a proposal only through the `approved`
LABEL EVENT, read from the issue timeline. In a cloud session the reader
is gated on `gh auth status`, which fails while `gh api` works (#459,
reproduced by the clerk 2026-10-13: `gh auth status` rc=1, `gh api
repos/chrsctl/joharness/issues/453/timeline --paginate` rc=0), and behind the
proxy `--paginate` past page one fails (403 on a numeric-ID path, measured
by the clerk's verifier 2026-10-13). "Any later comment stales the
approval", so a reviewer cannot ask and approve in one thread (#460 §1,
#461 item 2).

Decided by the owner in the clerk session, 2026-10-13 (issue #461 item 2,
answered "Comment approval"; recorded on #461): approval is a reviewer's
comment, read with `issue_read get_comments`, which every session has. The
label `approved` stays as a visible marker only. One of three plans for
#461 (with `scout-reviewer-trigger`, `scout-budget-by-count`); the pull
request body also says `Closes #459` and `Closes #456`.

## Scope

- `.claude/commands/clerk.md` THE SCOUT GATE — rewrite items 1–4 to one rule. A proposal is APPROVED when:
  (a) the newest comment on it authored by the `reviewer  :` login, carrying no Claude Code attribution footer, has `approved` as its first word (case-insensitive, trailing punctuation ignored); and
  (b) that comment is newer than the newest `scout:`-opening comment on the issue.
  Comments by others neither approve nor stale it. Read with `issue_read get_comments`, all pages. Comments unreadable = skip and report `APPROVAL UNREADABLE: <error>`; never fall back to the label. Remove the timeline reader, both fallbacks, the label-event rule and "any later comment makes the approval stale". Keep fail-closed, the author gate, `reviewer : none` = take no proposal, and CLOSED = declined.
- `.claude/commands/scout.md` §5 Revise — the bracket becomes: FIRST post ONE `scout: revised` comment (it is newer than any `approved`, so approval is needed again), THEN make the body edit. A pass that dies between the two leaves the proposal unapproved: fail-closed, which is what the old `scout: revising` bracket protected. Every place in scout.md that says the label is the gate now says the comment is.
- `joharness.sh:scout_report_lines` — the `reviewer  :` line says the reviewer's `approved` comment is the gate, not the label.
- `.agents/harness/selftest/scout.sh` — the assertion on that `reviewer  :` wording.
- `.agents/docs/orchestrated.md`, `.agents/scripts/conf-keys.sh`, `.agents/scripts/bootstrap-consumer.sh` — every "approved label gates" text says the comment.

## Out of scope

- The trigger, budget and digest: plans `scout-reviewer-trigger` and `scout-budget-by-count`.
- `joharness.conf` (core path).
- Any automatic `approved` labelling.

## Acceptance

- `grep -c -i 'timeline\|gh auth\|labeled' .claude/commands/clerk.md` — `0` (non-zero on main today).
- `grep -rn 'approved label' joharness.sh .claude/commands .agents/docs .agents/scripts .agents/harness/selftest` — no hits.
- `awk '/^THE SCOUT GATE/,/^Then the AUTHOR GATE/' .claude/commands/clerk.md | wc -l` — under 25 (45-ish on main today), recorded in the workstream file with the date.
- `grep -c 'scout: revising' .claude/commands/scout.md` — `0`.
- Walk the gate in the workstream file `## Review` on six cases. Expected results:
  - reviewer `approved` after `scout: revised` → taken;
  - `scout: revised` after `approved` → skipped;
  - a stranger's `approved` → skipped;
  - a footed `approved` by the reviewer's login → skipped;
  - another maintainer's comment after the reviewer's `approved` → still taken;
  - `Approved.` → taken.
- `bash .agents/harness/selftest.sh` (the runner only; topic files write fixtures at `/`) — the changed scout assertion PASSes; reverted, it FAILs.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Plan ships: consumer check = on `chrsctl/gx` after sync, the clerk pass takes gx #645 once its reviewer comments `approved` after the scout's last `scout:` comment.

## Where to look

- `.claude/commands/clerk.md` — line starting "THE SCOUT GATE," through "Then the AUTHOR GATE"; §2's footer rules (reuse their wording).
- `.claude/commands/scout.md` — "## 5. Revise", every `approved` mention.
- `joharness.sh:scout_report_lines` — the `reviewer  :` printf.
- `.agents/scripts/bootstrap-consumer.sh` — the `JOHARNESS_SCOUT_REVIEWER` comment line.
- Issue #461 item 2.

## Traps

- Fail closed: an unreadable comment list is a skip, never "the label is there"; the revised comment goes BEFORE the body edit.
- A Claude-footed comment never approves, whatever login posted it.
- Never edit `joharness.conf` (core path).
- Shared files with the other #461 plans: merge `origin/main` in before the pull request.
