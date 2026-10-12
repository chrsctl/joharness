---
workstream: scout-proposes-on-issues
status: in-progress
branch: manage/scout-proposes-on-issues
pr: none
plan: scout-proposes-on-issues
issue: none
session: https://claude.ai/code/session_018EiRiqyGuL1SweutNXmvE9
agent: opus
updated: 2026-10-12
next: ci, verify, round-3 verifier on the revision protocol, then retire and open the pull request
---

## Goal

Rewrite the scout role so a pass proposes on GitHub issues (brief first,
outside reads under switch and budget, every claim cited, revisions and
answers on the same issue, ranked digest, cost on every issue) and opens no
pull request.

## Decisions

- orchestrated.md "What each role reads" scout row named `review`; `cmd_scout` lists `upstream`. Corrected (verifier confirmed).
- Out-of-scope docs that contradicted the rewrite were fixed in place, one line each: orchestrated.md AUTOMERGE conf row, `.claude/commands/orchestrate.md` "scout waiting on its proposal pull request", `.agents/docs/research/README.md` "scout's proposal ... a human authors by merging". Leaving them would ship contradictions; too small for a follow-up plan.
- "Yours" = carries the attribution footer, never the login: the scout may post as the reviewer. Comments drive §4/§5 only from write-access authors, unfooted, not `clerk:` (mirrors the clerk's author gate).
- Revision = `scout: revising` comment (full change), body edit, `scout: revised` comment. Research step after r2 reopened (review churn): the clerk dates revisions by comments only and cannot see body edits, a pass can die anywhere, and the reviewer can approve at any moment. Edit-first lets a dead pass leave a changed body approved; one comment before the edit lets an approval land on the old body (r17) or the promised edit never happen (r16). The bracket closes both: an approval before `revised` is stale, and the next pass finishes a `revising` with no `revised`.
- Every scout comment opens `scout: `; yours = that prefix + footer (comments) or the `cost:` line + footer (issues): the footer alone also marks other Claude sessions' text.
- Release-note / Models API read moved under §3's switch and budget: it is an outside read.
- PLANNED (a base plan's `issue:` names it) proposals are neither counted in the ceiling nor revised; the read limit is a plan's frontmatter and `## Goal`.
- verify: first run 2026-10-12 right after dockerd start = 4 passed, 2 failed (container networking, compose); re-run `./joharness.sh verify` same day = 6 passed, 0 failed. Diff touches no environment file.

## Rejected

- None.

## Review

- r1: (verifier) §5 revised on any newer comment, the reviewer's "looks good" or a clerk verdict included, staling approvals (fixed: counting comments that ask something only; nothing asked = no comment)
- r2: (verifier) body edit before the revision comment lets the clerk plan an unapproved body if the pass dies between (fixed: comment first)
- r3: (verifier) "yours" undefined under a shared reviewer login; a hand-filed `scout:` issue could be edited (fixed: yours = footed)
- r4: (verifier) `list_issues` returns pull requests; `scout:` plan/build pull requests counted and revised (fixed: skip pull requests)
- r5: (verifier) release-note read in §2 ran under `research  : off` (fixed: under §3's switch and budget)
- r6: (verifier) no author filter: strangers steer revisions and re-answers (fixed: counting comments only; no fetching a URL only because a comment names it)
- r7: (verifier) footer-last vs cost-last contradiction (fixed: cost is the last line before the footer)
- r8: (verifier) §8 fix on an answer edited a request the scout did not open (fixed: a correction comment)
- r9: (verifier) stale docs: orchestrated.md AUTOMERGE row, orchestrate.md scout line, research/README.md (fixed)
- r10: (verifier) ceiling double-counted planned proposals; WAITING ON REVIEW blamed review for a plan backlog (fixed: planned ones excluded, report names both counts)
- r11: (verifier) resume path skipped the `./joharness.sh scout` run steps 5-6 read (fixed)
- r12: (verifier) read limits contradicted: plan bodies vs `## Goal`, brief read last vs "first" (fixed)
- r13: (verifier) digest rank undefined without a number (fixed: those rank after, in filing order)
- r14: (verifier) review spawned on exits that posted nothing (fixed: only when something was posted)
- r15: (verifier) code commit carried no workstream update; branch behind origin/main (fixed: this commit, merge next)
- r16: (verifier, round 2) death between revision comment and body edit: old body planned under a fresh approval (fixed: `revising`/`revised` bracket; next pass finishes an open `revising`)
- r17: (verifier, round 2) approval landing between the revision comment and the edit approves the old body (fixed: `revised` posted after the edit stales it)
- r18: (verifier, round 2) footer alone claims other sessions' footed issues and comments (fixed: `scout: ` prefix / `cost:` line plus footer; residual limit named)
- r19: (verifier, round 2) ceiling reads a plan's `issue:` but the read limit allowed only `## Goal` (fixed: frontmatter and `## Goal`, scout.md and orchestrated.md)
- r20: (verifier, round 2) §5 revised planned proposals and they defeated the WAITING ON REVIEW exit (fixed: PLANNED never revised)
- r21: (verifier, round 2) "your last comment" undefined with none (fixed: the issue's creation)
- r22: (verifier, round 2) `pull request` grep hit on the list_issues line matched neither allowed reading (fixed: names the pull requests other roles open)

## Blockers

None.

## Where to look

- `.claude/commands/scout.md` — the role being rewritten.
