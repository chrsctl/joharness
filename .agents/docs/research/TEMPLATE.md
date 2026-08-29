---
research: short-kebab-question
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/some-file.md
---

<!--
Copy to docs/research/<question>.md. Queue rules:
.agents/docs/research/README.md.

A research node settles ONE question and writes no code. A research file
that edits code is a plan wearing the wrong frontmatter.

`research` = the stem, as `plan:` is for plans.
`graduates` = the file the answer lands in when the question closes. The
edge is declared here and completed by the merge that deletes this file.
A question with no such file is a question nobody will act on.

A plan blocked on this question carries `research: <stem>` and stays
blocked while this file exists — same machinery as `needs`, same reason:
file existence is the state, no status field to rot.
-->

## Question

One sentence, answerable. Not a topic.

## Echo

The question restated in your own words, before any method runs. What you
believe it is asking, and what rests on the answer.

## Sweep

`comprehensive` or `goal-directed`, named. Then one line saying what that
choice means here — everything there is, or everything needed for what.

## What would settle it

The evidence that closes the question EITHER WAY. Written before the method
runs, so the answer cannot be fitted to what was found.

## Method

The commands run, verbatim. Web queries count as commands: quote them.

## Findings

- **The finding, stated.** Then its evidence, and the command or source that
  produced it. A finding with no command under it is an opinion.

## Consequence for the queue

Which plan changes, in what way, or none. This is the hop a plan reader
acts on.

## Verification

Who checked, and from where — a context that did not produce the findings
above. Each claim marked GROUNDED or WEAK, with what the second context
actually read. No date: the commit carries when.

## Graduates to

The file named in `graduates:`, and one line on why the answer belongs
there rather than in a rule line alone.
