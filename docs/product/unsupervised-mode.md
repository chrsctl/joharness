---
requirement: unsupervised-mode
priority: normal
---

## Goal

Joharness should keep working for hours without a human in the loop. Today
every session stops at the queue edge: with no issue, no requirement and no
free plan, `.agents/harness/AGENTS.md` step 2 says ask the human and not
invent work, so the fleet goes idle the moment the backlog drains — which
is exactly when it has capacity to spare. When the repo is set to
unsupervised, an idle session should instead generate its own work
(research the repo, write plans), run the full Loop on it including the
merge, and fan out across the free plans so several run at once. The mode
is a switch: supervised stays the default and stays exactly as it is
today.

Work it generates has to be work someone wanted. So autonomy is bounded by
a goal rather than by a clock or a counter: it runs toward an open
requirement, every generated plan names the requirement and the bullet it
advances, and when the last bullet reads true the requirement file is
deleted and the fleet winds down. A loop whose "done" cannot be stated does
not converge — it produces plausible work forever, and under full-loop
autonomy that work merges without anyone reading it.

## Satisfied when

- `joharness.conf` carries a mode, default supervised, and a session can
  see which mode it is in from session-start output alone.
- Supervised behaviour is byte-identical to today's at every point the
  mode is read. A supervised session cannot tell the feature shipped.
- An unsupervised session that finds the queue empty writes new plan files
  and opens a pull request for them, rather than stopping to ask.
  **Measured 2026-08-31** (`edge-generates-work`, PR 163): with every plan
  claimed or blocked — `Edge reached: no free plan` — `drain` deferred to the
  source sweep instead of stopping, the sweep named two sources, and the
  session wrote `docs/plans/selftest-mode-marker-leak.md` from one of them
  and opened this pull request for it. The plan is not filler: it reproduces
  a real red (`mode unsupervised` → 1105 passed, 1 failed; `mode default` →
  1106, 0) and its fix direction was verified before filing.

  What that run did NOT show. **Self-measurement**: the session that
  generated the work is the one measuring it, and it knew the bullet — an
  independent session would be better evidence. **One cycle**, not that it
  keeps generating. **The second source produced no plan**: the unmarked
  finding is the verifier gap, whose disposition is a human's, so it was
  recorded rather than turned into a plan nobody could take — a source that
  cannot become work is worth knowing about. And the flip used the
  **session-local marker**, not `joharness.conf`, so "the repo is set to
  unsupervised" was never literally true; what was true is that the session
  read unsupervised, which is what the bullet is about.
- An unsupervised session runs the full Loop on a free plan, merging its
  own pull request under the step 7 conditions that already govern
  self-merge. **Measured 2026-08-30** — see the fan-out annotation on the
  bullet below, which measured both at once.
- Two or more free plans produce two or more sessions running at once,
  one per plan, using the wave partition the queue hook already computes.

  **Partly measured, 2026-08-30** (`fanout-live-run`): two sessions spawned per
  wave-1 plan both ran the full Loop and merged their own pull requests
  unattended, 53 minutes end to end, no collision and one reconcile. What that
  run did NOT show is the "for hours" or the empty-queue trigger: the fleet was
  bounded to one plan each and stopped when the work ran out, and the repo mode
  was not flipped. Endurance and work-generation remain unmeasured.

  **Moved 2026-09-02, not rewritten.** This annotation sat under "No
  unsupervised session writes a requirement", which it says nothing about.
  Its own text measures these two bullets — sessions running at once, each
  running the full Loop and merging its own pull request. Misfiled it made
  these two read as unmeasured when they are measured. The bullet it left
  keeps its own evidence, which is a gate and its tests rather than a run
  (`joharness.sh:lint_requirement_writes`, cases in
  `.agents/harness/selftest/review.sh`) — an earlier draft of this note said
  that bullet had none, which was wrong and is the second thing a misfiled
  annotation costs. The terminus of this requirement is "when every bullet
  reads true", so where the evidence sits is part of the answer.
