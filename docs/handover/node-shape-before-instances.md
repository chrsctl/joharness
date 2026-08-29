---
workstream: node-shape-before-instances
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: node-shape-before-instances
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire the plan and workstream file, then open the PR.
---

## Goal

Instances of a node type can land before the type exists and nothing says
so. Four research files sat on `main` for days with no README, no TEMPLATE,
no listing and no lint. `lint_graph` checks EDGES between nodes; nothing
checked that a directory of nodes has a type at all.

## Decisions

- **The signal is self-naming, not frontmatter-in-general.** Every node
  file in this graph names itself in its first frontmatter key:
  `plan: <stem>`, `research: <stem>`, `requirement: <stem>`,
  `workstream: <stem>`. Verified across all 11 node files and 4 templates
  on `origin/main` f806d5b before writing any code. "Has frontmatter" would
  warn on any `docs/adr/` a consumer keeps, and a false warning trains
  sessions to ignore the channel the real findings ride on
  (`joharness.sh:lint_anchors` carries that lesson already).
- **A type is implemented when `.agents/docs/<type>/` exists.** Derived
  from the tree at read time, no registry to maintain — the trap the plan
  names. True of all four current types.

## Decisions (continued)

- **The check declines when `.agents/docs/` is absent entirely.** Found by
  running it: the selftest's scratch harness fixture carries `joharness.sh`
  and a stub suite and no harness docs, so every `docs/<type>/` in it read as
  undefined. That is not an early node type, it is a tree with no harness
  docs — a sync problem — and a check that cannot tell the two apart should
  say nothing rather than guess. `.agents/docs` is in the sync engine's
  `DIRS` (`.agents/scripts/sync-to-consumer.sh:174`), so every consumer
  carries it and the gate costs real repos nothing.

## Rejected

- **"Has frontmatter" as the node signal.** Simpler and wrong: any
  `docs/adr/` or `docs/notes/` a consumer keeps would warn, and
  `joharness.sh:lint_anchors` already carries the lesson that a false
  warning trains sessions to ignore the channel the real findings ride on. A
  case pins the difference.
- **A list of known types.** The trap the plan names: a registry is a second
  copy that goes stale against the thing it describes. Both signals are read
  from the tree.

## Review

Round 1, this session. Refutation: removing the `lint_unknown_types` call
from `lint_graph` — 813 passed / 5 failed against 818 / 0 with it. Three of
the eight new cases pass either way and are labelled in place (two refutes,
one half of a pair).

- r1: the fixture warning surfaced while running it: the selftest's scratch
  harness carries `joharness.sh` and a stub suite and no harness docs, so
  every `docs/<type>/` in it read as undefined. (fixed: the check declines
  without `.agents/docs/`, and the reasoning is that a tree missing the
  harness docs has a sync problem this lint cannot tell apart from an early
  node type)

Round 2, `.claude/agents/verifier.md` at opus, fed round 1's results. 12
findings, 9 verified against fixtures it built. Six were real defects in
code I had already called done.

- r2: **one filename with a space silently deleted a whole directory's
  warning.** The file list went to awk as an unquoted word-split string;
  mawk aborts on the first unopenable operand, so `END` never ran, the count
  came back empty, and the directory the check exists to report was skipped —
  with a raw awk error on `ci`'s stderr. gawk does not abort, so the answer
  differed by awk implementation too. (fixed: two builtin `read`s per file,
  no awk and no forks at all)
- r3: **a glob character in a filename over-counted.** `docs/g/` holding
  `s*.md` and `star.md` reported 3. Same word-splitting root cause; the same
  mechanism could pull `README.md` back past the `! -name` filter. (fixed by
  the same rewrite)
- r4: **`find` had no `-type f`**, so a DIRECTORY named `sub.md` was read as
  a file and took its whole directory's answer down the same fatal path.
  (fixed)
- r5: **CRLF node files were never counted.** `---\r` is not `---`, and the
  trim did not strip `\r`. A directory of nodes committed from a Windows
  checkout was invisible — and `.gitattributes` exists in this repo precisely
  because that checkout is real. (fixed: strip `\r` from both lines)
- r6: **the key named in the message was whichever file sorted last**,
  asserted over the whole count — false for the other file. The case could
  not catch it because its fixture used one key. (fixed: every distinct key
  named; a case with two)
- r7: **the counted claim was wrong in both directions.** "All 11 node files
  and 4 templates on f806d5b" — it is 12 at that ref (11 after #126 retired
  the satisfied requirement, which is the tree I actually counted), and no
  TEMPLATE self-names at all: they are excluded by the filename filter, not
  by the property. The rule holds for every real node file; the sentence
  citing it as evidence did not. (fixed, with the command and both refs)
- r8: **my own fixture emitted three false warnings in the suite's shallow
  clone and nothing asserted against them.** `mkdir -p` on
  `.agents/docs/plans` is invisible to git, so the `--depth 1` clone had a
  partial `.agents/docs` and warned for `docs/plans`, `docs/research` and
  `docs/handover`. The plan's own named trap — a false warning that trains
  sessions to ignore the channel — fired inside the diff written to avoid
  it. (fixed: the fixture carries all four types as a synced consumer does,
  and a new refute pins that an implemented type stays quiet)
- r9: the teardown used `rm -rf` on a TRACKED file, leaving an uncommitted
  deletion for later states to inherit — `fixture_rm` was added for this two
  hundred lines earlier, in the previous plan of this session. (fixed)
- r10: no case covered the `.agents/docs` decline branch; removing the guard
  left the suite green. (fixed)
- r11: a 192-character line in a file that wraps at ~76. (fixed)
- r12 (open, recorded not fixed): **a plausible consumer false positive the
  verifier could not confirm.** Docusaurus front matter conventionally
  carries `id:` equal to the file stem, which satisfies both halves of the
  signal, so a consumer keeping a Docusaurus tree under `docs/` would warn on
  every directory of it. Not fixed here: the fix would be a judgement about
  which keys are node-ish, which is the registry the plan forbids, and I have
  no such consumer to measure against. A repo that hits it should be the one
  that decides.
- r13: the workstream file said `next: Implement…` while the implementation
  was in the tree. (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:lint_graph` — the warn/red split this joins.
- `joharness.sh:lint_nodes` — the TEMPLATE/README/VISION filter reused.
