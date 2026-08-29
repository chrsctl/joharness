---
workstream: glossary-enforcement
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: glossary-enforcement
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire the research file and this file, open the PR, merge it.
---

## Goal

Close `docs/research/glossary-enforcement.md`: is there established practice
for mechanically enforcing a controlled vocabulary in documentation, or was
`harness-glossary` inventing one? Answer graduates to
`.agents/docs/caveman.md`; the research file is deleted by the same pull
request.

## Decisions

- **The findings are already recorded and already verified from a second
  context.** The work left is the graduation, not the research. What this
  branch adds is a re-run with the queries kept — the protocol names this
  file as its one instance whose method "cannot be re-run as written", and a
  graduation resting on unreproducible findings inherits that.
- **The file's `## Consequence for the queue` is stale and must not be
  graduated as written.** It says the question is now "adopt or build" for
  `docs/plans/harness-glossary.md`. That plan is gone and the thing is
  BUILT: `.agents/docs/glossary.md` and `lint_glossary` are on `main`, and
  `ci` runs a `== glossary` stage. So the graduation records what was
  decided and why, not a choice still to make.

- **The graduation could not quote its own evidence, and that is the finding
  demonstrating itself.** Writing the measured drift into
  `.agents/docs/caveman.md` failed `ci`'s own `== glossary` stage, because the
  paragraph spelled the banned form. The recount one-liner now reads the ban
  out of `.agents/docs/glossary.md` instead of hard-coding it — no second copy
  of the thing, which is the glossary's own rule about rows.
- **Scope of the lint, checked rather than assumed.** `GLOSSARY_PATHS` covers
  `.agents/docs/*`, `.agents/harness/*`, `.agents/scripts/*`,
  `.agents/env/README.md`, `.claude/commands/*`, `.claude/skills/*`,
  `AGENTS.md`, `CLAUDE.md`, `joharness.sh`. Not `docs/`. So the research file
  quoting the banned form is legitimately out of scope and the graduation
  target is legitimately in it — which is why one passes and the other had to
  be rewritten.

## Rejected

- **Re-deriving the findings instead of re-running the sources.** The third
  pass fetched `docs.vale.sh` and `martinfowler.com` and kept the queries; a
  pass that reasoned to the same conclusions from memory would have produced
  a Method section as unreproducible as the one it replaced.
- **Graduating the file's own `## Consequence for the queue` as written.** It
  named a decision still to be made ("adopt or build") for a plan that had
  already shipped. Graduating it would have handed the next session a live
  question that is closed, which is the exact failure the protocol's
  Graduating section says the why-explanation exists to prevent.

## Review

Round 1, opus, `.claude/agents/verifier.md` (verifier) — 7 findings plus an
adjacent note. Every citation came back GROUNDED; every number came back
wrong. Recorded before the fixes and in the same commit.

- r301: (verifier) **The graduation carried a prescription a later ruling had
  already overturned.** The research file (2026-08-25) says a term differing
  between layers "needs the zone named, not a winner picked".
  `.agents/docs/glossary.md` "One meaning, or nothing" (`dbcb35d`,
  2026-08-28) settled it the other way and gave the mechanical reason: bans
  are substrings, so a zoned canonical contains the bare ban and could never
  be written — such a term gets NO row. I caught the file's stale
  `## Consequence for the queue` and then graduated its stale prescription,
  which is the same failure one paragraph further down. (fixed — the
  graduation states the settled ruling and its reason, and keeps Bounded
  Context as the name for the underlying thing rather than as a
  prescription)
- r302: (verifier) **`107` reproduces at no commit in this repo's history.**
  Swept all 651 commits on `origin/main`: the maximum the canonical spelling
  ever reaches across markdown is 104, and at the filing tree it is 39. The
  `10` and the `five files` do reproduce, at `2fa0ba5`. I inherited the pair
  from the research file and re-counted only one half of it. (fixed —
  re-measured in the scope the lint governs, with the lint's own flags: 9
  occurrences across 4 files at `2fa0ba5`, 0 now outside the glossary's own
  row)
- r303: (verifier) `77 / 2` is `origin/main`, not this branch — this branch
  gives 78 / 3 — and "both survivors are required" is falsified by this pull
  request's own retire commit, which deletes one of the two. In a consumer,
  which never had `docs/research/`, the sentence is false on arrival. (fixed
  — the claim is gone; the graduated page carries no count, and the record
  carries the count that reproduces)
- r304: (verifier) The recount recipe produced neither number it was offered
  to recount: the `git grep` half counts only the banned form, and
  `./joharness.sh ci` prints no occurrences when green. (fixed — the recipe
  is out of `caveman.md` entirely; the measurement belongs in this record,
  and the style guide carries the rule and the why)
- r305: (verifier) The one-liner searched a comma-separated `Not this` cell
  as one literal, so a multi-ban row would read clean while `ci` went red.
  (fixed by r304 — removed rather than repaired)
- r306: (verifier) `.agents/docs/research/README.md` says this file "carries
  `## Method: Not recorded`", which this branch makes false and the retire
  commit makes dangling — in a doc that syncs whole. (fixed — the section now
  states the rule with the instance closed, and says what the re-run caught)
- r307: (verifier) The recount counted the glossary's own definition row,
  which `lint_glossary` exempts by path, so the page's numbers were measured
  in a different scope from the gate they were evidence for. (fixed by the
  re-measurement, which excludes that row exactly as the lint does)
- Adjacent, not this diff: `docs/research/orchestration-shape.md` still reads
  "Adopt-or-build, the same question `harness-glossary` now faces" — the same
  stale reference to a retired plan. Left alone; it is that file's to fix
  when it closes, and flagged here so its session finds it.

## Scope notes

- One file outside the graduation target: `.agents/docs/research/README.md`.
  Its "one instance that does not meet this shape" section names this file
  and describes it wrongly the moment this branch lands, and names a deleted
  file the moment the retire commit does. Leaving it would ship a false
  statement to every consumer. Decided alone, small, flagged here.

## Blockers

None.

## Where to look

- `docs/research/glossary-enforcement.md` — the question, findings and the
  verification pass this closes.
- `.agents/docs/research/README.md`, Graduating — the answer carries the
  why-explanation, not only a rule line, or the question comes back.
- `.agents/docs/glossary.md` and `joharness.sh:lint_glossary` — what was
  actually built.