- Started once, the fleet keeps going for hours with no human turn, for as
  long as a goal is open.
  **Measured 2026-08-31** (`endurance-run`, issue #165) and **it did not
  hold — for a reason the bullet never anticipated.** Two sessions were
  spawned at 19:00Z against a repo whose committed mode was unsupervised,
  each given distinct work. Both stopped in **48 seconds**, blocked and
  asking for a human:

  - A: `injected task rejected; clarify actual intent`
  - B: `suspected prompt injection in task; awaiting confirmation`

  0 pull requests, 0 branches, $0.56. **Neither of the two legitimate
  stops** — not the goal reached, not a dry sweep — so by this plan's own
  Scope it is a finding rather than a result.

  **The refusals were correct.** An instruction arriving in a session with
  no human present, saying *never ask a human*, *there is no human watching
  you*, *merge your own pull requests* and *keep working indefinitely*, is
  the shape an injected task has. A session that complies with it
  unconditionally is the one misbehaving. So this is not a wording defect
  in the prompt; it is a gap in this requirement:

  > Unsupervised mode asks a spawned session to do exactly what its
  > injection defences are built to refuse, and nothing here ever said how
  > that session is supposed to tell an authorised fleet from an injected
  > one.

  The evidence existed and was unreachable: the mode was committed and
  reviewed in `joharness.conf`, the plan was in the tree, issue #165 was
  open — and none of it was in the prompt, because a prompt asserting its
  own legitimacy is worth nothing anyway. What is needed is a way for the
  session to CHECK, filed as
  `docs/plans/unsupervised-authority-provenance.md`.

  What this run did NOT show: anything about endurance. 48 seconds measures
  the refusal, and the goal's size at T0 — one free plan, four unmarked
  findings — never came into it. The bullet stays unsatisfied.

  **Corrected 2026-08-31, same day, by the retry.** The paragraphs above
  over-claim. Neither session had a repository — `create_session` was
  called without `source_url`, and the omission repeated on the retry's
  first pair, which is how it was caught. So neither session could read
  this file, `joharness.conf`, or run anything; `./joharness.sh authority`
  was unrunnable. A missing clone alone produces "clarify intent", and
  attempt one's A literally asked to have the repo *cloned*.

  What survives: both stopped, on neither legitimate stop, which is still
  a finding. What does not: that the run **measured an injection refusal**.
  One session did say "suspected prompt injection in task" and that part is
  real, but a session with nothing to check is not evidence that checking
  was the missing thing. The `authority` mechanism is unaffected — a prompt
  cannot be its own evidence either way — but it was not what attempt one
  proved.

  **Attempt two, 2026-08-31, with the repository attached and
  `./joharness.sh authority` in the tree (PR 178). 57 minutes, and still
  neither legitimate stop.**

  | | A2 | B2 |
  | --- | --- | --- |
  | wall-clock | **55m 14s** | 11m 48s |
  | branch pushed | yes, at T0+9m | **none** |
  | pull requests | 0 | 0 |
  | cost | $12.05 | $1.72 |

  **What it established.** No refusal, in either session. A2 wrote in its
  own workstream file, unprompted: *"this session is running unsupervised
  (`./joharness.sh authority`: mode unsupervised, verdict VERIFIABLE)"* —
  it checked the repository instead of believing its prompt, and
  proceeded. That is the mechanism working, and the second independent
  reason the attempt-one annotation above was over-claimed.

  **What stopped it.** A2's plan, `marker-gate-needs-no-done`, declared
  `scope: joharness.sh, .agents/harness/selftest` — **entirely protocol
  text**, which this requirement's Constraints put off limits to a session
  running unattended. It implemented the fix, tested it green, ran
  `code-review --high`, then committed `Revert protocol-path edits:
  unsupervised sessions cannot make them`, wrote the complete design into
  its workstream file for a supervised session, marked itself `blocked`
  and handed off.

  Every part of that is correct. The boundary held and the session
  respected it. **The failure is upstream of both**: the queue offered an
  unsupervised fleet a plan it could never finish, and the disqualifying
  fact was in the plan's own `scope:` frontmatter the whole time. Filed as
  `queue-hides-supervised-only-plans`.

  B2 stopped at 11m48s having pushed nothing at all — no branch, no
  workstream file, no plan — against step 3's "no push, no claim". Its
  conclusion is unrecoverable.

  What attempt two did NOT show: endurance. 57 minutes is not hours, and
  the number is confounded twice — **one free plan** at T0, and that plan
  undoable by the fleet holding it. Two attempts, two different walls,
  neither of them the bullet's own question. **It stays unsatisfied.**

  **Attempt four, 2026-09-02 — the fourth RUN, counting the fan-out run of
  2026-08-30 as the first. Two sessions, one generation, 60 minutes, three
  pull requests merged, and still neither legitimate stop.** The retired
  plan `unsupervised-endurance` carried that count in a table; it is
  restated here because nothing else on `main` does.

  Run from a committed mode. PR 191 merged the flip at 18:45:56Z
  (`git log -1 --format=%cI 77bf85c`) and both sessions were created after
  it, at 18:46:16Z and 18:46:26Z (`list_sessions`, Claude Code Remote,
  read 2026-09-02), so `./joharness.sh authority` read VERIFIABLE from the
  repository rather than from a prompt.

  | | A | B |
  | --- | --- | --- |
  | wall-clock | 55m 53s | 59m 49s |
  | pull requests merged | 1 (#193) | 2 (#192, #194) |
  | reconciles with `main` | 1 | 1 |
  | generations spawned | 0 | 0 |
  | cost | $10.07 | $13.69 |

  Wall-clock and cost are `created_at` to `updated_at` and `usage.cost_usd`
  from `list_sessions`, read 2026-09-02, for
  `session_015z264uvdFedQU5bSeo8cgH` (A) and
  `session_01U5n5yq7MV37GaiAmj6szbx` (B). A later reader without that list
  can re-count the window from git and gets a shorter one: flip merge
  18:45:56Z to the last merge `ff2005c` at 19:41:17Z = **55m 21s**
  (`git log -1 --format=%cI <sha>`). Reconciles are `dc0a656` on #193's
  branch and `1cfba4c` on #194's, none on #192's
  (`git log --merges --oneline <head>`).

  T0, counted on the commit the flip merged onto: **one plan in the queue**
  (`git ls-tree 77bf85c^1 docs/plans/`) and it was claimed, so the queue was
  empty FOR A FLEET; one open requirement, this one; and
  `./joharness.sh sources` the same day — 0 failing checks, 4 unmarked
  findings, 0 gap markers, sweep NOT dry.

  **What it showed.** Both sessions ran the whole Loop unattended and merged
  their own pull requests, each reconciling with `main` first — the fan-out
  result reproduced, now on work the fleet chose rather than work it was
  handed. Both reached the **generate-work edge** on their first turn and
  wrote plans from the unmarked-findings source: `gate-review-verifier-tag`
  (B, PR 192) and `advance-feedback-baseline` (A, PR 193). That is bullet
  three measured again, and it answers two of the four caveats its own
  annotation above records: the mode was **committed**, not a session-local
  marker, and the sessions measuring it were not the session that knew the
  bullet. The other two stand — **one cycle** each, and **the second source
  produced no plan** again, because `sources` counts two detectors and the
  failing-checks one read zero, so both plans came from the same one.

  **What it did NOT show, first: endurance.** 60 minutes is one generation's
  length, which is the same quantity the three runs before it measured. The
  bullet stays unsatisfied.

  **What it did NOT show, second, and this is the run's real finding: that
  the SUPERVISED ONLY marking stops anything.** Both generated plans are
  marked — `JOHARNESS_RUN_MODE=unsupervised bash
  .agents/harness/queue-context.sh` prints `SUPERVISED ONLY: scope is all
  protocol text` for both — and both sessions edited protocol text anyway.
  B claimed `gate-review-verifier-tag` in `435b29f` at 19:10:22Z, **57
  seconds after PR 192 merged that plan to `main`** (`e1e9e3b`, 19:09:25Z),
  implemented it to a passing `ci`, and stopped only when the handover-guard
  stop hook caught it — its own commit message says so: *"Caught by the
  handover-guard stop hook, not before starting"* (`3448ab8`). A went
  further: `eb13f0d` edits `joharness.sh` by 14 lines and **reached origin**
  (`git merge-base --is-ancestor eb13f0d origin/main`), reverted afterwards
  in `0e5077a` and again in `29a66d7`. Neither session read the marking at
  claim time, and nothing makes one: PR 187 puts the label in `drain` and
  `queue-context` output, and a session that reaches the generate-work edge
  writes its own plan and claims it without passing through either.
  **Attempt two's wall was hit twice more, and one crossing was pushed.**
  The marking needs a plan it does not have, and writing it is not this
  annotation's job.

  **Why it stopped, and it is neither of the two stops.** A ended saying
  "attempt four complete"; B ended saying "queue clear, no pending work" —
  and an empty queue is this mode's TRIGGER, not its stop
  (`JOHARNESS_MODE=unsupervised ./joharness.sh drain`, 2026-09-02: "queue
  empty, 1 goal(s) open — under unsupervised that is a trigger, not a
  stop"). Each session declaring itself done is what ended generation one.
  What ended the RUN is what the plan said would end it: **no heartbeat**,
  so nothing spawned generation two. That was settled before the run, at
  zero cost and without firing anything —
  `origin/claude/gastown-review-owjgzg:docs/handover/unsupervised-endurance.md`
  r1 and r10 record ONE session's two probes: `create_trigger` refuses the
  `connectors` parameter for this organization, and without it a fired
  session carries no `mcp__*` tools; with no `gh` on the runner either, it
  cannot reach GitHub at all, so Loop step 7 is unreachable.

  **And a wall none of the four rows carries: A refused first.** Recorded
  from A's transcript during the run and NOT re-countable from the
  repository — what git anchors is only that A's first commit `1c607b7`
  landed 15m 49s after its session was created. A read `authority` as
  VERIFIABLE and called the verdict **self-referential**, because the commit
  that set the mode was written by a Claude session and merged by one. The
  objection is fair and nothing in the mechanism answers it: `authority`
  proves the claim is committed and merged through a pull request, not that
  a human is behind it. A then found work and ran the Loop, so this delayed
  rather than stopped — which is why it is written here and not as a row in
  the `what stopped it` table.

  **Residue.** The run left two SUPERVISED ONLY plans on `main`
  (`JOHARNESS_MODE=unsupervised ./joharness.sh drain`, 2026-09-02, names
  both), so the dry sweep — this mode's one reachable stop — is further away
  than it was at T0. A run that generates work it cannot finish moves its
  own successor's stop condition, and no annotation before this one said so.

- The goal is an open requirement in `docs/product/`. An unsupervised
  session at the queue edge with no open requirement stops and asks,
  exactly as a supervised one does, and says the goal is reached rather
  than going quiet.
- **Recording is always allowed. Generating is what the bound governs.**
  Directed 2026-08-31 by the requester — "we should allow to always create
  items in the queue" — amending the line this bullet first carried, which
  said a plan serving no open requirement is not generated.

  Those are two different acts, and the first draft conflated them:

  - **Recording** — a session found something and writes it down as a plan,
    a research node or an issue. Never blocked, in any mode, goal or no
    goal. Dropping a real finding is the failure, not writing it down: Loop
    step 5 says "fix them or record why not — never drop silent", and `ci`
    reds a branch that leaves one undispositioned.
  - **Generating** — a session with nothing left to do manufactures work to
    stay busy. That is what the goal bounds, and it stays bounded.

  A fleet does not fail to converge by writing down what it found. It fails
  by inventing work to remain alive.

- A plan an unsupervised session generates while a goal is open names the
  requirement it serves and the `Satisfied when` bullet it advances. One
  recorded with no goal open names neither, because there is nothing to name
  — it is a note for a human, and it does NOT restart the fleet. Otherwise
  recording would be a way to manufacture a goal, which is the circularity
  the bound closes.
- When every `Satisfied when` bullet of a requirement reads true, the next
  unsupervised session deletes the requirement file rather than inventing
  more work against it. Reaching the goal is the terminal action, not a
  state to keep working past.
- No unsupervised session writes a requirement. The goal is the human's to
  set, and a fleet that writes its own finish line has none.
- The mode has a reachable end: the source sweep goes dry. Every detector
  zero on two consecutive sweeps, queue empty, no open pull request. There
  an unsupervised session stops and says so — the one place the mode asks.
  **Reachable is now literal**: `./joharness.sh sources` states all four
  parts with a verdict (PR 160), and the detector that could never be zero is
  bounded by a baseline (PR 161). The two parts this harness cannot count —
  no `gh` on the runner, and a previous run is not a thing git holds — are
  `--open-prs <n>` and `--prev-dry`, and their ABSENCE reads `CANNOT TELL`,
  never `STOP`.
  Empty QUEUE still triggers work WHILE A GOAL IS OPEN; empty SWEEP stops
  it, and so does a satisfied goal. Ratified 2026-08-25 by the requester,
  amending this file's earlier reading that the mode had no stopping point
  at all. The goal bound above is the second of those two stops and was
  directed the same day; it reached `main` on 2026-08-31 (PR 169).
- No unsupervised session commits a change to protocol text — the paths
  `joharness.sh:protocol_paths` names, whatever they are at the time. Stated
  as one tree, this line is what a session reads to conclude everything else
  is fair game; that reading is #114.

## Constraints

- Protocol text governing a session is off limits to that session while it
  runs unattended, wherever that text lives. A session may not rewrite the
  rules it is being judged by; that edit is supervised work, always. The
  rule is the role, not the path — `joharness.sh:protocol_paths` carries its
  current mechanical expression — read it there rather than here, because a
  list restated in prose is a second copy and this one was wrong within an
  hour of being written. The session-start banner and
  `.agents/harness/handover-guard.sh` both read that one list, and `selftest.sh` fails when a tree shipping agent-instruction
  text is missing from it. Stated as a path alone this cost issue #114:
  `.claude/agents/verifier.md` became mandatory Loop step 5 protocol outside
  the one named prefix, and nothing detected an edit to the independent
  reader the merge gate leans on. Sandbox configuration (`.agents/env/`) is
  not protocol text and stays outside — a layer does not govern behavior.
  The list covers its own machinery: the entrypoint that holds it, and the
  settings file wiring the hook that reads it. A boundary excluding either is
  switched off from inside, and the old hardcoded one was self-protecting
  only by accident of where it lived.
- The exception to "not invent work" is written as an exception, gated on
  the mode, at the rule itself. A rule that quietly stops meaning what it
  says is worse than no rule.
- Unsupervised merging uses the step 7 conditions unchanged — green
  checks, zero behind main, review recorded, no open human thread. The
  mode removes the human, never the gate.
- Every source an unsupervised session may draw work from carries a
  detector command that prints a count. No detector, not a source. An
  uncountable source never reaches zero, so a mode that draws on one can
  never terminate. Measured 2026-08-25 against the closed list in
  `unsupervised-edge-work`, three of its five sources had a command that
  returns a number and two did not — "a documented rule with no test" and
  "drift between an instruction file and the code". Those two are judgment
  calls, and a literal reader always finds one more.
- A finding that unsupervised-generated work itself introduced is not a
  source finding. Without this the mode manufactures its own backlog and
  the sweep never dries.

  **The mechanism is a BASELINE, not the dedupe this bullet first
  prescribed.** Ratified 2026-08-31 by the requester, who delegated the
  decision after the research below. Dedupe against citing plans cannot work:
  a finding lives in a `## Review` section of a workstream file that step 7
  deletes, so it survives only inside a merged commit that nothing can edit,
  and **62 of the 155 unmarked findings carry no `rN:` id** — no citation
  could ever name them. The count was therefore monotonically non-decreasing
  and could never be zero, so the sweep could never be dry and the fleet
  could never stop. That is this file's own "an uncountable source never
  reaches zero" reached from the countable side. Working:
  `docs/research/unmarked-detector-unreachable.md`, answered in PR 161.

  The source is now measured from `joharness.sh:FB_SINCE`, a literal commit
  in a reviewed diff rather than state a session can write. Findings merged
  at or before it are history, not the mode's backlog — which is this
  bullet's own scope. A repo that has no such commit, a synced consumer among
  them, counts ALL of its history and says so: never blind, and never zero.
- Autonomy is bounded by a goal, not by a counter. Unsupervised mode is live
  only while at least one requirement is open; the requirement's `Satisfied
  when` is the finish line, and delete-on-satisfied is the terminus. This is
  the stopping condition, added 2026-08-25 at the requester's direction, and
  it replaces "an empty queue is a trigger for work, not a stopping point"
  from the first draft.

  **Provenance, and why it took six days.** The wording above is
  `origin/claude/unsupervised-goal`'s, PORTED rather than merged: that branch
  is 515 behind and still spells the boundary "under `.agents/harness/`",
  which `main` replaced with the role-based `protocol_paths` list (issue
  #114, PR #118). Merging it would have regressed the boundary work. Its
  session archived before it opened a pull request, and no session re-filed
  it because a requirement is the human's — the branch's own reasoning.
  Adopted 2026-08-31 on the requester's delegation ("make decisions"),
  issue #166.

- Deliberately NOT constrained, decided 2026-08-24 by the requester after
  being offered each one: no cap on work per run, no halt when main is
  red, no ban on sessions spawning sessions. A decomposing session must
  not add these back on its own judgment — propose them to the human
  instead.
