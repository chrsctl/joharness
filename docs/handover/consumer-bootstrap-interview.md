---
workstream: consumer-bootstrap-interview
status: in-progress
branch: claude/drain-session-access-r80jpt
pr: none
plan: consumer-bootstrap-interview
issue: none
session: https://claude.ai/code/session_01HkdcTFBBEsYFS3MKbxjZ3R
agent: sonnet
updated: 2026-09-04
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

"Add all switches to the initial questions." One question exists today, the
autonomy switch, merged in pull request #208. The other four conf keys are a
flag or a hardcoded seed value.

## Decisions

- **Branch restarted from `main`.** Its previous pull request is merged, so
  this is a fresh change on the same branch name rather than commits stacked
  on merged history.
- **Defaults do not move.** `none`, `lazy`, `lazy`, `off`, `supervised` stay
  what a repo gets by pressing Enter. The change is who is asked.
- **A key is written to an EXISTING conf only when a flag gave it or the
  interview answered it.** The selftest already pins a bootstrap keeping
  `JOHARNESS_ENV=custom-own`, and that is the correct rule: a value nobody
  was asked about is the consumer's own. `JOHARNESS_MODE` stays the exception
  it was given in #208, because autonomy must not arrive by inheritance.
- **The interview offers the conf's current value as the default** where one
  exists. Enter is then a no-op rather than a way to strip a selection.

## Rejected

- **Feeding the pty helper one answer per run.** It worked while the interview
  asked one question and hung the whole suite the moment it asked three: a pty
  reports no end of file while its master is open, so the second `read` blocks
  instead of defaulting. One line per question plus a tail of blanks, and a
  `timeout` around every pty run so the next question added here fails a case
  rather than hanging a job.
- **Validating an interview answer exactly as a flag.** It reads as the strict
  choice and it is the wrong one: the question offers the conf's current value
  in brackets, so strict validation refused the very word it had just
  suggested. Review r2.
- **Dying on an answer the question cannot use.** Review r1: the prompt this
  grew out of defaulted rather than dying, and a typo at question four threw
  away questions one to three.
- **Asking the two layer-shaped questions when the layer is `none`.** They
  configure a layer; with none selected they configure nothing.

## Review

Sonnet depth: `/code-review` (high) on the full diff, plus the harness verifier
reading it cold. Six findings. Both readers independently found the dead read
in the autonomy question; everything else was found by one and not the other.

- r1: (verifier) **A habitual `y` or `n` killed the whole interview.** The
  question this grew out of was `[y/N]` and accepted `y|Y|yes|YES|Yes`,
  defaulting anything else. Rewritten as `supervised | unsupervised` and
  validated, it exited 1 on `y` — after the operator had answered every
  earlier question, all of which went with it. Reproduced under a pty at both
  the review and the autonomy question. (fixed: one `ask_choice` for all four
  two-choice questions. Enter takes the value in force, either word takes
  itself, `y` and `n` take the second and first — the second is the more-doing
  option in every pair here — and a word it cannot use is asked AGAIN, three
  times before it is an error, so a typo costs a line rather than a session)
- r2: (code-review) **The layer question validated a typed answer harder than
  Enter.** It offers the conf's current value in brackets, so with
  `JOHARNESS_ENV=custom-own` the prompt reads `[custom-own]`, Enter succeeds
  and typing that same word exits 1. A repo is entitled to keep saying what it
  already says. (fixed: an answer equal to the value in force takes the Enter
  path, since it is the same decision)
- r3: (code-review) **The no-terminal line described a child that does not
  exist.** It printed the parse-time defaults as what the repo would run
  under, while on an existing conf only `JOHARNESS_MODE` is written.
  Reproduced against a whole clone: the log said "env none, review off" over a
  conf keeping `JOHARNESS_ENV=docker` and `JOHARNESS_REVIEW=on`. (fixed: the
  line now says a seeded conf gets the defaults and an existing one keeps its
  own values with only the mode written)
- r4: (code-review) `.agents/docs/consumer-repos.md` carried the same
  misstatement, that a run with no terminal "takes every default". (fixed:
  split into what a seeded conf gets and what an existing one keeps)
- r5: (code-review, verifier) **Dead read in the autonomy question.** It read
  `JOHARNESS_MODE` out of the conf into `cur`, then overwrote `cur` with
  `supervised` two lines later, with the explanatory comment between. Both
  readers noted that deleting the live line as the apparent duplicate would
  silently restore inherited autonomy. (fixed: the read is gone and the
  comment says there is deliberately nothing to read here)
- r6: (self, during the build) **Adding questions hung the suite.** The pty
  helper fed one answer, and a pty reports no end of file while its master is
  open, so the second question's `read` blocked rather than defaulting. Killed
  after ten minutes. (fixed: one line per question plus eight blank ones, and
  `timeout` around every pty run, so the next question added here fails a case
  in a minute instead of hanging a job nobody can interrupt)

The verifier reproduced and cleared several things worth not re-deriving: no
path reaches `unsupervised` without the literal word or the flag; the layer
name typed at the question is validated exactly as `--env` is; `set_conf_key`
cannot corrupt `JOHARNESS_ENV_SETUP` while writing `JOHARNESS_ENV`, because
the pattern anchors on the `=`; no answer can reach the `sed` replacement with
a `|` in it, since every written value is either a fixed enum or constrained
to `[a-z0-9._-]`; and the dry run leaves the tree byte-identical on both entry
paths.

## Blockers

None.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh` — first contact; the only place the
  harness asks a human anything.
