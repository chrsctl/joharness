---
plan: unsupervised-authority-provenance
urgency: urgent
agent: opus
effort: high
needs: none
requirement: unsupervised-mode
advances: Started once, the fleet keeps going for hours with no human turn
scope: joharness.sh, .agents/docs/unsupervised.md, .agents/harness/selftest
---

## Goal

The endurance run of 2026-08-31 lasted 48 seconds. Both spawned sessions
refused their task as a suspected prompt injection and asked for a human.
They were right to: *never ask a human*, *there is no human watching you*,
*merge your own pull requests* is the shape of an injected task, and a
session that complies with it unconditionally is the one misbehaving.

So the fleet cannot be started by a prompt that asserts its own authority.
**It has to be startable by a prompt that points at evidence the session can
check for itself.**

## The distinction that does the work

`mode_source` already knows where the mode came from, and the three sources
are not equally trustworthy to a session that suspects its own prompt:

| source | what it proves |
| --- | --- |
| `conf` | a **committed, reviewed** line in the repo the session cloned |
| `marker` | a file in someone's git directory |
| `environment` | a variable the caller exported |

Only the first is evidence. The other two are the caller asserting
authority by a different route — exactly what the session is right to
distrust. Nothing today draws that line.

## Scope

- **`./joharness.sh authority`** — prints the provenance of the current
  mode and reaches a verdict a suspicious session can act on:
  - the resolved mode and its source;
  - for `conf`: the commit that last set `JOHARNESS_MODE`, with sha,
    author, date and subject, and whether it is an ancestor of the default
    branch (reviewed and merged) or only local;
  - the open requirements in `docs/product/`, since unsupervised is live
    only while a goal is open;
  - a verdict: **VERIFIABLE** only for a merged conf commit;
    **UNVERIFIED** for marker and environment, saying plainly that the
    claim rests on the caller and not on the repository.
- **A documented spawn-prompt shape** in `.agents/docs/unsupervised.md`:
  the prompt GRANTS nothing. It names the work, points at
  `./joharness.sh authority`, and instructs the session to stop if the
  verdict is not VERIFIABLE. Authority comes from the tree; the prompt only
  routes.

## Out of scope

- **Wording that gets past the refusal.** If a session still declines after
  checking committed evidence, that is its call and the answer is not more
  persuasive text. This plan makes the evidence checkable; it does not try
  to make the check come out a particular way.
- Any change to what unsupervised mode DOES once running.
- Making `authority` grant anything. It reports; `run_mode` still decides.

## Acceptance

- `authority` prints VERIFIABLE for a merged conf flip, and UNVERIFIED for
  the marker and for `JOHARNESS_MODE=` in the environment.
- A conf flip that exists only as a local commit does not read as merged.
- `.agents/docs/unsupervised.md` carries the spawn-prompt shape, and it
  asserts no authority of its own.
- Cases for each verdict, and `mutate` reds them.

## Traps

- **Absent is not zero, again.** A repo with no git history, or a detached
  checkout that cannot resolve the default branch, must read as UNVERIFIED
  and never as verified — the same rule `sources` follows for a source it
  cannot count.
- Do not let `authority` exit non-zero for UNVERIFIED alone. It is a report;
  a session reads the verdict. An exit code invites a caller to branch on
  it and turn a report into a gate nobody reviewed.
