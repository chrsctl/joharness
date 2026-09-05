---
research: capture-intent
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/docs/product/README.md
---

## Question

Which practices in the AI-Native SDLC Playbook's "Capture as intent.md"
lesson does `docs/product/` already have under another name, which should
joharness adopt, and which does it reject with reason?

## Echo

Human handed this repo a URL and nothing else:
`https://academy.claude.com/courses/ai-native-sdlc-playbook/capture-intent`,
lesson 2 of 14 of Anthropic's "AI-Native SDLC Playbook". The lesson defines
`intent.md` — a proto-spec the originator brainstorms with Claude, saves in a
version-controlled `intent/` folder the product owner watches, and that the
next stage consumes. joharness's counterpart is the requirement file,
`docs/product/<requirement>.md`: human-written, coarse, on `main`,
decomposed by sessions into plans. The two were designed apart. What rests
on the answer: whether any plan should exist to change the requirement
template, the intake route, or the product README — and whether any lesson
practice gets a recorded rejection so the next session that reads the
lesson does not re-open it.

## Sweep

`goal-directed` — every practice the ONE lesson states, each with a verdict
of convergent (already have) / adopt-candidate / reject. Not the other
thirteen lessons; a "Stage 2: Design" or "Stage 6: Maintain" practice the
lesson only points at is out of scope, named where it touches a finding.

## What would settle it

For each practice: the lesson sentence stating it, the joharness rule or
mechanism covering the same ground (or none), and one verdict. Settled
either way. A practice with no counterpart and a concrete joharness use is
an adopt-candidate; a practice a joharness rule argues against, with its
reason recorded, is a rejection; a practice with a counterpart is
convergent and nothing changes. Unsettleable here: whether the lesson's
practices work in an organization — the lesson gives no measurement, and
this sweep reads the page, not a team running it.

## Method

```bash
curl -sSL -o lesson.html \
  https://academy.claude.com/courses/ai-native-sdlc-playbook/capture-intent
# 200, 63381 bytes
for p in 'Repeat processes are encoded via skills' 'survival rate' \
  'product owner reviews and corrects' 'Author: J. Ortiz' 'intent/' \
  'first conversation to a committed' 'made after the first' \
  'connector to the version-control system'; do
  printf '%-45s %s\n' "$p" "$(grep -c -- "$p" lesson.html)"
done
# every phrase: 1
```

Lesson text read whole through the session's page fetch tool, prompted
"Reproduce the full text content of this lesson page ... transcribe", then
each quoted phrase re-grounded against the raw HTML with the loop above.
joharness side read on this branch: `.agents/docs/product/README.md`,
`.agents/docs/product/TEMPLATE.md`, `.agents/docs/plans/README.md`,
`.agents/docs/research/README.md`, `.agents/docs/graph.md` (Rules),
`.agents/docs/handover/README.md` (Graduation), `.claude/commands/plan.md`,
`.agents/harness/queue-context.sh` (UNPLANNED).

```bash
git grep -niE 'intent\.md|proto-spec|product owner' -- '*.md' '*.sh'
# 0 hits on origin/main: the lesson's vocabulary is new here
ls .claude/commands .claude/skills
# drain.md handover.md plan.md who.md / steward — no requester-side command
```

## Findings

