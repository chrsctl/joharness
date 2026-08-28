---
workstream: queue-shared-scope
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: queue-shared-scope
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Finish — retire plan and workstream, PR, merge
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

- A suffix or bare-symbol spelling (`tests/foo.py~`, `+tests/foo.py`). The
  prefix reads as a word in frontmatter a human skims, and an older hook
  degrades safely with it — `shared:foo` matches no path, so it over-splits
  rather than claiming safety it cannot prove. A stripped symbol would make
  the same declaration read as an ordinary exclusive path.
- Asserting wave membership by naming both plans in sequence. Wave order
  follows queue order, so the first version of that assertion passed on one
  run and failed on the next. Now it extracts the wave line and checks each
  member separately — the flake was caught by running the suite three times
  rather than once, which is the rule this session merged an hour ago.

## Review

Opus tier = adversarial, separate lenses; both run 2026-08-28. They found the
SAME top three independently, and all three were the feature quietly claiming
a parallel safety it had not proven — the plan's hardest trap, failed three
ways in the first cut.

- r1: a plan whose scope was ENTIRELY shared paths counted as UNSCOPED, so a
  queue where every plan marks the same file skipped the wave block and
  printed "N free plans = N parallel sessions" — the unconditional promise
  the wave partition exists to replace, emitted for exactly the queue this
  marking describes, with no reconcile named. (fixed: shared paths count as
  scope; such a plan conflicts with nobody exclusively, so it joins wave 1
  and the wave names the reconcile. Covered both ways)
- r2: one plan's `shared:` SILENTLY VOIDED another plan's unmarked claim on
  the same path. The split test compared exclusive against exclusive only, so
  a marked path vanished from every comparison — including with an author who
  never consented to a reconcile. Measured: a named split became a silent
  merge, and at directory granularity `shared:beach` swallowed every unmarked
  path beneath it. This directly contradicted the sentence the same diff
  added. (fixed: a path stops splitting only when BOTH plans mark it;
  exclusive-versus-shared still splits and still names the path)
- r3: a shared-only plan was told "declare scope: in the plan file to join a
  wave" — advice whose only compliance is to delete the marking. (fixed by
  r1's fix)
- r4: (doctrine) the wave header and the always-printed trailer still read
  "declared scopes disjoint, parallel proven", unqualified, directly above a
  wave naming a reconcile — so for a literal reader the proof outranked the
  footnote and "reconcile expected" read as an aside about something already
  safe. Fixing r1-r3 without this would have left the doctrine claim false.
  (fixed: both lines now say parallel proven EXCEPT where a reconcile is
  named, and that it is a cost accepted rather than a collision ruled out)
- r5: (correctness) a pair sharing TWO paths named only the first, because
  the overlap helper returns on first hit — and which one surfaced depended
  on declaration order. (fixed: a variant that collects every overlap)
- r6: (correctness) `Shared:` with a capital letter matched neither the strip
  nor the extract, so it survived as an exclusive path matching nothing real
  — a capitalisation typo made a plan read MORE parallel-safe, the unsafe
  direction. (fixed: the prefix is matched case-blind)
- r7: (doctrine) the new consumer figures carried no command, date or repo —
  the rule this session merged an hour ago — and their only provenance was
  the plan file this PR deletes. (fixed: repo, commit and date inline, with
  "recount it there, not here", since a consumer reading `.agents/docs` could
  otherwise take "measured in a consumer" to mean itself)
- r8: (doctrine) `TEMPLATE.md` is the documented path for a plan author and
  never mentioned the marking, so the feature only existed for someone who
  read the protocol's parallel-work section in full. (fixed)
- r9: (doctrine) the protocol's own frontmatter blurb two screens above still
  described `scope` in terms the marking had made false. (fixed)
- r10: (doctrine) a wave carrying both notes printed two em-dash clauses that
  merged: the intra-wave reconcile read as qualifying the cross-wave overlap.
  (fixed: the reconcile is a semicolon clause naming "inside this wave")
- r11: (doctrine, caveman) "genuinely routine" — hedging on the drop list.
  (fixed)
- r12: two of my own assertions were order-dependent and would have flaked in
  the harness's own suite: the first named both wave members in sequence, the
  second named which counterpart a conflict cites. Wave order follows queue
  order, and adding two plans reshuffled it. (fixed: both assert the property
  against an extracted line; suite run twice, 513 passed both times)
- r13: (correctness, clean) `set -u` on the sparse wave array, dedupe against
  substring paths, glob injection in the dedupe pattern, bare `shared:`,
  padding after the colon, a path containing `shared:` mid-string, and
  byte-identical output against origin/main's hook on six no-marking
  fixtures — none broke.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:free_scopes` — where scope is parsed.
- `.agents/harness/queue-context.sh:scopes_overlap` — the test that splits.
- `.agents/harness/selftest.sh` `== queue-context.sh scope waves` — coverage
  to extend, not replace.
