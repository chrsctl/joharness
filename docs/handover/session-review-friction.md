---
workstream: session-review-friction
status: review
branch: claude/session-review-harness-friction
pr: none
plan: none
session: https://claude.ai/code/session_01Qk5dbNUvkmSB1dj5ufvhNB
agent: opus
effort: high
updated: 2026-08-24
next: Review and merge the PR.
---

## Goal

A consumer repo (`chrsctl/gx`) ran one long session — thirteen PRs merged,
CRM phases C4 through C10 — and was then asked to review the *run* for harness
improvements. These are the findings that belong here rather than there, with
the evidence each rests on. `plan: none`: the trigger was a human request, not
a queue item.

The consumer's own findings (`run-all.sh` discarding its failure transcript,
and a criteria index that cannot match a phrase spanning two string literals)
are repo-owned and stay in `chrsctl/gx`.

## Decisions

- **Stale-workstream listing is bounded, and the message names step 7.**
  23 files on `origin/main` printed 23 lines before the first prompt, every
  session, and the wall reads as a chore nobody owns. `JOHARNESS_STALE_SHOWN`
  (default 5) caps the list; the tail is a count. The message now says what
  the files ARE — step 7 not happening, one merge at a time — and that YOUR
  pull request deletes YOUR file. A count that stays flat is the signal; a
  list nobody reads is not.
- **Step 7 splits branch deletion from file deletion.** Thirteen merges in
  that run added six workstream files to `main` and removed none, with the
  Loop read end to end each time. "Deleting = optional hygiene, human-only"
  sits one sentence above the file-deletion clause and reads as covering it.
  Now: deleting the BRANCH is optional and human-only; deleting the FILES is
  not optional and is yours.
- **The lazy-provisioning banner says setup does not survive a resume.**
  Two stalls in one run, both after a session resume: files were on disk, the
  Docker daemon was not, and the banner's "Not provisioned at session start"
  was read as covering only a first start. One line, because the banner was
  literally true — see Rejected.
- **`scope` must name the file a plan registers itself in.** Three plans each
  adding a suite have disjoint subjects and disjoint declared scopes, and all
  three edit `.github/workflows/ci.yml`. The hook then does not merely miss
  the conflict, it asserts the opposite: it proves a parallel wave. Guidance
  now names the shape — suite→CI workflow, doc→index, module→runner list.

## Rejected

- **A `probe.sh` in the env contract**, so the entrypoint could report actual
  provisioned state instead of a static banner. Correct and too expensive:
  `.agents/env/README.md`'s "every file optional" contract is deliberately
  minimal, and one wrong assumption twice does not buy a new required-ish
  file in every environment layer. Revisit if the same stall shows up in a
  second consumer repo.
- **Making the stale-file check fail or block.** It is a report about other
  people's merged branches; a session that inherited 23 of them cannot be the
  one held responsible. Bound it and name the owner instead.
- **Carrying the consumer's two findings here.** `run-all.sh` discarding the
  failing suite's output, and the criteria index matching raw file text so a
  phrase spanning two adjacent string literals never matches, are both
  `chrsctl/gx` code. They stay there.

## Review

- Finding 4 (the banner) was downgraded during review from "the contract is
  wrong" to "the message is short one line" — the banner said *at session
  start* and meant it; the failure was my reading. Recorded because the first
  framing would have changed the env contract for every layer.
- Rewording the rot message broke `rot check ignores status field`: the first
  draft wrapped "Merged = finished" across two `add` lines and the assertion
  greps the phrase. That message is asserted text, not prose — reflowed rather
  than reworded.
- The first cap assertion refuted a bare `docs/handover/stale-ws.md`, which
  also appears in the other-branches section because the `inheritor` fixture
  carries a copy. It failed for the right answer and the wrong reason. Both
  listing assertions now anchor on the stale list's own two-space indent.
- The `scope` finding came out of this session's own review of its own plans,
  not out of a hook failure. It has no test here: the hook proves disjointness
  of what it is told, and nothing can check a declaration against a file the
  plan has not written yet. Guidance is the whole fix, and it is weaker than
  a check. Left as guidance deliberately.

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — the rot check, and the listing that
  grew to 23 lines in one session.
- `joharness.sh` — the lazy-provisioning banner.
- `.agents/docs/plans/README.md` — `scope`, and the file it cannot express.
