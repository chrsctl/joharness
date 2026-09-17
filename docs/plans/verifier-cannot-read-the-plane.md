---
plan: verifier-cannot-read-the-plane
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .claude/agents/verifier.md, .agents/docs/research/README.md, .agents/harness/selftest/review.sh
---

## Goal

Issue #267, its first option and only that one. `.agents/docs/research/README.md`
requires a second context that did not produce the findings, and Loop step 5
spawns `.claude/agents/verifier.md` at every review depth. For a question
whose evidence is a control-plane record, that pairing cannot work: the
reviewer declares `tools: Read, Grep, Glob, Bash` and has no such call.

It went wrong once, in the open: a research node's `## Verification` recorded
that reviewer re-sampling live sessions, and the reviewer's own first line
was that it could not, so every reading was a written number to it. The
answer was withdrawn on review — the right outcome, reached slower than it
needed to be, because nothing said the pairing was impossible before the
section was written.

## Scope

- `.claude/agents/verifier.md` — say what this reader cannot see. Its four
  tools are the whole of its reach, so a claim resting on a control-plane
  record, a live service or anything else `outside this checkout` is one it
  can only check for internal consistency — that phrase verbatim, because
  Acceptance makes it the literal both files must carry. It should say that in its own voice,
  where a session about to spawn it reads, and say what it DOES do with such
  a claim: check the arithmetic, check nothing in the repo contradicts it,
  and mark it as unverified rather than silent.

- `.agents/docs/research/README.md`, the Verification section — a node whose
  evidence is a reading this reviewer cannot take names its second context
  UP FRONT, in `## Method`, rather than discovering the gap at verification
  time. Two honest answers exist and the section should name both: the
  operator takes the reading, or a differently-tooled session does. Neither
  is "the verifier did it".

- `.agents/harness/selftest/review.sh` — assert the new sentence is there,
  so a later edit cannot quietly drop the one line that would have prevented
  the instance above. Note what that topic does NOT do today: it checks
  `verifier.md` exists and is non-empty (`[ -s ... ]`) and reads none of its
  content, so this is a new shape there rather than one more needle. It has
  `$ROOT` and the path already, and the existence check is guarded on
  `JOHARNESS_CANONICAL=1` — a content assertion needs the same guard, or it
  fires in a consumer checkout where the file is present and not owned.

## Out of scope

- Giving the verifier control-plane tools, issue #267's option 2. It runs
  unattended at every review depth in every consumer, and
  `interrupt_session`, `archive_session` and `create_session` sit behind the
  same MCP server as `get_session` — so this is a decision about what an
  unattended agent may do to a live fleet, which is the human's, not a
  tool-list edit. The issue says so itself and does not claim an answer.
- Whether a separate read-only reviewer file beats a tool-list flag. Same
  decision, one level down.
- Making the operator the second context by rule, option 3. It makes a
  question wait on a person, which is the operator's call to accept.
- Any change to what Loop step 5 spawns, at any depth. The reviewer stays
  exactly as mandatory and exactly as tooled.
- The node that exposed this. It is merged, open, and carries the instance
  in its own `## Verification`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`. Both files are prose the caveman and
  glossary stages read, so the bar is a gate here.
- `.claude/agents/verifier.md` names the limit and what the reviewer does
  instead. Asserted in `review.sh` against the file's own text, single-line
  needles grep-checked against the file before committing — a needle that
  crosses a wrapped line fails on a reflow that changed nothing.
- `.agents/docs/research/README.md` says a node needing such a reading names
  its second context in `## Method`, and names both honest answers.
  Asserted.
- Proved by REVERTING, per Loop step 5: dropping the sentence from
  `verifier.md` reds a positive assertion. Use `./joharness.sh mutate`,
  which restores the line itself — never a hand-edit of the working tree,
  which staged a mutated file once on this repo.
- The two files agree on WHICH claims are affected, asserted mechanically
  rather than by reading, because the node author reads one file and the
  reviewer reads the other. Pick ONE literal phrase for the boundary —
  `outside this checkout` is the one Scope bullet 1 already uses, and the
  exact wording matters less than its being identical — put it in both files, and assert it in
  each: the first `expect` pins the literal against `verifier.md`, the
  second compares what the README carries to what the first found. Needle
  first in the second one, or an empty match passes over anything. That is
  the shape that caught a near-miss spelling on this repo two items ago; a
  bullet asking the files to "agree" without naming the token is a bullet
  nobody can write.
- SHIPS: `.claude/agents/` and `.agents/docs/` both reach every consumer, so
  this changes what every reviewer says about itself. Name the consumer-side
  check: in a consumer, spawn the verifier on any branch and its report
  carries the limit; and `.agents/docs/research/README.md` there tells a node
  author the same thing.

## Where to look

- `.claude/agents/verifier.md:4` — the tool list, which is the whole fact.
- `.agents/docs/research/README.md`, "Verification is not optional" — the
  requirement, and its own worked instance of a second source that
  corroborated nothing, which is the same failure one step out.
- `.agents/harness/selftest/review.sh` — it already reads `verifier.md`, so
  the assertion has a home and needs no new topic.
- `docs/research/liveness-in-a-long-turn.md`, `## Verification` — the
  instance, with what the reviewer could and could not check.

## Traps

- Do not widen the reviewer's tools to make the limit go away. That is the
  human's decision and it is out of scope by name.
- A needle for a `.md` file must sit inside one wrapped line. Two
  assertions on this repo failed that way in one session, the second after
  the first was fixed; grep the needle against the file first.
- The reviewer must still REPORT an unverifiable claim, not skip it. A
  reader told "you cannot check this" that then says nothing has turned a
  known limit into a silent one.
