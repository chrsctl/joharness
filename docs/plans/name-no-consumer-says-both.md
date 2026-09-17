---
plan: name-no-consumer-says-both
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/docs/consumer-repos.md
---

## Goal

Issue #273. `.agents/docs/consumer-repos.md`, `## Name no consumer`, answers
one question twice and differently, seven lines apart:

- `:207-209` — a consumer's pull request numbers ARE covered: *"The same goes
  for a consumer's plan names, item names and pull request numbers — all of
  them are that repo's internal work wearing a citation's clothes."*
- `:214-216` — they are NOT: *"Commit hashes and pull request numbers are not
  covered either — opaque to anyone without the repo, and they are what a
  counted number rests on."*

Nothing gates this rule — the same section says a matcher would have to
enumerate an operator's repositories, which is theirs to do and not a
session's. So the only enforcement is a session reading the page, and a page
that answers twice gives whichever answer was read last. Measured in one
session, 2026-09-17: the session cited the second paragraph to its reviewer
as settled and the reviewer cited the first back as settled, each quoting the
file correctly.

**One sentence survives. This plan says which, and the requester may say
otherwise — that veto is the whole of what is open here.**

## The direction, decided here so the implementer does not re-litigate it

**Pull request numbers ARE covered.** Three reasons, in order of weight:

1. **The asymmetry.** Treating a number as covered costs a citation some
   precision. Treating it as uncovered when it is covered puts a consumer's
   internal reference into `.agents/docs/`, which ships to every consumer —
   the exact thing the section's opening paragraph exists to prevent. Only
   one of those two errors is recoverable after it ships.
2. **The list it sits in.** `:207-209` puts pull request numbers beside plan
   names and item names, which nobody disputes are covered. A number plus a
   repository name anyone can guess is a live URL.
3. **The counting argument is already served without it.** `:214-216`'s
   rationale — *"they are what a counted number rests on"* — is true of
   **commit hashes**, and the exemption for those is not in dispute and
   stays. `.agents/docs/graph.md` requires a measured number to carry what
   produced it; a commit hash does that and is not a live link to anybody's
   work tracker.

So the edit is to `:214-216`, not to `:207-209`.

## Scope

- `.agents/docs/consumer-repos.md`, `## Name no consumer`, the paragraph at
  `:212-216` (the "Requester's rule" paragraph). Narrow its exemption to
  commit hashes alone, and say in the same sentence WHY the two differ — a
  hash is re-countable by whoever holds the repo and is inert to everyone
  else; a pull request number is a pointer into that repo's work tracker.
  One or two sentences. The paragraph already carries the canonical-repo
  carve-out and keeps it unchanged.
- The same file's earlier sentence at `:207-209` is the surviving spelling
  and is NOT edited. Verify by reading it that it needs no change to agree.

## Out of scope

- **Gating it.** The section explains at `:218-222` why there is no matcher,
  and that reasoning is untouched by this. A plan that adds one is a
  different plan and needs the operator's decision about enumerating their
  repositories.
- **Auditing the tree for existing violations.** Whether any shipped file
  currently carries a consumer's pull request number is a separate question
  with a separate cost; this plan fixes the rule, not its past application.
  If the implementer notices one in passing, file it, do not widen.
- **`.agents/docs/glossary.md`.** The glossary fixes contested TERMS and
  `ci` fails on the wrong spelling of one. This is a contested RULE about a
  class of reference, not a word with two spellings, so it gets no row —
  and adding one would make `ci` red on every legitimate use of the phrase.
- Any other file. `consumer-repos.md` is the only place the rule is stated.

## Acceptance

- The file contains exactly one answer about pull request numbers. The
  counted check, run on the branch:

      grep -n 'pull request number' .agents/docs/consumer-repos.md

  returns the covered sentence and the narrowed exemption, and no sentence
  saying pull request numbers are not covered. Read both hits; a count alone
  passes for the wrong edit.

- The commit-hash exemption survives, with its rationale attached to it
  rather than shared with a number that no longer has it:

      grep -n 'Commit hashes' .agents/docs/consumer-repos.md

- `./joharness.sh ci` → `ci: pass`.
- `./joharness.sh finish` green, and the edge review recorded with one
  finding tagged `(verifier)`.

## Where to look

- `.agents/docs/consumer-repos.md:Name no consumer` — the section, both
  paragraphs, and the un-gated reasoning below them.
- `.agents/docs/graph.md:Rules` — the counting requirement `:214-216` was
  serving, which the commit-hash exemption continues to serve.
- `.agents/docs/caveman.md` — house style for the replacement sentences.

## Traps

- **Do not delete `:207-209`'s clause to resolve it.** That is the cheap
  direction and it is the expensive error: it makes the shipped-reference
  reading correct. The edit is to the exemption.
- **A contested rule is not a glossary term.** See Out of scope.
- The file ships to every consumer, so the sentence is read by operators who
  have never seen this issue. It has to stand alone without it.
- `git grep` before claiming a sentence is the only one of its kind; this
  defect exists because two sentences said the same thing differently and
  nobody grepped.
