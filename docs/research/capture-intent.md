---
research: capture-intent
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/product/README.md
---

## Question

Which practices in the AI-Native SDLC Playbook's "Capture as intent.md"
lesson does `docs/product/` already have under another name, which should
joharness adopt, which does it reject with reason — and what does the
lesson's non-engineer originator hit when they write a requirement here?

The second half was ADDED mid-run, on the human's instruction ("Just do
research and usability"), in the same commit that added F11 through F13
(`git show 240a89b -- docs/research/capture-intent.md`). What that costs
is recorded under "What would settle it" rather than smoothed over.

## Echo

Human handed this repo a URL and nothing else:
`https://academy.claude.com/courses/ai-native-sdlc-playbook/capture-intent`,
lesson 2 of 14 of Anthropic's "AI-Native SDLC Playbook". The lesson defines
`intent.md` — a proto-spec the originator brainstorms with Claude, saves in a
version-controlled `intent/` folder the product owner watches, and that the
next stage consumes. joharness's counterpart is the requirement file,
`docs/product/<requirement>.md`: human-written, coarse, on `main`,
decomposed by sessions into plans. The two were designed apart.

Echo of the amended half, written when the half was added: the human is
asking whether this repo's intake is usable by the person the lesson
describes — someone who writes markdown and does not run the gates. That is
a question about what the gates DO to their file, answerable by running
them, not by reading the protocol and judging it. What rests on both
halves: whether any plan should exist to change the requirement template,
the intake route, or the product README, and whether any lesson practice
gets a recorded rejection so the next session that reads the lesson does
not re-open it.

## Sweep

`goal-directed` — every practice the ONE lesson states, each with exactly
one verdict from {convergent, adopt-candidate, reject}, plus one usability
walk of the lesson's originator through this repo's intake, measured by
running the gates on what they would write. Not the other thirteen lessons;
a "Stage 2: Design" or "Stage 6: Maintain" practice the lesson only points
at is out of scope, named where it touches a finding.

## What would settle it

For each practice: the lesson sentence stating it, the joharness rule or
mechanism covering the same ground (or none), and one verdict. A practice
with no counterpart and a concrete joharness use is an adopt-candidate; a
practice a joharness rule argues against, with its reason recorded, is a
rejection; a practice with a counterpart is convergent and NOTHING
changes — a finding that demands an edit is not convergent, whatever it
resembles.

Usability settles on the gates' own output. The two probe files are named
in advance and are not free choices: file 1 is the lesson's own example,
byte for byte, because that is what the lesson tells the originator to
write; file 2 is the repo's TEMPLATE with `priority: high`, because
`high` is the one value a requester who has seen `urgent` would guess and
the enum does not carry. Either each passes `ci` and reaches the hook, or
a gate names what broke.

**Written after, and saying so.** The practice half of this criterion
predates its method; the usability half does not — it was written in the
commit that carried F11 through F13. The research protocol requires the
criterion first, precisely so findings cannot be fitted to what was found
(`.agents/docs/research/README.md`). What limits the damage here is that
the usability verdicts are command output, re-runnable by anyone from the
Method block, not judgements. Read them as reproducible; do not read the
usability criterion as having constrained them.

## Method

Lesson text fetched by this session's page-fetch tool (`WebFetch`), whose
query is a prompt, quoted here in full as the protocol requires:

```
Reproduce the full text content of this lesson page as faithfully as
possible: every heading, paragraph, list item, checklist, example,
template, and code block. Do not summarize; transcribe.
```

Then re-grounded against the raw page:

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

That loop covers EIGHT phrases. The findings quote roughly twenty more,
which it does not cover; those were checked by the verification pass
below, not here. An apostrophe or quote mark in a phrase needs the HTML
entity (`&#x27;`) to match, which is why the eight are punctuation-free.

joharness side read on this branch: `.agents/docs/product/README.md`,
`.agents/docs/product/TEMPLATE.md`, `.agents/docs/plans/README.md`,
`.agents/docs/research/README.md`, `.agents/docs/graph.md`,
`.agents/docs/unsupervised.md`, `.agents/docs/handover/README.md`,
`.claude/commands/plan.md`, `.agents/harness/queue-context.sh`,
`.agents/scripts/sync-to-consumer.sh`, `.github/workflows/ci.yml`,
`joharness.sh`.

