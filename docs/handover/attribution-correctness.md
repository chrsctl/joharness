---
workstream: attribution-correctness
status: done
branch: claude/licensing-matches-verify-qtamqe
pr: none
plan: attribution-correctness
issue: none
session: https://claude.ai/code/session_01BgxrYUJru5VR12hRuPxkdV
agent: sonnet
updated: 2026-09-04
next: Retire plan and workstream file in the last commit before the pull request opens, then open it
---

## Goal

Human asked two things after #206. "Can we Attribute correctly" — make the
distilled style guide carry the whole MIT notice, not half of it. "Okay
remove mention and just integrate The ideas" — take the named third-party
design record out of the tree and keep the reasoning where it is used.

## Decisions

- Full upstream notice inside `caveman.md`, at the end. MIT names both the
  copyright notice and the permission notice; a pointer to `.agents/LICENSE`
  does not survive copying the file alone, which is the exact case #206's
  review raised.
- `prior-art.md` deleted rather than paraphrased. Its stated purpose was to
  stop a session re-litigating settled rejections, and that purpose is
  served better by the argument sitting in the document that owns the
  decision than by a file a session has to know to open.
- Borrowed EVIDENCE dropped, not laundered. The file carried another
  project's measured operational failures as support for rules here. Those
  claims hold only because someone else counted them, so restating them
  without the source would make this repo assert numbers it never
  measured — against its own rule that a measured number carries what
  produced it. The rules they supported are already stated on their own
  grounds elsewhere, so nothing load-bearing is lost.
- Each argument went to the document that owns the decision: branch shape to
  `product/README.md`, no-datastore and the in-repo trade to `graph.md`,
  session interrogation to the handover alternatives table, liveness to
  `unsupervised.md`.
- `graph.md`'s one-line credit for the task-graph model kept. It is
  provenance for the document's framing, not a quotation, and the file is
  more honest with it than without.
- Migration note added for existing consumers. Removals do not travel
  (sync engine header), so a consumer synced before today keeps the deleted
  file and receives a NOTICE that no longer covers the quotations in it —
  the regression is in the consumer, not here, and only a doc line reaches
  it. Found by asking what the deletion does downstream, not by a gate.

## Rejected

- Paraphrasing the quotations and keeping the file. Offered to the human;
  they chose removal and integration, which also ends the maintenance of a
  second place where branch-flow reasoning lives.
- Keeping the borrowed health vocabulary for a future liveness monitor.
  Taking a taxonomy while removing the source is the one thing this change
  set out not to do.
- HTML comment for the upstream notice in `caveman.md`. A notice that does
  not render is not a notice.

## Review

Depth: sonnet — `/code-review` (high) on the full diff plus
`.claude/agents/verifier.md` at sonnet, 2026-09-04. The verifier reverted
`caveman.md` in a scratch clone and confirmed the new assertions red without
it, ran both sync tools against a scratch consumer bootstrapped from
`origin/main`, and checked every argument out of the deleted file against
its stated destination.

- r1: (verifier, code-review) the selftest's rationale comment still
  described the pointer design this diff replaced — "the permission text is
  LICENSE beside the file" — two lines above the assertions written to make
  that false. Recurrence of #206 r4, whose fix was the same comment.
  (fixed: the comment now states why both halves live in the file)
- r2: (code-review) migration section said "a consumer synced before
  2026-09-04", but the file only reached `main` on 2026-09-02 (`add174a`),
  so an earlier consumer gets `pathspec did not match` from the prescribed
  `git rm`. (fixed: the window is named with the command that dates it, and
  the sync's own `consumer-only` line is named as the reliable tell)
- r3: (code-review) plan Acceptance claimed every scoped path ships, while
  `.agents/harness/selftest/license-notice.sh` is canonical-only — chasing
  the mismatch risks un-exempting the selftest tree and shipping all 37
  topic files. (fixed: the acceptance names which paths ship and which
  cannot)
- r4: (code-review) the two new assertions grepped one opening phrase from
  each half, so a style pass compressing the notice body stays green.
  (fixed: the embedded block is dedented and compared byte for byte against
  `.agents/LICENSE` with upstream's holder line substituted)
- r5: (code-review) acceptance criterion "no hit outside `docs/`" was
  ambiguous — the intended hit lives under `.agents/docs/`. (fixed: the
  three expected files are named)
- r6: (code-review) README's "No per-file headers" now reads as contradicted
  by `caveman.md`'s in-file notice. The sentence is about this repo's own
  grant, so the fix is a distinction, not a correction. (fixed: the sentence
  scopes itself to this repo's grant and names the one upstream exception)
- r7: (verifier) clean on everything else, verified by running rather than
  reading: the embedded MIT text is byte-identical to this repo's copy with
  only the holder differing; the migration's premise reproduces end to end
  (a scratch consumer keeps the file, reported `consumer-only`, while its
  NOTICE arrives without the entry); every load-bearing argument reached its
  destination; the borrowed measured evidence was dropped everywhere rather
  than restated unsourced. The Convergent section went with no destination —
  each rule it named already stands on its own grounds elsewhere, so only
  the framing was lost. (no change needed)

## Blockers

None.

## Where to look

- `.agents/docs/caveman.md` — the closing notice section.
- `.agents/docs/product/README.md` — Branch flow, three integrated bullets.
