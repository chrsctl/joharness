---
workstream: backpass-remove
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: none
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: Remove the five touchpoints, keeping the pure-pointer rule its dead reason justified
---

## Goal

Human ask: backpass was adopted here 2026-08-28 and is not useful — remove
it if so. Verified not useful, four independent reasons below. Five
touchpoints, two of which cite backpass as the REASON for a rule that should
outlive it.

## Decisions

- FOUR OF THE FOUR reasons I first wrote were wrong or overstated, and the
  verifier caught every one. They are corrected below and the originals are
  named, because the first cut is in commit `b3f16eb`'s message, which
  outlives this file. Read this section over that one.
  1. It resolves no `@` imports, so it audits root `AGENTS.md` and
     `CLAUDE.md` only — the two `memoryFiles` its own `.backpassrc.json`
     named. MOST of what this repo enforces lives in
     `.agents/harness/AGENTS.md`, invisible to it. Not "every rule", which
     is what I wrote: root `AGENTS.md` Part 2 carries enforced rules too —
     the single layer carve-out (`selftest.sh:LAYER_CARVE_OUT_FILE`), run
     `ci` before a pull request, trust counted numbers. A real blind spot,
     a partial one.
  2. Its evidence rule is "at least two independent sessions", and this
     container cannot supply two. I wrote that the transcript store "never
     exists" here; it does. Counted 2026-08-28,
     `find ~/.claude/projects -name '*.jsonl' | wc -l` → 32, `du -sh
     ~/.claude/projects` → 17M. What is missing is not the store but the
     CORPUS: the container is ephemeral and holds this session only, so the
     corroboration rule can never be met, and a tool whose gate can never
     pass is a tool that proposes nothing.
  3. Its principles are already here under other names — the four-stage
     loop (`.agents/docs/feedback.md`, `## The four stages`) and rejection
     memory (`## Rejected` plus `## Graduation` in the handover protocol).
     NOT "the always-loaded token budget in AGENTS.md's own header": `grep
     -rni 'token\|budget' AGENTS.md .agents/harness/AGENTS.md CLAUDE.md` →
     0 hits. That header argues for brevity and cites a study; it sets no
     budget. I labelled the bullet "verified against the tree" and that
     sub-claim was the one thing in it I had not checked.
  4. The human's constraint: no reliance on non-shell workflows. THE
     HUMAN'S line, not the repo's — I attributed it to the repo, and
     `grep -rni 'non-shell\|shell-only'` finds it nowhere. The nearest repo
     text is `joharness.sh:959` refusing Vale as "a Go binary in a `ci`
     whose whole toolchain is shell and shellcheck", which is scoped to
     `ci`'s toolchain, not a repo-wide prohibition. backpass is a Node CLI
     that writes to `AGENTS.md`, so it falls under the human's line
     squarely; the repo's line is adjacent, not identical.
- The `CLAUDE.md` rule KEPT is the weaker, true one: instruction text goes
  in `AGENTS.md`. Its reason survives — a harness reading `AGENTS.md`
  natively never sees this file's body, so text here reaches one reader and
  misses the other. What does NOT survive is PURITY, the stronger rule that
  the file contain nothing but the pointer: backpass enforced that by
  warning every run, and nothing replaces it. The comment now says
  "convention, not a gate" rather than implying an enforcement that left
  with the tool.
- No plan file, and the carve-out does NOT cover this. `.agents/docs/plans/
  README.md` grants it to copy and sync tasks — "make X match Y" — and a
  removal at a human ask is neither. Recorded as a departure rather than
  dressed up as an exemption: the ask was specific and the diff is five
  touchpoints. The rule is right and I went around it.
- Removals do not travel to consumers
  (`.agents/scripts/sync-to-consumer.sh`, header). A consumer synced
  between the adoption commit and this one keeps `.agents/docs/backpass.md`
  describing a tool canonical no longer carries, and will see it reported
  as consumer-only. Named here because the diff cannot fix it and a silent
  version of this is how consumers accrete dead docs.

## Rejected` plus graduation, the always-loaded
     token budget in `.agents/harness/AGENTS.md`'s own header. Verified
     2026-08-28 against the tree.
  4. Human constraint, and the repo's own line: no reliance on non-shell
     workflows. backpass is a Node CLI that WRITES to `AGENTS.md`. The
     glossary lint comment already refused Vale on exactly this ground —
     "a Go binary in a `ci` whose whole toolchain is shell and shellcheck".
