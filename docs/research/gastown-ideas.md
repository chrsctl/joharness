---
research: gastown-ideas
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/docs/prior-art.md
---

## Question

Which ideas in gastownhall/gastown should joharness adopt, which does it
already have under another name, and which does it reject with reason?

## Echo

Human asked for a review of gastown's ideas. Gas Town is Steve Yegge's
multi-agent orchestration system for Claude Code and other runtimes:
tmux-managed worker fleets, a git-backed issue ledger (Beads), watchdog
agents, a merge queue. joharness solves an overlapping problem — sessions
that outlive their context, work that outlives its session — with markdown
files and git instead of daemons and a database. What rests on the answer:
whether any joharness plan should exist to adopt a gastown mechanism, and
whether any joharness rule gets a recorded rejection so the question stays
closed.

## Sweep

`goal-directed` — everything needed to decide adopt / already-have / reject
for joharness. NOT everything gastown contains: implementation quality,
`internal/` Go code, and most of `docs/design/` were not audited. Findings
are about stated ideas, read from gastown's own docs.

## What would settle it

For each gastown idea: the gastown doc stating it, the joharness rule or
mechanism covering the same ground (or none), and a verdict one of
adopt-candidate / convergent (already have) / reject (with the joharness
rule it collides with). Settled either way: an idea with no joharness
counterpart and real value is an adopt-candidate; an idea joharness's own
measured rules argue against is a recorded rejection. Unsettleable here:
whether gastown's mechanisms work well in practice — that needs running it,
out of this sweep's scope.

## Method

```bash
GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://github.com/gastownhall/gastown /home/user/gastownhall/gastown
git -C /home/user/gastownhall/gastown log -1 --format='%H %cI %s'
# 649b832b7672bc7a2dbef26f5983aba6198b819b 2026-07-23T09:03:02-04:00
ls /home/user/gastownhall/gastown /home/user/gastownhall/gastown/docs \
   /home/user/gastownhall/gastown/docs/concepts /home/user/gastownhall/gastown/docs/design
```

Read whole: `README.md`, `AGENTS.md`, `docs/why-these-features.md`,
`docs/glossary.md`, `docs/concepts/propulsion-principle.md`,
`docs/concepts/heartbeats.md`, `docs/concepts/molecules.md`,
`docs/concepts/identity.md`, `docs/concepts/integration-branches.md`,
`docs/concepts/convoy.md`. joharness side read from `AGENTS.md`,
`.agents/harness/AGENTS.md`, `.agents/docs/research/README.md`,
`.agents/docs/glossary.md` on this branch.

All gastown paths below are relative to that clone at `649b832`.

## Findings

