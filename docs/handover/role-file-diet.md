---
workstream: role-file-diet
status: in-progress
branch: claude/role-file-diet
pr: none
plan: role-file-diet
issue: none
session: https://claude.ai/code/session_014pf1ZLsyT6Q6B8M2STqS9P
agent: opus
updated: 2026-10-23
next: Run ci and verify on the review fixes, then retire and open the pull request
---

## Goal

Cut what every orchestrator pass loads (`.claude/commands/orchestrate.md`,
41.5 KB) to 22 KB or less by moving rare branches verbatim to
`.agents/docs/orchestrate-reference.md`, behaviour unchanged.

## Decisions

- Moves are exact substrings of the old file, each replaced by one pointer
  line; a pointer swapped back for its text rebuilds the old file byte for
  byte (checked by the split script at build time). Reflow happens only at
  a cut, so no rule's words change.
- Pointer convention, once, at the top: `ref § <name>` = `## <name>` of
  `git show origin/main:.agents/docs/orchestrate-reference.md`. Read from
  fresh `origin/main` (fetched every Pass entry), so a reference change
  reaches a running orchestrator without touching the `harness=` hash rule
  (out of scope).
- `## 0. Start` moves whole: it runs once per session, never per pass. Its
  heading stays in `orchestrate.md` so `"## 0. Start" step N` citations in
  keeper.md and orchestrated.md still land.
- Pointer lines keep the moved names (GUARD, RETIRE, "A scout issue needs
  the scout") so citations in scout.md and orchestrated.md, out of scope,
  still find them.
- The six unclaimed-spawn rows (BLOCKED BEFORE CLAIM, STILLBORN, ...) move
  as one block behind one row in the same table position, conditions a
  superset of theirs, "none matches = next row": first-match order is
  unchanged.
- RUN END, the RETIRE arm rule, the health table's match columns, spawn,
  schedule, report and Never stay: every normal pass runs them.

- Moved section → pointer that reaches it (`orchestrate.md`): Optional
  tools → Tools ("Any other tool or `status_bucket` absent"); 0. Start →
  §0 ("First: ref § 0. Start"); Duplicate → Pass entry bullet; Held by
  human → health row and §3 `held-human=` clause; Unratified block →
  health row; Relay → `blocked` row; Unclaimed spawn rows → pointer row
  in their old table position; KILL and LOOP, Respawn limit, GUARD →
  lines after the table; Role sessions → §3 bullet; RETIRE → §4 RETIRE
  arm; Retired session woken, Out-of-band arm, Human stop → §4; Fresh
  session line → Report opening lines; Core wait → Report (wait line or a
  `corewait=` stem). The selftest checks both directions by name.

## Rejected

- Moving RUN END: an idle fleet ends every hourly run there, so it is the
  normal path, not a rare one.
- Several small moves (served-model line, environment note, source_url
  rationale): each pointer and heading costs about what it saves, and the
  total must stay within 5% of 41,573 bytes.

## Review

- r1: Optional tools section got the health table's header prepended (fixed)
- r2: (verifier) pointer-name check over-captured into the next sentence, 9 FAILs (fixed: longest section-name prefix match)
- r3: (verifier) unclaimed-spawn pointer row said not RUNNING; RUNNING with a BLOCKED bucket never reached the moved held= rows (fixed: any)
- r4: (verifier) corewait= drop rule read only while the wait line prints (fixed: pointer also fires on a corewait= stem)
- r5: (verifier) held-human= drop rule read only while its row matches (fixed: §3 clause points to it)
- r6: (verifier) status_bucket is a field, not a tool, so its degradation row was unreachable (fixed: pointer names it)
- r7: (verifier) moved role text says the standard lines are below, they are in orchestrate.md (fixed: reference intro says its terms hold there)
- r8: (verifier) section check was a substring test and checked no content (fixed: exact name, non-empty body; mutations tested)
- r9: (verifier) scout trigger is read on scout-on passes yet moved (wontfix: its pointer fires on that same scout row; keeping it breaks the 22 KB cut)
- r10: (verifier) harness= hashes only orchestrate.md (wontfix: pointers read origin/main fresh; the Pass entry rule is out of scope)
- r11: (verifier) citations in keeper.md, scout.md, orchestrated.md land one hop away on a pointer (no change)

## Blockers

None.

## Where to look

- `docs/plans/role-file-diet.md` — the item.
