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

- Not a plan file. Removing an adopted tool at the human's ask, diff
  self-describing except for the two rules whose justification changes — and
  those go in the commit message and the pull request body, which persist
  where a workstream file does not.
- Why it goes, all four checked rather than recalled:
  1. It resolves no `@` imports, so it audits root `AGENTS.md` only. Every
     rule this repo enforces lives in `.agents/harness/AGENTS.md`. The tool
     cannot see them — recorded in `.agents/docs/backpass.md` itself.
  2. Its evidence source is local transcript stores. Sessions here run in
     ephemeral remote containers where those never exist; the same file says
     the corpus in a web session is empty.
  3. Its principles are already here under other names — the detect /
     record / generalize / prevent loop in `.agents/docs/feedback.md`,
     rejection memory in `## Rejected` plus graduation, the always-loaded
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

- The two deleted files: read them at the commit before this branch's
  removal commit. `git log --diff-filter=D --oneline -- <path>` finds it,
  the same way a retired workstream file is recovered.
- `.gitignore` — the `.backpass/` block.
- `CLAUDE.md`, `.agents/docs/handover/README.md` — the two that cite it as a
  reason and must keep the rule.