- **F1 — Work as a queryable ledger.** Gastown's foundation: every work item
  is a "bead" in a git-backed Dolt database; every action carries an actor;
  history is queryable (`bd audit`, `bd stats`). Source:
  `docs/why-these-features.md` ("Work is data. Not just tickets —
  structured, queryable data."). joharness's counter-position is deliberate:
  state is file existence on branches, readable by `git show`, no database,
  no daemon — and `.agents/docs/research/README.md` ("Not an index") bans
  second views as stored-copy failures. Verdict: reject the mechanism, keep
  the principle — joharness already treats work as data, the datastore is
  the tree. The cost gastown pays (`bd`, sqlite3, tmux in `README.md`'s
  prerequisites table; Dolt and the daemons via the install steps and
  `gt up`) is the cost joharness's design exists to avoid.

- **F2 — GUPP, the propulsion principle.** "If you find something on your
  hook, YOU RUN IT" — agents execute assigned work immediately, no
  confirmation round-trip; the named failure mode is a worker announcing
  itself and waiting while the watchdog assumes progress. Source:
  `docs/concepts/propulsion-principle.md`. Convergent: joharness Loop step 1
  ("Hook names workstream file for this branch? That is your job"), step 2's
  "not invent work" inverse, `/drain`, and unsupervised mode's "edge =
  generate work, never ask". joharness even has the measured version of
  gastown's stall story: 5 of 119 merge gaps over three hours with a full
  queue (`.agents/harness/AGENTS.md`, `/drain` paragraph). Verdict: already
  have; nothing to adopt but the phrase is good.

- **F3 — Persistent agent identity and derived capability.** Workers have
  persistent identities across ephemeral sessions; commits and records carry
  `BD_ACTOR`; capability is meant to be DERIVED from work history rather
  than declared. Source: `docs/concepts/identity.md`. But capability-based
  routing is explicitly "Status: Planned — not yet implemented"
  (`docs/why-these-features.md`). joharness declares capability statically:
  plan frontmatter `agent:` tier (`.agents/docs/agent-selection.md`).
  Derived-from-history matching is the "trust counted numbers" philosophy
  applied to agent selection, which joharness should find attractive — but
  gastown itself has not built it. Verdict: idea worth remembering, no
  adoption while the only existing implementation is a design doc.

- **F4 — Watchdog chain with cross-checked liveness.** Three tiers (daemon →
  Boot → Deacon → Witness, `README.md` "Monitoring & Health"), each watching
  the next, plus a hard-won rule:
  gastown keeps THREE heartbeat stores, they diverge, and the recorded
  incident (hq-qxl9) is a healthy agent escalated as stuck because one store
  aged while another was fresh. Their fix: never declare an agent stuck from
  a single store; cross-check tmux activity first. Source:
  `docs/concepts/heartbeats.md`. joharness's `/who` is a single liveness
  source ("`/who` = truth", `.agents/harness/AGENTS.md`), which avoids the
  divergence bug by construction. Verdict: convergent on the lesson from the
  opposite direction; the chain-of-watchers shape is relevant to the
  unsupervised fleet heartbeat (`.agents/docs/unsupervised.md`) if that ever
  grows a monitor — adopt the "one store or cross-check all" rule there.

- **F5 — Bors-style bisecting merge queue (Refinery).** Workers never push
  to main; completed branches queue, the merged stack is verified once, red
  batches bisect to isolate the failing MR. Source: `README.md` "Merge Queue
  (Refinery)". joharness instead serializes at merge time: each session
  merges its own PR, must be 0 behind fresh-fetched main, and reconciles by
  hand when main moved (step 7). That reconcile loop is exactly the
  contention a merge queue removes — but joharness's own measured data shows
  the current failure is starvation (gaps with a full queue), not
  contention. Verdict: adopt-candidate ONLY when a measured number shows
  sessions losing time to step-7 reconciles; GitHub's native merge queue
  would be the cheap route, not a Refinery.

- **F6 — Integration branches for epics.** Child work merges into a shared
  `integration/{epic}` branch, landing on main as one merge commit when all
  children close; guarded by three layers (role prose, a pre-push git hook
  doing ancestry detection, an env-var-bearing authorized code path).
  Source: `docs/concepts/integration-branches.md`. Direct collision:
  joharness step 7 says "every step merges, no long-lived integration
  branch". Gastown's gains (atomic epic landing, cross-child coherence,
  one-commit rollback) are real but priced in exactly what joharness
  optimizes against: work invisible on main for the epic's lifetime, and a
  branch a dead session can strand. Verdict: reject, now with the reasoning
  recorded. One sub-idea IS adoptable separately — see F10.

- **F7 — Formulas and molecules; lazy step materialization.** Reusable TOML
  workflow templates instantiated per run; the operational lesson is that
  materializing every step as a database row cost ~6,000 rows/day and the
  fix was root-only wisps (~400/day) with steps read inline, reserving
  materialized checkpoint-recovery steps (`pour = true`) for workflows where
  "you would curse losing the progress after a crash". Source:
  `docs/concepts/molecules.md`. joharness plans are one-shot files, deleted
  on merge — no accumulation by construction, and repeatable process lives
  in `joharness.sh` subcommands instead of templates. Verdict: convergent
  outcome; the pour heuristic is a crisp sentence worth stealing if joharness
  ever adds checkpointing to long work.

- **F8 — Mail vs nudge split.** Two channels with distinct semantics:
  persistent payload (`gt mail`, survives restarts) and ephemeral wake
  (`gt nudge`, immediate delivery); "mail carries payload, nudge wakes".
  Source: `AGENTS.md` (gastown's). joharness has only the persistent
  channel — workstream file plus push — and live sessions discover each
  other by fetch (`/who`). Verdict: clean decomposition; adopt only if
  joharness sessions ever need same-instant coordination, which the
  branch-per-workstream design mostly removes.

- **F9 — Seance: query predecessor sessions.** Dead sessions' event logs
  are discoverable and a successor can ask a predecessor questions
  (`gt seance --talk`). Source: `README.md` "Seance". This is recovery for
  what handover files fail to capture. joharness bets the other way: make
  the handover file carry everything non-derivable (same commit as code,
  push or invisible), and treat compaction decay as measured and designed
  for (`.agents/docs/handover/README.md`). Verdict: reject as mechanism —
  a needed seance is a failed workstream file — but it is the strongest
  challenge to that bet, and worth revisiting if handover files measurably
  lose decisions.

- **F10 — Hard gates over prose for policy an agent could ignore.**
  Gastown's stated reason for its three-layer guard: "AI agents can ignore
  instructions" — so policy gets a git-boundary enforcement (pre-push hook)
  behind the prose. Source: `docs/concepts/integration-branches.md`,
  "Safety Guardrails". joharness already lives this (ci/finish/selftest
  gates, `fin_strength`), with one gap: "Merge-commit method ONLY" (step 7)
  is enforced by prose alone, and one squash by one session silently breaks
  the merged-branch ancestry filter for every later session. GitHub's
  allowed-merge-methods setting (or a ruleset) can restrict this
  server-side. Verdict: adopt-candidate, smallest in this file.

- **F11 — NDI and session-end discipline.** "Nondeterministic Idempotence" —
  reliable outcomes from unreliable agents via persistent state plus
  oversight (`docs/glossary.md`); and "Work is NOT complete until `git push`
  succeeds" (gastown `AGENTS.md`, Session Completion). Verdict: convergent
  with joharness's foundations ("no push, no claim"; infrastructure reading
  re-derived at every check) — independent teams landing on the same two
  rules is evidence for both.