- The pure-pointer rule for `CLAUDE.md` STAYS. backpass was its stated
  reason and is not its only one: harnesses that read `AGENTS.md` natively
  resolve no imports, and Claude Code loads `CLAUDE.md` rather than
  `AGENTS.md`. Both already sit in the same sentence of the handover
  protocol. A rule losing its justification is not a rule losing its point.

## Rejected

- Keeping `.agents/docs/backpass.md` as a record of why the tool was tried.
  The reasons it failed are worth keeping and the tool's shape is not; they
  are in this file and in the pull request body, both reachable from
  history, and a doc describing a tool nobody runs is the stale instruction
  this repo deletes on sight.
- Dropping the pure-pointer rule with its reason. The reason changed; the
  rule did not. Two other justifications for it already sat in the same
  sentence of the handover protocol.

## Review

Sonnet tier. `.claude/agents/verifier.md` on the full diff — the rule merged
in PR #110, applied on the very next branch. Ten findings, and the four that
matter are one defect repeated: I labelled claims "verified against the
tree" and had not run them.

- v1 Reason 2 was FALSE and trivially checkable. I wrote that local
  transcript stores "never exist in the ephemeral remote containers sessions
  run in". They do: `find ~/.claude/projects -name '*.jsonl' | wc -l` -> 32,
  `du -sh ~/.claude/projects` -> 17M, run here 2026-08-28. The true
  statement is narrower — the container holds ONE session, so backpass's
  two-independent-sessions gate can never pass. It is also in `b3f16eb`'s
  commit message, which outlives this file. (fixed in Decisions; the commit
  message stands as the record of the error)
- v2 Reason 3 cited "the always-loaded token budget in AGENTS.md's own
  header". `grep -rni 'token|budget'` over the three files -> 0 hits. That
  header argues for brevity and cites a study; it sets no budget. The bullet
  carried a "verified" label and that sub-claim was the part I had not run.
  (fixed)
- v3 Reason 1's "every rule this repo enforces lives in
  `.agents/harness/AGENTS.md`" is false — root `AGENTS.md` Part 2 carries
  enforced rules, including the layer carve-out the selftest checks.
  (fixed: "most", counterexamples named)
- v4 Reason 4 attributed "no reliance on non-shell workflows" to the repo.
  It is the human's line; `grep -rni 'non-shell|shell-only'` finds it
  nowhere in the tree. (fixed)
- v5 The surviving justification does not justify the surviving RULE. What
  I kept reads as PURITY — nothing but the pointer — and the two surviving
  reasons justify only that instruction text belongs in `AGENTS.md`.
  backpass was purity's sole enforcer, warning every run, and nothing
  replaces it. (fixed: the weaker true rule, and the comment now says
  "convention, not a gate")
- v6 My replacement comment contradicted itself — "a second copy that
  reaches one reader and not the other". Content only here is not a copy;
  content that is a copy reaches both. (fixed)
- v7 The no-plan carve-out covers copy and sync tasks, not a removal at a
  human ask. (fixed by recording the departure — see Decisions)
- v8 "the same way a retired workstream file is recovered" is a false
  generalization: that needs `--all --full-history`. (fixed)
- v9 The sonnet-depth `/code-review` pass is owed, and this verifier pass is
  not it. (open — recorded rather than claimed as done)
- v10 Removals do not travel to consumers, so a consumer synced today keeps
  the deleted doc. (recorded in Decisions; this diff cannot fix it)

Caught by me while writing, before the verifier ran:

- r1 The comment I wrote into `CLAUDE.md` cited a section
  "Reaching a fresh session" that does not exist — the heading is "How a
  session finds this without being told". Invented while replacing a
  citation, which is the same class as the five unreproducible numbers this
  session already produced. (fixed: the real heading, read out of the file)
- r2 `ci`'s graph lint flagged this workstream file's own anchor pointing at
  the deleted `.agents/docs/backpass.md` — the gate catching the diff that
  broke it, one run after the deletion. (fixed: the anchor names where to
  read it in history instead)

## Blockers

None.

## Where to look

- The two deleted files: `git log --diff-filter=D --oneline -- <path>`
  finds the removal commit, then `git show <it>^:<path>`. NOT "the same way
  a retired workstream file is recovered" — that needs `--all
  --full-history` (`.agents/docs/handover/README.md`), because a workstream
  file's whole life is on a side branch. These two lived on `main`, so the
  short form reaches them.
- `.gitignore` — the `.backpass/` block.
- `CLAUDE.md`, `.agents/docs/handover/README.md` — the two that cite it as a
  reason and must keep the rule.
