---
workstream: local-checks-merge
status: in-progress
branch: claude/skip-github-actions-wait-jdd3bn
pr: 236
plan: none
issue: none
session: https://claude.ai/code/session_018BqX6Ux5hvSAm5AQ725mDe
agent: opus
updated: 2026-09-11
next: Review the ci.yml gate, record it, retire this file again.
---

## Goal

Second increment on an open pull request, at the requester's word: "if you
run out of GitHub action minutes you should be able to switch". The knob as
merged saves the WAIT and not the minutes — `ci.yml` still runs on every
pull request and every push to `main`, whatever a session does locally. So
the same name gets a second home: a GitHub repository variable the workflow
itself reads.

## Decisions

- One name, two homes, chosen over a second name. `JOHARNESS_CHECKS` in
  `joharness.conf` says what the SESSION does; `vars.JOHARNESS_CHECKS` in
  the repository's variables says whether GITHUB spends minutes. Two readers
  on two machines, one word for the question they both answer. A second name
  would let them disagree silently, and the only reason to want that
  disagreement is a case nobody has yet.
- Repository variable, not the tracked conf: the workflow cannot read a file
  from the branch before deciding whether to start, and a switch that needs a
  commit is no use to somebody who has already run out of minutes.
- The gate is on the `lint` job, not on `on:`. A workflow-level `if` does not
  exist, and gating the trigger would need a commit to restore.
- The reasoning lives in ONE place, `.github/workflows/ci.yml`'s `lint` job;
  `joharness.conf` and the bootstrap's seeded conf point at it. The first
  draft restated it in all three and the third copy already disagreed (r15).
- The variable stops GitHub checking and starts nothing. Set alone, with the
  conf left at `github`, no machine checks anything — stated as the sharp
  edge rather than papered over with a branch-protection claim that is not
  true of this repo (r16).
- Not read by `joharness.sh` at all. The entrypoint has no GitHub token and
  no business asking; the workflow is the only reader of the variable, the
  conf is the only reader of the key.

## Rejected

- Gating on `on:` or deleting the trigger. Both need a commit to undo, which
  is the thing the requester is trying to avoid at the moment minutes run out.
- A second switch name (`JOHARNESS_CI_RUNS`, say). Independence nobody has
  asked for, paid for in every document that then has to explain which is
  which.
- Having `finish` read the repository variable through the API to warn when
  the two disagree. A gate that needs a token is a gate a consumer without
  one cannot run — the same reason this command reads no checks today.

## Review

Second increment, opus adversarial plus `.claude/agents/verifier.md` at opus
on commit `f1f035b`. The one-line mechanism survived every pass; the forty
lines of prose around it did not, and eight of the eleven findings are about
claims those comments made.

- r15: (verifier, correctness) the bootstrap's seeded conf said "no run
  starts", which the same commit contradicted twice — `ci.yml` and
  `joharness.conf` both said the run IS created and the job skipped.
  Measured against this repo's own data: run 34520202488 lists the `windows`
  job, skipped by a job-level `if: false`, as completed with conclusion
  `skipped` and `started_at` equal to `completed_at`, and it appears as a
  check run on the commit (Actions API, 2026-09-11). (fixed: that copy is
  now a pointer, and `ci.yml` carries the measurement.)
- r16: (verifier, correctness) THE finding. "Branch protection requiring that
  check holds the merge button" was asserted three times as the reason this
  is safe, and it is not true here — `branches/main` reports
  `"protected": false` with no required checks (2026-09-11), so the brake
  named does not exist. Worse, whether a `skipped` check satisfies or blocks
  a required check is GitHub behaviour neither reader can test, and it is
  documented to go the other way. (fixed: the claim is gone. What replaces
  it is the hazard it was papering over — variable set, conf left at
  `github`, no machine checks anything and step 7's first condition is met
  by a run that checked nothing — stated as the sharp edge, with what is
  measured and what is not relied on marked as such.)
- r17: (verifier, correctness) organization-scope precedence was in none of
  the three homes. `vars` resolves environment, then repository, then ORG, so
  an org variable of this name switches the job off in every consumer holding
  no repository value — with their own conf still saying `github`, which is
  r16 happening to somebody who never touched their repo. (fixed: named, with
  "set it on the repository" in the instruction itself.)
- r18: (verifier, correctness) the layer verdict goes with the job:
  `.agents/scripts/ci-verify-layers.sh` is a STEP of `lint`, so with the
  variable set a session has no run to read for its layer and owes `verify`
  itself. Unmentioned. (fixed: named in `ci.yml`, pointing at step 7.)
- r19: (verifier, correctness) the gate also covers `push: branches: [main]`,
  so the per-sha `main` runs the concurrency block above it exists to protect
  — the ones catching cross-PR collisions no per-PR gate sees — skip too. The
  new text was written entirely in pull-request terms. (fixed: named.)
- r20: (verifier, correctness) "the minutes switch" overstated: `update.yml`
  keeps a weekly cron and the `windows` job would bill at 2x if re-enabled.
  (fixed in the wording — it now says it gates the per-pull-request spend,
  which is the one that scales. `update.yml` itself left ungated: a repo out
  of minutes that also stops receiving harness updates is a different trade
  from not re-running PR checks, and it is the human's to make. Raised with
  the requester rather than decided here.)
- r21: (verifier, docs) the fact lived in three places while two of them
  claimed it lived in two, and the third had already rotted (r15). Nothing in
  `ci` compares them. (fixed by subtraction: `ci.yml` holds the one copy,
  `joharness.conf` and the seeded conf are pointers.)
- r22: (verifier, correctness) "Set `JOHARNESS_CHECKS=local` there" misreads
  the Variables UI, which takes Name and Value as separate fields — pasting
  that string as the value sets something that is not `local`, the job keeps
  running, and nothing says why. Exactly the requester's scenario failing
  silently. (fixed: the two fields are spelled out, with that failure named.)
- r23: (verifier, docs) this file cited `bootstrap-consumer.sh:788` for the
  ci.yml seed; at that commit line 788 is about `write_decided_keys` and the
  seed is at 795. A line number in an anchor, which the plan protocol forbids
  for this exact reason. (fixed: the anchor names the function.)
- r24: (verifier, docs) "nothing a session can flip" stated a convention as a
  mechanism — no protocol path covers the variable and no gate reads it.
  (fixed: it now says a session cannot SEE it, and that nothing forbids one
  touching it.)
- r25: (verifier, docs) "Actions is free on this public repo" was a fourth
  copy of a claim already in this file, and false in the private consumers it
  is seeded into. Same class as this file's PR210 r4. (fixed: removed.)

## Blockers

None.

## Where to look

- `.github/workflows/ci.yml:lint` — the job the variable gates.
- `joharness.conf:JOHARNESS_CHECKS` — the other home of the same name.
- `.agents/scripts/bootstrap-consumer.sh:seed` — ci.yml is SEEDED verbatim at
  bootstrap and never synced after, so a consumer older than this carries the
  ungated workflow.