- **F12 — Scope joharness should not follow.** Wasteland federation
  (cross-town work market with reputation stamps, `docs/WASTELAND.md`
  listing), multi-runtime presets (11 agent CLIs, `README.md`), OTEL
  telemetry, web dashboard, TUI feed. All serve gastown's fleet-of-30
  ambition. joharness's unit of scale is the repo and its queue; none of
  these earn their weight at that scale. The one transferable fragment: the
  problems-view health taxonomy (GUPP violation / stalled / zombie /
  working / idle, `README.md` "Problems View") is a good vocabulary for the
  unsupervised heartbeat's checks.

## Consequence for the queue

No existing plan changes. Two adopt-candidates, both small, neither filed as
a plan by this research (the human decides they are wanted):

1. Enforce merge-commit-only server-side (F10) — GitHub's allowed-merge-
   methods setting or a ruleset, so the ancestry filter cannot be broken by
   one forgetful squash. One settings change plus a line in
   `.agents/docs/product/README.md`.
2. When `.agents/docs/unsupervised.md` heartbeat work is picked up, carry
   F4's liveness rule (one store, or cross-check all stores) and F12's
   health taxonomy into that design.

F5 (merge queue) is explicitly deferred behind a measurement: adopt only if
step-7 reconcile time is measured hurting.

## Verification

Checked by a spawned subagent that read the gastown clone at `649b832`
directly and did not write the findings above; joharness-side citations
re-read from this branch by the same subagent. Two precision nits it raised
(F1 sourced Dolt to the wrong part of `README.md`; F4's chain cite belonged
to `README.md`, not `heartbeats.md`) were folded into the findings above in
the same commit. It could not check, from these sources: that GitHub's
settings can restrict merge methods (F10 — external product behavior), and
whether any gastown mechanism works in practice (the declared WEAK below).

- F1 GROUNDED — quotes found verbatim in `docs/why-these-features.md`
  (Design Philosophy) and prerequisites table in `README.md`; "Not an
  index" present in `.agents/docs/research/README.md`.
- F2 GROUNDED — principle and failure mode verbatim in
  `docs/concepts/propulsion-principle.md`; joharness 5-of-119 numbers in
  `.agents/harness/AGENTS.md` as cited.
- F3 GROUNDED — "Status: Planned" banner confirmed in
  `docs/why-these-features.md` (Capability-Based Routing); identity format
  in `docs/concepts/identity.md`.
- F4 GROUNDED — three stores, hq-qxl9 incident, and cross-check rule all in
  `docs/concepts/heartbeats.md`.
- F5 GROUNDED — "Bors-style merge queue — polecats never push directly to
  main" in `README.md`; bisect behavior stated there.
- F6 GROUNDED — three-layer guardrails and land flow in
  `docs/concepts/integration-branches.md`; joharness "no long-lived
  integration branch" in `.agents/harness/AGENTS.md` step 7.
- F7 GROUNDED — row counts (~6,000/day → ~400/day) and pour heuristic
  verbatim in `docs/concepts/molecules.md`.
- F8 GROUNDED — "mail carries payload, nudge wakes" table in gastown
  `AGENTS.md`.
- F9 GROUNDED — seance commands in `README.md`; the verdict sentence is
  assessment, not sourced claim.
- F10 GROUNDED — "AI agents can ignore instructions" in the guardrails
  table of `docs/concepts/integration-branches.md`; joharness merge-method
  rule is prose-only in step 7. Checked by running
  `grep -rn -i "squash" joharness.sh .agents/scripts/` and
  `grep -nE "merge_method|merge-method|--merge\b" joharness.sh` — zero hits
  either way, no code gate.
- F11 GROUNDED — NDI definition in `docs/glossary.md`; push discipline in
  gastown `AGENTS.md` Session Completion.
- F12 GROUNDED — health-state table in `README.md` Problems View; feature
  list as described.
- WEAK (cross-cutting) — claims about gastown mechanisms WORKING (refinery
  bisect behavior, seance in practice) rest on gastown's docs, not on
  running it or reading `internal/`; the sweep declared this out of scope.

## Graduates to

`.agents/docs/prior-art.md` — a why-explanation recording what comparable
systems chose and why joharness differs, so the rejections here (F1, F6,
F9) stay closed with reasoning instead of being re-litigated by the next
session that discovers gastown. The two adopt-candidates graduate as plans
only if the human queues them.
