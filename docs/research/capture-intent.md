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
joharness adopt, which does it reject with reason — and what does the
lesson's non-engineer originator hit when they write a requirement here?

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
of convergent (already have) / adopt-candidate / reject, plus one usability
walk of the lesson's originator through this repo's intake, measured by
running the gates on what they would write. Not the other thirteen lessons; a "Stage 2: Design" or "Stage 6: Maintain" practice the
lesson only points at is out of scope, named where it touches a finding.

## What would settle it

For each practice: the lesson sentence stating it, the joharness rule or
mechanism covering the same ground (or none), and one verdict. Settled
either way. A practice with no counterpart and a concrete joharness use is
an adopt-candidate; a practice a joharness rule argues against, with its
reason recorded, is a rejection; a practice with a counterpart is
convergent and nothing changes. Usability settles on the gates' own output:
a file the originator would plausibly write either passes `ci` and reaches
the hook, or one of them names what broke. Unsettleable here: whether the lesson's
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

Usability probe, run on this branch with the tree otherwise clean — the
lesson's example `intent.md` pasted verbatim under `docs/product/`, then a
TEMPLATE-shaped requirement carrying the one word a requester would guess:

```bash
mkdir -p docs/product
# file 1: the lesson's example, byte for byte, no frontmatter
#   docs/product/claims-status-self-service.md
# file 2: TEMPLATE shape with `priority: high`
#   docs/product/claims-status-high.md
./joharness.sh ci
#   DEAD docs/product/claims-status-high.md: priority 'high' not one of: normal urgent
#   ci: FAIL
rm docs/product/claims-status-high.md; ./joharness.sh ci
#   edges sound (0 plans, 1 research, 1 workstreams, 1 requirements)
#   ci: pass
./joharness.sh session-start | grep -i 'requirement\|UNPLANNED'   # nothing
./joharness.sh graph | grep 'req:'                                  # nothing
```

The last two read `origin/main` (`.agents/harness/queue-context.sh`, ref
selection; `joharness.sh:cmd_graph` via `base_ref`), so an uncommitted or
branch-local requirement is invisible to both by design — how the hook
WOULD list file 1 is read from `queue-context.sh` (Requirements tier:
stem from the filename, `${rprio:-normal}`), not observed.

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

### Usability — the lesson's originator meets `docs/product/`

The lesson's persona is a non-engineer ("No formal language is required";
contributors "don't need to use Git directly"). Three findings from
walking that persona through joharness's intake, probe commands in Method.

- **F11 — The lesson's `intent.md` pastes in as-is and is scheduled.**
  File 1, no frontmatter, lesson headings: `ci: pass`, `1 requirements`
  counted; the hook would list it `UNPLANNED — decompose into plans` under
  its filename with priority `normal` (read from `queue-context.sh`,
  Requirements tier). So the shape barrier for the requester is nil: any
  markdown file under `docs/product/` on `main` is a requirement. Verdict:
  convergent, and stronger than F1 said — F2's template slot is a
  convenience for the decomposing session, not a gate on intake.

- **F12 — One guessed word reds `main` for everyone.** File 2,
  `priority: high`: `DEAD ... priority 'high' not one of: normal urgent`,
  `ci: FAIL`. A requirement is written directly on `main` ("direct or PR
  — human's call", `.agents/docs/product/README.md`) by a person who
  never runs `ci`, so the red lands on the base branch and bills the next
  session. Asymmetric with F11: omitting the key is a silent `normal`
  (`joharness.sh:lint_enum` returns 0 on empty), guessing it is DEAD. The
  vocabulary is two words and the guess is the natural one. Verdict:
  adopt-candidate — either the requirement's `priority` lint warns and
  reads unknown as `normal` (the requirement is product, not protocol,
  and `lint_requirement_writes` already treats it as the human's), or the
  TEMPLATE comment says "omit unless `urgent`". Smallest real defect this
  research found.

- **F13 — The only requester-facing text points at a protocol written
  for sessions.** `.agents/docs/product/TEMPLATE.md`'s comment: "Copy to
  docs/product/<requirement>.md, on main. Protocol: README.md here." That
  README is caveman style for agents — "decompose", "hook", "edge",
  "queue" — and lives under a dotted directory. Nothing tells the
  lesson's originator the path, the two keys, or that a pull request
  hides the requirement from the hook until it merges (Method, last
  paragraph). The lesson's answer is "a skill set up by a technical team
  member and signed off by a lead", which is F6's `/requirement` command
  with the interview and the vocabulary inside it. Verdict: folds into
  F6; raises it from nice-to-have to the fix for F12 and this together.

## Consequence for the queue

No existing plan changes. Four adopt-candidates, none filed as a plan by
this research — the human decides they are wanted:

1. Requirement `priority` lint: warn and read as `normal`, or TEMPLATE
   says "omit unless `urgent`" (F12). One `lint_enum` call or one comment
   line; haiku-sized, and the one measured defect here.
2. `## Open questions` in `.agents/docs/product/TEMPLATE.md` plus the
   README line routing each into a research node (F2, F5's "reject =
   delete" sentence in the same edit). Docs only; haiku-sized.
3. A `/requirement` command for the requester side (F6, F13): interview
   in the requester's words, vocabulary validated, file written from the
   TEMPLATE. sonnet: the interview shape is the unclear edge.
4. Post-plan edit count on requirement files (F10). Only behind a human
   asking for the number.

Two rejections recorded for the graduation: the in-body author/status line
(F4) and detector-written requirements (F9).

## Verification

Not done from a second context. The independent reader was spawned and the
human stopped it mid-run ("Just do research and usability"), and no session
may re-spawn one unasked. What stands in for it, and what it is not:

- Every lesson quote in F1–F10 and F13 was re-grounded mechanically against
  the raw page (Method, first block: each phrase count 1). A grep proves the
  words are on the page, not that the finding reads them right.
- F11 and F12 rest on commands whose output is in Method, re-runnable by
  anyone with the tree.
- No joharness citation was re-read by anyone but the writer.

So every claim below is WEAK — self-grounded, unread — until the graduating
pull request, or a later session, runs the reader the research protocol
requires (`.agents/docs/research/README.md`, Verification is not optional)
and upgrades or refutes each line.

- F1 WEAK — self-grounded only
- F2 WEAK — self-grounded only
- F3 WEAK — self-grounded only
- F4 WEAK — self-grounded only
- F5 WEAK — self-grounded only
- F6 WEAK — self-grounded only; absence claim is one `ls`
- F7 WEAK — self-grounded only
- F8 WEAK — self-grounded only
- F9 WEAK — self-grounded only
- F10 WEAK — self-grounded only
- F11 WEAK — command output in Method; hook behaviour read from code, not
  observed
- F12 WEAK — command output in Method
- F13 WEAK — self-grounded only
- WEAK (cross-cutting) — whether any lesson practice works in an
  organization; the lesson gives no measurement and this sweep reads the
  page, not a team.

## Graduates to

`.agents/docs/product/README.md`, Requirements section — the file that owns
the requirement's shape and intake. The two rejections need their reasons
beside the rule they protect, or the next reader of the lesson re-opens
them; the adopt-candidates land as plans only if the human queues them.
