---
workstream: queue-shared-scope
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: queue-shared-scope
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Add shared: marking, stop it splitting waves, name the reconcile, cover both
---

## Goal

Plan `docs/plans/queue-shared-scope.md`: the wave partition proves parallel
safety by disjoint `scope`, but in a real consumer queue every plan naming
code names the same two or three files, so no two plans are ever disjoint and
every wave holds one plan. The advice then inverts what the repo actually
did — four concurrent sessions against exactly those files, 2 of 24 pull
requests needing a reconcile, an 8% cost rather than an impossibility.

## Decisions

- Spelling (the plan leaves it to this session): a `shared:` prefix on the
  path inside `scope`. Readable in the frontmatter, greppable, and it degrades
  safely — an older hook that does not know the prefix treats
  `shared:foo.sh` as a path that matches nothing, so it over-splits waves
  rather than claiming a safety it cannot prove.
- A shared path is excluded from the overlap test that SPLITS waves, and
  collected separately so the wave line can name the expected reconcile.
  Never silently dropped: a wave claiming parallel safety it does not have is
  worse than one claiming none (the plan's trap).
- Output stays one line per wave. The hook runs before every session's first
  prompt.

## Rejected

(pending)

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:free_scopes` — where scope is parsed.
- `.agents/harness/queue-context.sh:scopes_overlap` — the test that splits.
- `.agents/harness/selftest.sh` `== queue-context.sh scope waves` — coverage
  to extend, not replace.
