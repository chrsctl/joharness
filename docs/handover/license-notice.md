---
workstream: license-notice
status: done
branch: claude/licensing-matches-verify-qtamqe
pr: none
plan: license-notice
issue: none
session: https://claude.ai/code/session_01BgxrYUJru5VR12hRuPxkdV
agent: sonnet
updated: 2026-09-04
next: Retire plan and this file in the last commit before the pull request opens, then open it
---

## Goal

Human asked, verbatim: "Verify that alle pieces Matches licensing also when
distilled if not fix. And attribution." Check every distilled piece both
ways — text taken in from other projects, harness text handed out to
consumers — against the license each side requires, and fix what fails.

## Decisions

- Verified inbound (2026-09-04, upstream LICENSE files fetched from
  raw.githubusercontent.com): `.agents/docs/caveman.md` is a close
  derivative of `skills/caveman/SKILL.md` in JuliusBrussee/caveman — motto,
  pattern line, Not/Yes example and several rules verbatim. Upstream is MIT,
  Copyright (c) 2026 Julius Brussee; its LICENSE scope note puts only the
  engine directories under BSL, the skill is MIT. The file named the upstream
  and the word MIT and carried no copyright line: that fails MIT's one
  condition. Gas Town quotations in `prior-art.md` are short and attributed
  (MIT, Copyright (c) 2025 Steve Yegge). `graph.md` adapts ideas from
  codejunkie99/graph-engineering (MIT, Copyright (c) 2026 codejunkie99,
  default branch `master`), no text reproduced. Vale, Fowler, arXiv: short
  quotations with links, no license condition attaches.
- Verified outbound: `sync-to-consumer.sh` `FILES`/`DIRS` ship no license
  text at all. Fails the same condition for every consumer.
- Shipped notice lives at `.agents/LICENSE` + `.agents/NOTICE`, not root:
  root `LICENSE` in a consumer is that repo's own, and the previous plan
  rejected shipping there for exactly that reason. `.agents/` is the one
  path every consumer receives whole, and `.gitattributes` already pins it.
- Two files, not one: `LICENSE` stays byte-identical to root so a selftest
  can `cmp` them and drift is impossible; NOTICE holds prose (scope,
  third-party) that must not be pasted into MIT text.
- Third-party notices point at `LICENSE` beside them for the permission
  text rather than repeating the MIT body three times.

## Rejected

- Root `LICENSE` in `FILES`. Overwrites a consumer's license every sync.
- `.agents/harness/LICENSE`. Ships with no engine change, but names one
  subtree while the grant covers `joharness.sh`, `.claude/` and
  `.agents/docs/` too.
- Deleting a whole clone's root `LICENSE` in bootstrap. Consumer may keep
  MIT deliberately; a warning matches the README precedent.

## Review

Depth: sonnet — `/code-review` (high) on the full diff, 2026-09-04, plus
`.claude/agents/verifier.md` at sonnet, which re-ran ci, selftest, verify,
both sync tools against scratch dirs, revert-and-run on every new case in a
scratch clone, and fetched all three upstream LICENSE files.

- r1: (code-review) NOTICE said the grant covers "everything under
  `.agents/`" in a consumer, which claims a consumer's own environment layer
  written there. (fixed: the grant covers what came from canonical, decided
  by the tools that place it; a consumer's own file under those paths is its
  own)
- r2: (verifier) the same sentence contradicted its own "exactly the files
  the sync ships": `.agents/scripts`, the selftest and every unselected
  layer never ship — verified with a live `--dry-run`, 38 new paths, none
  there. (fixed: same rewrite as r1 — the manifest is the list, the NOTICE
  describes it and names the canonical-only exclusions)
- r3: (code-review) `bootstrap-consumer.sh` seeds joharness's `ci.yml`,
  `update.yml`, README and Part 2 stubs, which the exhaustive list omitted
  and then disclaimed. (fixed: named as carried under the same grant, the
  consumer's to edit from then on)
- r4: (code-review) `caveman.md` justified its in-file line with "gets
  copied on its own" while the permission text does not travel with it.
  (fixed: header says copy it with `.agents/LICENSE`, and that the
  copyright line is the half of the condition that stays in the file;
  selftest comment aligned)
- r5: (verifier) motto attributed to `skills/caveman/SKILL.md`; it is not
  in that file, it is upstream's `README.md` line 6 — verified by fetch.
  (fixed: both files cited in NOTICE and in the header)
- r6: (code-review) whole-clone warning fired on mere presence of a root
  `LICENSE`, so a human who replaced it before bootstrapping got a false
  warning. (fixed: `cmp` against the shipped `.agents/LICENSE`, which is
  byte-identical to joharness's root file; identical or no shipped copy =
  warn, different = named as the repo's own. Fixture aligned, replaced
  case asserted both ways)
- r7: (code-review) NOTICE named one layer's tools (kubectl, helm, k3d) —
  a layer-specific fact in a harness-level file no gate watches. (fixed:
  general sentence only)
- r8: (code-review) "LICENSE line 11" written in the selftest comment and
  the plan; the clause is line 12. (fixed: the clause is quoted, no line
  number anywhere)
- r9: (code-review) `prior-art.md` said the quotations' paths are listed
  in NOTICE; NOTICE pointed back. (fixed: paths are beside each quotation,
  NOTICE names repository and holder)
- Verifier's clean checks, recorded as its result: `LICENSE` copies
  byte-identical, all three holder/year/license claims match upstream,
  the eol-pin walk covers both new files, all six new selftest cases red
  without their code (revert-and-run in a scratch clone), fresh and
  whole-clone bootstrap behave as asserted. (no change needed)

## Blockers

None.

## Where to look

- `.agents/NOTICE` — what the grant covers, and every upstream named.
- `.agents/scripts/sync-to-consumer.sh:FILES` — the two new entries.