- **F1 — The artifact is the same artifact.** Lesson: `intent.md` "contains
  what is wanted, why, and under which constraints", sections Problem /
  Proposed outcome / Affected users and systems / Constraints / Open
  questions. joharness: `docs/product/TEMPLATE.md` — Goal ("what product
  needs and why. Requester's words"), Satisfied when, Constraints;
  README: "Human writes. Coarse." Both are markdown, version-controlled,
  human-owned, in the requester's terms, consumed by the next stage
  unchanged. Verdict: convergent. Two lesson sections have no slot — see
  F2 and F3.

- **F2 — Open questions have no slot in a requirement.** Lesson example
  ends `## Open questions` ("Do third-party loss adjusters need access
  too?"). joharness TEMPLATE has none, and `.agents/docs/research/README.md`
  says "Sessions file questions, never requirements" — the research node
  is the session's tool. A human's open question today lands in prose
  inside Goal, where the decomposing session has to notice it. The routing
  already exists one hop later: a plan naming `research:` is blocked while
  the question is open (`.agents/docs/plans/README.md`, Lifecycle), so a
  requirement's open question is exactly what a session should turn into
  a research node before planning. Verdict: adopt-candidate, smallest in
  this file — an `## Open questions` section in
  `.agents/docs/product/TEMPLATE.md`, and one README line saying the
  decomposing session files each as a research node and blocks the plan on
  it. No code.

- **F3 — Affected users and systems is the plan's `scope:`, derived.**
  Lesson lists them in the intent ("Claims handlers, portal team,
  claims-core API"). joharness puts the paths a plan touches in the plan's
  `scope:` frontmatter, written by the session, proved disjoint by the
  queue hook; the requirement says "Not implementation". Verdict:
  convergent, at a different level on purpose: the human names people and
  systems in Goal prose if they matter, and the machine-readable form is
  the session's to derive, because a human-written path list is the
  stored copy that rots (`.agents/docs/graph.md`, Rules).

- **F4 — Author, timestamp and status: git or the file body.** Lesson
  governance: "The evidence is the committed `intent.md`, which lists the
  author, the timestamp, and the full revision history. It's logged in the
  Git history" — convergent with "Provenance = commits. Never hand-write
  time or source into a file" (`.agents/docs/graph.md`). But the lesson's
  example ALSO writes `Author: J. Ortiz (claims operations). Status:
  draft.` into the body. joharness has no status field on a requirement
  or a plan by design: "field discipline fails exactly when someone
  hurries" (`.agents/docs/plans/README.md`, Lifecycle), and a first merge
  broke the weaker rule within minutes (`.agents/docs/handover/README.md`,
  Graduation). Verdict: reject the in-body author/status line with that
  reason; the lesson's own governance paragraph already agrees the record
  is git.

- **F5 — Accept or reject is the merge or the closed review; here it is
  file existence.** Lesson: "the accept or reject decision that sends the
  intent into Stage 2: Design is recorded as the merge or the closing
  review". joharness: a requirement enters by landing on `main` ("direct
  or PR — human's call"), the hook flags it UNPLANNED
  (`.agents/harness/queue-context.sh`), and the decomposition PR is the
  accept. Reject has no named path: the human deletes the file. Verdict:
  convergent, one gap worth a sentence — the product README should say
  "reject = delete the file", since delete-on-done is already the state
  model and an unwanted requirement left standing is queue work forever.

- **F6 — Repeat processes as skills; the requester has none.** Lesson:
  "Repeat processes are encoded via skills"; the template "can be encoded
  as a skill set up by a technical team member"; Claude "asks the
  questions an analyst would ask: scope, users, constraints, and what
  success looks like". joharness encodes the SESSION side — `/plan`,
  `/handover`, `/drain`, `/who` — and nothing for the person writing a
  requirement (`ls .claude/commands .claude/skills`). Verdict:
  adopt-candidate — a `/requirement` command that interviews the requester
  in their words and writes `docs/product/<name>.md` from the TEMPLATE,
  the human committing. Ships to consumers only if `.claude/commands/` is
  in the sync engine's lists; the plan that builds it must check
  `.agents/scripts/sync-to-consumer.sh` rather than assume.

- **F7 — Home for intent: a folder in the product repo.** Lesson: "the
  simplest home is an `intent/` folder in the product repo. This setup
  keeps the artifact chain next to the code derived from it. A dedicated
  intent repo is only worth the overhead when intent spans many
  repositories". joharness: `docs/product/` in each consumer, beside the
  plans and the code; no cross-repo queue exists and none is planned.
  Verdict: convergent.

- **F8 — Non-engineers commit through a connector.** Lesson: "a connector
  to the version-control system (e.g., GitHub) lets Claude commit Markdown
  files on their behalf from claude.ai or Cowork". joharness's README
  already allows "direct or PR"; nothing in the harness cares which client
  made the commit. Verdict: convergent; nothing to add.

- **F9 — Event-triggered intake.** Lesson: intent "can enter through
  different routes ... a ticket is filed, or an incident is surfaced via
  an alert", and "regardless of whether the intent originates from an
  event trigger or a person ... the product owner reviews and corrects the
  agent-written `intent.md` before it is committed". joharness keeps the
  human on the requirement and routes machine-originated asks through the
  other door: "Issues stay the front door for humans" and bugs
  (`.agents/docs/plans/README.md`), and "no session in any mode writes a
  plan from a detector". Verdict: convergent in outcome — both keep a
  human between the alert and the committed artifact — through a
  different door. Reject the variant where a detector writes the
  requirement itself: that is the detector-writes-plan rule one level up,
  with the same reason.

- **F10 — Measures: one is countable here, one is not.** Lesson leading
  indicator: "Time from first conversation to a committed `intent.md`,
  read from Git history". The conversation start is not in git, so
  joharness cannot count it and does not write it (Trust counted numbers,
  root `AGENTS.md`). Lagging: "survival rate ... the share of `intent.md`
  files that the product owner accepts into Stage 2: Design rather than
  closes", and "the changes to `intent.md` made after the first `spec.md`
  commit for the same change". The second IS countable from git alone:
  commits touching `docs/product/<r>.md` after the first commit adding a
  plan whose `requirement:` names it. Verdict: adopt-candidate only as a
  read-time count, never a stored one — same doctrine as `feedback`, which
  counts from merge history at read time. Not filed as a plan here: a
  metric nobody asked for is a dashboard (`.agents/docs/research/README.md`,
  "Not an index").

## Consequence for the queue

No existing plan changes. Three adopt-candidates, none filed as a plan by
this research — the human decides they are wanted:

1. `## Open questions` in `.agents/docs/product/TEMPLATE.md` plus the
   README line routing each into a research node (F2, F5's "reject =
   delete" sentence in the same edit). Docs only; haiku-sized.
2. A `/requirement` command for the requester side (F6). sonnet: the
   interview shape is the unclear edge.
3. Post-plan edit count on requirement files (F10). Only behind a human
   asking for the number.

Two rejections recorded for the graduation: the in-body author/status line
(F4) and detector-written requirements (F9).

## Verification

Checked by a spawned verifier subagent that re-fetched the lesson page
itself and re-read every joharness citation on this branch; it did not
write the findings above. Its result and disposition: this branch's
workstream file `## Review`.

- F1 GROUNDED
- F2 GROUNDED
- F3 GROUNDED
- F4 GROUNDED
- F5 GROUNDED
- F6 GROUNDED
- F7 GROUNDED
- F8 GROUNDED
- F9 GROUNDED
- F10 GROUNDED
- WEAK (cross-cutting) — whether any lesson practice works in an
  organization; the lesson gives no measurement and this sweep reads the
  page, not a team.

## Graduates to

`.agents/docs/product/README.md`, Requirements section — the file that owns
the requirement's shape and intake. The two rejections need their reasons
beside the rule they protect, or the next reader of the lesson re-opens
them; the adopt-candidates land as plans only if the human queues them.
