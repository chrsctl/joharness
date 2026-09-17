---
plan: name-no-consumer-says-both
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/docs/consumer-repos.md
---

## Goal

Issue #273. `.agents/docs/consumer-repos.md`, `## Name no consumer`, answers
one question twice and differently, in two consecutive paragraphs:

- the paragraph beginning *"Cite the measurement, never the repository"* ends
  *"The same goes for a consumer's plan names, item names and pull request
  numbers"* — **covered**;
- the paragraph beginning *"Requester's rule, 2026-09-16"* ends *"Commit
  hashes and pull request numbers are not covered either"* — **not covered**.

Nothing gates this rule; the section says why, and that reasoning stands. So
the only enforcement is a session reading the page, and a page that answers
twice gives whichever answer was read last. One session did exactly that on
2026-09-17: it cited the second paragraph to its reviewer as settled and the
reviewer cited the first back as settled, each quoting the file correctly.
Both artifacts are in this repo's history — issue #273's body, and the review
recorded on the branch that filed it.

**One sentence survives. This plan says which, and the requester may say
otherwise — flagging that is an acceptance item below, not a courtesy.**

## The direction, and what decided it

**Pull request numbers are NOT covered. The edit removes them from the
covered list, and the exemption paragraph stands.**

The rule the file is reaching for is **descriptive versus opaque**:

- A repository name, a plan name, an item name each say what somebody is
  BUILDING. That is the internal work the section exists to keep out of
  every other operator's copy.
- A commit hash and a pull request number say nothing at all to a reader
  without the repo. They are pointers, and the thing that would make them
  resolvable — the repository name — is banned outright and separately, in
  this same section's first paragraph: *"Do not write it."* That ban is not
  in dispute and this plan does not touch it.

Three checks, each re-runnable:

1. **The tree already practices the exemption, in the directory the rule
   ships from.** `git grep -nE "PR ?#[0-9]+" -- .agents/docs` returns three
   shipping lines whose provenance rests on a consumer's pull request
   number, the repository withheld in each: `agent-selection.md:6`
   ("Developed in a consumer (its PR #3)"), and `feedback.md` twice. Reading
   pull request numbers as covered makes those three non-compliant the
   moment it lands, in files nobody is editing.
2. **The counting requirement needs them.** `.agents/harness/AGENTS.md`,
   step 5: *"Measured number carries what produced it, same sentence — the
   command, and when. Number nobody can re-count is a written number."* For
   a claim about merges, a pull request number is often the only thing that
   makes it re-countable by whoever holds the repo — which is exactly the
   exemption's own stated rationale.
3. **The leak the other reading fears needs a second violation.** A number
   becomes a live link only beside a repository name, and writing one is
   already forbidden. A rule whose justification is that another rule might
   be broken is not the one to tighten.

**What was rejected, and why it is written down rather than dropped.** The
first draft of this plan decided the opposite — covered — on an asymmetry
argument (shipping an internal reference is unrecoverable, losing citation
precision is not). Its heaviest supporting reason was false against the tree
(check 1 refutes it), and it never engaged the exemption's first rationale,
"opaque to anyone without the repo", which is the one that bears. The
asymmetry is real and it is answered by check 3, not by ignoring it.

## Scope

- `.agents/docs/consumer-repos.md`, `## Name no consumer`. In the paragraph
  beginning *"Cite the measurement, never the repository"*, remove pull
  request numbers from the covered list, leaving plan names and item names.
- In the same edit, say WHY the list splits where it does — descriptive
  versus opaque, in the section's own voice, one or two sentences. Without
  it the next reader sees an arbitrary list and the contradiction grows back;
  the file's own history is the argument for saying it.
- The paragraph beginning *"Requester's rule, 2026-09-16"* is the surviving
  spelling and is NOT edited. Read it to confirm it needs no change to agree.

## Out of scope

- **Gating it.** The section explains why there is no matcher — a list of
  names would have to enumerate an operator's repositories, which is theirs
  to decide. Untouched by this. A plan that adds one needs that decision
  first.
- **The three existing usages.** Under this direction they are compliant, so
  there is nothing to clean up. Had the direction gone the other way they
  would each have become a violation in the same commit, which is check 1 and
  is why they are named here rather than left to be discovered.
- **`.agents/docs/glossary.md`.** The glossary fixes contested TERMS and `ci`
  fails on the wrong spelling of one. This is a contested RULE about a class
  of reference, not a word with two spellings — a row would red every
  legitimate use of the phrase.
- Any other file. Grepped: the rule is stated in `consumer-repos.md` and
  nowhere else, and no selftest asserts the section's text.

## Acceptance

All four, and the flag is one of them.

- **One answer survives, and it is the right one.**

      grep -n 'pull request number' .agents/docs/consumer-repos.md

  Expected: exactly ONE hit, in the "Requester's rule" paragraph, reading
  that they are not covered. Zero hits means the wrong sentence was cut;
  two means nothing was.

- **The reason the list splits is on the page**, not only in this plan:

      grep -niE 'opaque|resolves to nothing|say what' .agents/docs/consumer-repos.md

  Expected: at least one hit inside `## Name no consumer` that a reader can
  use to place a NEW kind of identifier without asking. A reviewer reads it;
  the grep only proves it is there.

- **A consumer can act on it.** This file ships, so state the check a
  consumer runs after its next sync: read `## Name no consumer` and confirm
  it gives one answer for pull request numbers. No consumer-side command
  exists, because the rule is un-gated by design — say that in the pull
  request rather than implying a check that does not exist.

- **The requester was asked.** The direction above is this plan's proposal,
  not a ratified rule. The implementing session flags it — in the pull
  request body and to the human — and says it is proposing a reversal of the
  sentence at *"The same goes for a consumer's plan names…"*. Under
  `JOHARNESS_MODE=unsupervised` this item is what stops the plan merging a
  rule change nobody was asked about.

- `./joharness.sh ci` → `ci: pass`; `./joharness.sh finish` green; edge
  review recorded with one finding tagged `(verifier)`.

## Where to look

- `.agents/docs/consumer-repos.md:Name no consumer` — the section, both
  paragraphs, and the un-gated reasoning below them.
- `.agents/harness/AGENTS.md:Verify` — "Measured number carries what produced
  it", the counting requirement the exemption serves. It is in step 5 of the
  Loop, not in `graph.md`; an earlier draft of this plan cited the wrong file
  and `lint_anchors` could not have caught it, because it checks the path and
  never the content.
- `.agents/docs/agent-selection.md` — its own first lines are check 1's
  evidence, and it is also the tier table.
- `.agents/docs/caveman.md` — house style for the replacement sentences.

## Traps

- **The naming rule bites the hand writing it.** The implementer is editing
  the section that forbids naming a consumer, in a file that ships to every
  consumer. Cite no repository, and no plan or item name, in the sentences
  added.
- **A measured number carries what produced it, same sentence** — the
  command, and when (`.agents/harness/AGENTS.md`, step 5). Any count added
  to this section obeys the rule the section is about.
- **Do not add a glossary row.** See Out of scope; it would red every
  legitimate use.
- **`git grep` before calling a sentence unique.** This defect exists
  because two sentences said the same thing differently and nobody grepped.
- **Deciding is allowed; deciding silently is not.** "Decide alone" does not
  list a documentation rule as stop-and-ask, so this plan proposes rather
  than parks — and the acceptance makes the flag a gate, because the first
  draft named a veto nobody was required to offer.