```bash
git grep -niE 'intent\.md|proto-spec|product owner' origin/main \
  -- '*.md' '*.sh' | wc -l
# 0 — the lesson's vocabulary is new here. The ref is load-bearing: without
# it the same command greps the worktree and returns 17, this file's own
# hits.
ls .claude/commands .claude/skills
# drain.md handover.md plan.md who.md / steward — no requester-side command
git grep -nE 'committer|%an|%ae' -- joharness.sh .agents/harness/
# one hit that is not a comment: joharness.sh:authority_commit, which
# PRINTS an author and gates nothing
```

Usability probe, run on this branch with the tree otherwise clean, then
re-run from scratch by the verification pass:

```bash
mkdir -p docs/product
# file 1: the lesson's example, byte for byte, no frontmatter
#   docs/product/claims-status-self-service.md
# file 2: TEMPLATE shape with `priority: high`
#   docs/product/claims-status-high.md
./joharness.sh ci
#   == graph lint
#     DEAD docs/product/claims-status-high.md: priority 'high' not one of: normal urgent
#   (no `edges sound` line: the section prints the red instead of the counts)
#   ci: FAIL          exit 1
rm docs/product/claims-status-high.md; ./joharness.sh ci
#   edges sound (0 plans, 1 research, 1 workstreams, 1 requirements)
#   ci: pass          exit 0
rm docs/product/claims-status-self-service.md; rmdir docs/product
```

The hook's own output, observed rather than read from code — file 1 put on
a dangling commit over `origin/main` (no ref written), the hook pointed at
it through the variable it already honours:

```bash
HANDOVER_BASE_BRANCH=<probe-sha> bash .agents/harness/queue-context.sh
# Requirements without plans — planning outranks the plan queue:
#   docs/product/claims-status-self-service.md  [normal, UNPLANNED — decompose into plans]
```

Both `session-start` and `./joharness.sh graph` read `origin/main` when it
exists (`.agents/harness/queue-context.sh` ref loop; `joharness.sh:base_ref`,
used by `cmd_graph`), so a requirement that is uncommitted or lives only on
a branch is invisible to both: with the probe files in the worktree, both
greps printed nothing.

## Findings

- **F1 — The artifact is the same artifact.** Lesson: `intent.md` "contains
  what is wanted, why, and under which constraints", sections Problem /
  Proposed outcome / Affected users and systems / Constraints / Open
  questions. joharness: `docs/product/TEMPLATE.md` — Goal ("What product
  needs and why. Requester's words"), Satisfied when, Constraints;
  README: "Human writes. Coarse." Both are markdown, version-controlled,
  human-owned, in the requester's terms, consumed by the next stage
  unchanged. Verdict: convergent. Two lesson sections have no slot — see
  F2 and F3.

- **F2 — Open questions have no slot in a requirement.** Lesson example
  ends `## Open questions` ("Do third-party loss adjusters need access
  too?"). joharness's TEMPLATE has none, and
  `.agents/docs/research/README.md` says "Sessions file questions, never
  requirements" — the research node is the session's tool. A human's open
  question today lands in prose inside Goal, where the decomposing session
  has to notice it. The routing exists one hop later: a plan carrying
  `research: <stem>` is blocked while that question file exists
  (`.agents/docs/research/README.md`, Edges; `.agents/harness/AGENTS.md`
  step 2 — NOT `plans/README.md`, which never mentions the edge). So a
  requirement's open question is what a session should turn into a
  research node before planning. Verdict: adopt-candidate — an
  `## Open questions` section in `.agents/docs/product/TEMPLATE.md`, and
  one README line routing each into a node the plan blocks on. No code.

- **F3 — Affected users and systems has no requirement-level slot, and
  the nearest thing is hand-written too.** Lesson lists them in the intent
  ("Claims handlers, portal team, claims-core API"). joharness's TEMPLATE
  says "Not implementation" and has no such section; the machine-readable
  form arrives one level down, in a plan's `scope:`, which the queue hook
  proves disjoint. Note against the easy reading: `scope:` is itself a
  HAND-WRITTEN path list the repo accepts, "only as true as it is
  complete", kept because it "already rots visibly in review"
  (`.agents/docs/plans/README.md`). So the reason a requirement carries no
  path list is not that hand-written lists rot — this repo takes that
  trade knowingly — it is that the requirement is written before anyone
  knows the paths. Verdict: convergent, at a different level; the
  requester names people and systems in Goal prose, which no rule
  mandates and nothing stops.

- **F4 — Author, timestamp and status: git, not the body.** Lesson
  governance: "The evidence is the committed `intent.md`, which lists the
  author, the timestamp, and the full revision history. It's logged in the
  Git history" — convergent with "Provenance = commits. Never hand-write
  time or source into a file" (`.agents/docs/graph.md`, Rules). But the
  lesson's example ALSO writes `Author: J. Ortiz (claims operations).
  Status: draft.` into the body. joharness has no status field on a
  requirement or a plan by design: "field discipline fails exactly when
  someone hurries" (`.agents/docs/plans/README.md`, Lifecycle), and a
  first merge broke the weaker version of that rule "in minutes"
  (`.agents/docs/handover/README.md`, Graduation). Verdict: reject the
  in-body author and status line, with that reason; the lesson's own
  governance paragraph already agrees the record is git.

- **F5 — Accept has a path, reject has none.** Lesson: "the accept or
  reject decision that sends the intent into Stage 2: Design is recorded
  as the merge or the closing review". joharness: a requirement enters by
  landing on `main` ("direct or PR — human's call"), the hook flags it
  UNPLANNED, and the decomposition pull request is the accept. Reject is
  nowhere in `.agents/docs/product/README.md`, which documents Add,
  Unplanned and Satisfied and stops. Delete-on-done is already the state
  model, so the missing sentence is one line — and a requirement nobody
  wants, left standing, is queue work forever. Verdict: adopt-candidate
  (a finding that demands an edit is not convergent), the sentence being
  "reject = delete the file".

- **F6 — Repeat processes as skills; the requester has none.** Lesson:
  "Repeat processes are encoded via skills"; the template "can be encoded
  as a skill set up by a technical team member and signed off by a lead";
  Claude "asks the questions an analyst would ask: scope, users,
  constraints, and what success looks like". joharness encodes the SESSION
  side — `/plan`, `/handover`, `/drain`, `/who` — and nothing for the
  person writing a requirement. Verdict: adopt-candidate — a
  `/requirement` command that interviews the requester in their words and
  writes `docs/product/<name>.md` from the TEMPLATE, the human committing.
  Two constraints the building plan inherits, settled here rather than
  deferred: `.claude/commands` is in the sync engine's `DIRS`
  (`.agents/scripts/sync-to-consumer.sh`), so it ships to every consumer;
  and it is inside `GLOSSARY_PATHS` and caveman's "command prompts"
  scope, so requester-facing prose there is still gated house style.

- **F7 — Home for intent: a folder in the product repo.** Lesson: "the
  simplest home is an `intent/` folder in the product repo. This setup
  keeps the artifact chain next to the code derived from it. A dedicated
  intent repo is only worth the overhead when intent spans many
  repositories". joharness: `docs/product/` in each consumer, beside the
  plans and the code. The lesson points at a "Legacy systems" section in
  Stage 3 for how this home relates to a Jira or requirements tool that
  already holds the record; that lesson is out of this sweep, and
  joharness has no such bridge today. Verdict: convergent.

- **F8 — Non-engineers commit through a connector.** Lesson: "a connector
  to the version-control system (e.g., GitHub) lets Claude commit Markdown
  files on their behalf from claude.ai or Cowork". joharness's README
  already allows "direct or PR — human's call". No gate reads commit
  authorship: the one non-comment hit for `%an` in the harness is
  `joharness.sh:authority_commit`, which prints an author and gates
  nothing (command in Method). Verdict: convergent; nothing to add.

- **F9 — A detector must not write the requirement.** Lesson: intent "can
  enter through different routes ... a ticket is filed, or an incident is
  surfaced via an alert", and "regardless of whether the intent originates
  from an event trigger or a person ... the product owner reviews and
  corrects the agent-written `intent.md` before it is committed".
  joharness's matching rule is mode-scoped and was nearly miscited: "No
  unsupervised session writes a requirement, and `ci` reds the branch that
  does" (`.agents/docs/unsupervised.md`, Bounds;
  `joharness.sh:lint_requirement_writes`, which returns early under
  supervised with "a requirement is a human's to write"). So under
  supervised nothing GATES a session that writes one — the human between
  the alert and the artifact is convention there, mechanism only
  unsupervised. The plan-side rule, "no session in any mode writes a plan
  from a detector" (`.agents/docs/plans/README.md`), is the same doctrine
  one level down. Verdict: reject a detector writing the requirement
  itself, with that reason recorded; the lesson's human-in-the-loop is
  what joharness relies on under supervised, and it is worth knowing that
  is convention rather than a gate.

- **F10 — Measures: one is countable here, one is not.** Lesson leading
  indicator: "Time from first conversation to a committed `intent.md`,
  read from Git history". The conversation's start is not in git, so this
  repo cannot count it. Lagging: "survival rate ... the share of
  `intent.md` files that the product owner accepts into Stage 2: Design
  rather than closes", and "the changes to `intent.md` made after the
  first `spec.md` commit for the same change". The second IS countable
  from git alone: commits touching `docs/product/<r>.md` after the first
  commit adding a plan whose `requirement:` names it. The precedent is
  not against it — `feedback` and `scorecard` already count from history
  at read time and report without gating (`.agents/docs/graph.md`). What
  the repo forbids is a STORED number and a second view of the queue
  (`.agents/docs/research/README.md`, "Not an index"), neither of which a
  read-time count is. Verdict: adopt-candidate, read-time only, and last
  in the queue below because nobody has asked what the number is for.

### Usability — the lesson's originator meets `docs/product/`

The lesson's persona is a non-engineer: "No formal language is required",
and "contributors without Git experience don't need to use Git directly".
Four findings from walking that persona through joharness's intake. Probe
commands and their output are in Method.

- **F11 — The lesson's `intent.md` pastes in as-is and is scheduled.**
  File 1, no frontmatter, lesson headings: `ci: pass`, `1 requirements`
  counted. The hook then lists it as
  `docs/product/claims-status-self-service.md  [normal, UNPLANNED —
  decompose into plans]` — its PATH, not its stem, priority defaulted
  because a file whose first line is not `---` yields no frontmatter at
  all. Neither reader tests for frontmatter; both exclude only
  `TEMPLATE.md`, `README.md` and `VISION.md`, so a requester who names
  their file `README.md` gets silence instead of a queue entry. Verdict:
  convergent, and stronger than F1 alone said — the template is a
  convenience for the decomposing session, not a gate on intake.

- **F12 — One guessed word reds the base branch for everyone.** File 2,
  `priority: high`: `DEAD ... priority 'high' not one of: normal urgent`,
  `ci: FAIL`. Asymmetric with F11: an absent key is a silent `normal`
  (`joharness.sh:lint_enum` returns 0 on an empty value), a guessed one is
  red. A requirement is written directly on `main` by a person who never
  runs `ci`, and `ci` runs on push to `main` (`.github/workflows/ci.yml`),
  so the red lands on the base branch — and `lint_nodes` walks the whole
  worktree rather than a diff, so every later pull request run is red too,
  for a file it never touched, until someone fixes `main`. Step 7 needs
  green checks, so it blocks merges meanwhile. Verdict: adopt-candidate,
  and NOT the obvious one: reading an unknown value as `normal` would
  silently downgrade an urgent requirement, which is the failure this repo
  reds elsewhere on purpose — `joharness.sh` records the PR 140 incident
  where a value that "lints clean and renders as nothing" cost a plan, and
  reds a malformed `issue:` because "a claim that looks accepted and
  silently is not" is worse. So keep the red and move the guard earlier:
  the TEMPLATE comment naming the two values, and F6's command validating
  before the human commits.

- **F13 — The vocabulary is documented, one hop away, in prose written
  for sessions.** `.agents/docs/product/TEMPLATE.md`'s comment gives the
  path — "Copy to docs/product/<requirement>.md, on main. Protocol:
  README.md here" — and that README names both keys and both values:
  "Frontmatter `requirement`, `priority` (`normal` | `urgent`)". So the
  information exists; the earlier draft of this finding said it did not,
  and was wrong. What is true is the register and the route: the file is
  caveman-compressed instruction text for agents, under a dotted
  directory, reached by a link inside an HTML comment in a template the
  originator has to find first. Nothing routes them to it, and F12 is what
  a wrong guess costs. Verdict: adopt-candidate, the same one as F6 — the
  interview carries the vocabulary to the requester instead of asking them
  to read the protocol.

- **F14 — Who may write to the intent home is unanswered here.** Lesson:
  "A technical team member needs to stand up the intent home and decide
  who can write to it, since many contributors will come from across the
  organization." joharness says a requirement lands on `main` "direct or
  PR — human's call" and says nothing about who may push. The remedy is a
  forge setting, the same shape as the merge-method gap
  `.agents/docs/product/README.md` already records as prose a rule nothing
  in this repo can hold. Verdict: adopt-candidate — one sentence in that
  README pointing write access at the forge, beside the bullet that
  already makes the same admission for merge methods.

## Consequence for the queue

No existing plan changes. Six adopt-candidates, none filed as a plan by
this research — the human decides which are wanted:

1. Requirement `priority`: keep the red, add the two values to the
   TEMPLATE comment (F12). One line, haiku-sized, and the one measured
   defect here.
2. `## Open questions` in `.agents/docs/product/TEMPLATE.md` plus the
   README line routing each into a research node (F2), and F5's
   "reject = delete the file" sentence in the same edit.
3. A `/requirement` command for the requester side (F6, F13): interview
   in the requester's words, vocabulary validated before the commit,
   file written from the TEMPLATE. sonnet — the interview shape is the
   unclear edge, and the command ships to every consumer.
4. One sentence on write access, beside the merge-method bullet (F14).
5. Post-plan edit count on requirement files (F10). Read-time only, and
   only behind a human saying what the number is for.

Two rejections recorded for the graduation: the in-body author and status
line (F4), and detector-written requirements (F9), the second carrying the
fact that supervised mode gates it by convention rather than by code.

## Verification

Three passes read this node from contexts that did not write it, spawned
at the branch's escalated opus tier: a `.claude/agents/verifier.md`
grounding pass, a does-it-reproduce pass that re-ran every probe from
scratch, and an adversarial pass on verdict soundness. Their findings and
dispositions are in this branch's workstream file `## Review`, retired with
the branch and recoverable by the command in the pull request body. What
each pass could NOT check: whether any lesson practice works in an
organization — the lesson publishes no measurement, and all three passes
read the page, not a team.

An earlier revision of this section claimed no reader could be spawned
because "no session may re-spawn one unasked". No such rule exists
(`git grep -niE 're-spawn|respawn|unasked'` finds only this file);
`.agents/harness/AGENTS.md` step 5 says the opposite — every depth spawns
the verifier. The sentence was an invention covering a gap, and it is
recorded here rather than deleted quietly, because that is the class of
error this section exists to catch.

- F1 GROUNDED — lesson quote and both TEMPLATE and README quotes verbatim.
- F2 GROUNDED after correction — the blocking rule was cited to
  `plans/README.md`, which never mentions the `research:` edge (`grep -c`
  = 0); re-cited to `research/README.md` Edges and step 2.
- F3 GROUNDED after correction — the original rested on a rot rule about
  DERIVED state and missed the repo's own hand-written `scope:`; the
  finding now carries the counter-example and drops an invented
  "on purpose".
- F4 GROUNDED — three lesson strings and three joharness rules verbatim.
- F5 GROUNDED after regrade — the verdict was convergent while the finding
  demanded a new sentence, which this node's own settle rule forbids.
- F6 GROUNDED, and one deferred question settled: `.claude/commands` is in
  the sync engine's `DIRS` and in `GLOSSARY_PATHS`.
- F7 GROUNDED — lesson sentence verbatim; an unsourced "none is planned"
  was dropped.
- F8 GROUNDED after correction — the absence claim now carries the grep
  and names the one reader of authorship.
- F9 GROUNDED after correction — both original quotes were about PLANS;
  the requirement-side rule is `unsupervised.md` Bounds, and it is
  mode-scoped, which changes the finding from "convergent" to a rejection
  plus a named convention. The double verdict is gone.
- F10 GROUNDED after correction — "trust counted numbers" forbids written
  numbers, not measurement, and `feedback` and `scorecard` are the
  precedent the original missed.
- F11 GROUNDED, hook output now OBSERVED — the reproduce pass ran
  `queue-context.sh` against a dangling commit carrying the probe file.
  Two overstatements fixed: it prints the path, not the stem, and
  `TEMPLATE`, `README` and `VISION` are excluded.
- F12 GROUNDED, severity corrected upward — the worktree-wide lint reds
  later pull request runs too, and the proposed fix was reversed after the
  adversarial pass named the silent-downgrade rules it collided with.
- F13 UNGROUNDED as first written, corrected — its central claim that
  nothing tells the originator the path or the keys is false; both are
  documented, and the finding now says what is actually wrong.
- F14 GROUNDED — lesson quote verbatim; raised by the adversarial pass as
  a practice the sweep had missed.
- WEAK (cross-cutting) — every claim about what the lesson's practices
  achieve in an organization.

## Graduates to

`.agents/docs/product/README.md`, Requirements section — the file that owns
the requirement's shape and intake, and the one file this graduation may
touch besides deleting this node (`.agents/docs/research/README.md`,
"Not a plan"). The two rejections land there as their own short paragraph
POINTING at the rules they protect — F4's in `.agents/docs/graph.md` and
`.agents/docs/plans/README.md` Lifecycle, F9's in
`.agents/docs/unsupervised.md` Bounds — rather than restating them, since
`graduates:` is single-valued and a second copy of a rule rots against the
first. Without that paragraph the next reader of the lesson re-opens both.
The adopt-candidates land as plans only if the human queues them.
