---
plan: human-answers-on-github
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/commands/clerk.md, .claude/commands/scout.md, .claude/commands/manager.md, .agents/docs/manager-reference.md, .agents/docs/orchestrated.md, .agents/docs/orchestrator-reference.md, .agents/docs/feedback.md, .agents/harness/AGENTS.md, .agents/harness/selftest/orchestrated.sh, README.md
---

## Goal

A human reads a question and answers or approves it, on GitHub, with one
gesture, whoever asked. Today there are four ways of saying yes (scout
`approved` re-applied after every revision; a bare-number reply plus removing
`human-review` on a clerk HUMAN or NARROWER issue; removing `human-review`
on a manager pull request held at merge; an answer typed into an
orchestrator's turn for a manager block), and the natural gesture fails
silently: gx #1391 carried `approved` and `human-review` together, the clerk
skipped it, and it moved only because the maintainer answered inside a clerk
session (gx PR #1418), after which the clerk asked them to remove
`human-review` by hand. Requester's decision (2026-11-10): `human-review`
stays the one hold label; no new label.

The protocol to build. Its home is `.agents/docs/orchestrated.md` Bounds
(new paragraph "A human's answer"); every other file points there.

1. **Inbox.** Two GitHub filters: `label:human-review` (questions and
   freezes) and `label:scout -label:approved is:open` (scout proposals,
   unchanged from today). README names both.
2. **A question.** An agent that needs a human, in the SAME action that
   applies `human-review`, posts ONE comment whose first line opens
   `decision needed:` (the clerk: first line `clerk: <VERDICT>`, second line
   `decision needed:`, so the clerk's prefix rule and one-comment-per-pass
   rule hold). Body: what is decided (1-2 lines), the evidence, 2 to 4
   numbered options with one `(recommended)`, and the closing line "approve
   = the recommended option; or reply with a number or your own answer".
   Before posting it, the agent removes `approved` from that issue or pull
   request if present, so any `approved` read later was applied after the
   question (a label carries no time through the MCP tools: clerk.md, THE
   SCOUT GATE).
3. **An OPEN question** = `human-review` on the item AND a `decision needed:`
   comment on it with the Claude Code footer by an author with write access,
   and no LATER comment carrying an `answered:` line (an `answered:` line
   answers only questions in earlier comments, never one in its own
   comment). `human-review` with no open question is a
   FREEZE: only a human removes it; no agent posts a question onto it or
   removes it.
4. **The answer** to an open question, read in this order:
   1. the newest COUNTING comment newer than the question (author gate and
      footer rule of clerk.md §2): a bare number selects that option, any
      other text is the decision as written;
   2. else the label `approved`: the recommended option;
   3. else none: still waiting.
   No agent ever applies `approved`. A footed comment answers nothing.
   Known limit, as today: every session posts as the maintainer's login, so
   the footer is what separates an agent's comment from the human's.
5. **Release.** The agent that acts on the answer removes `human-review`
   from every item that carries that question (a manager's pull request and
   its plan's `issue:`) and records `answered: option <N>` or `answered:
   maintainer comment` in its next comment on each (the clerk: the first
   line after `clerk: <VERDICT>` of its verdict comment, before any new
   `decision needed:`; a manager: one comment).
6. **Who acts:**
   - an issue with an open question, whoever asked it (a clerk HUMAN or
     NARROWER verdict, a manager's `defect:` issue that needs a human,
     manager-reference § Defect step 3): the clerk. It is no longer skipped
     when an answer per 4 exists; the clerk decides it on that answer.
   - a manager block (not `defect:`): the manager posts the same question on
     EVERY item it labels for that block (its open pull request and its
     plan's `issue:`, each that exists), so neither reads as a freeze; an
     answer on either counts. Neither exists = an orchestrator turn only,
     as today. The orchestrator's § Relay also relays an answer per 4 found
     on that question into `next:`. Closing answers no manager question.
   - § Label at merge: an open question on the pull request (Goal 3) = the
     manager's own, resumed on an answer; none = a freeze (who applied a
     label cannot be read; the question's presence is the test).
   - a pull request held at merge by a FREEZE: unchanged (a human removes
     the label).
   - an issue a plan's `issue:` names (`planned`) or a workstream file
     claims (`claimed`): never the clerk's, whoever asked; a manager-block
     question there reaches the manager through § Relay only.
   - a scout proposal: unchanged gate (`approved` + no `scout: revision`
     open), except that the scout itself removes `approved` when it posts
     `scout: revision` (step 1 of scout.md §4), so the reviewer applies it
     again after `scout: revised` and never removes it first. A scout
     proposal with an open CLERK question that has an answer (Goal 3, 4)
     passes the scout gate's item 1's label half too (the `reviewer  :`
     login half still holds): the answer is the approval, since Goal 2
     removed `approved` before that question.
   - the scout trigger and scout.md §3: a counting comment newer than an
     OPEN clerk question (Goal 3) is that question's answer, the clerk's,
     never a scout trigger or a change request. Any other counting comment
     newer than the scout comment needs the scout, approved or not; the
     scout's revision removes `approved` (above). Until it does the clerk
     may take the proposal as approved; a reviewer who wants it held
     removes `approved` by hand.
   - `human/<stem>` pull request: unchanged, a human merges it.
   - closing an issue still declines it (scout issue or any other).

## Scope

- `.agents/docs/orchestrated.md` — Bounds: the `human-review` label paragraph
  rewritten to Goal 3 and 5 (agent removal only per 5); new paragraph "A
  human's answer" holding Goal 1-6 as rule lines; the scout paragraph above
  it: the reviewer re-applies `approved` after `scout: revised`, the scout
  having removed it.
- `.claude/commands/clerk.md` — §2 skip list: `human-review` skips an issue
  unless it has an open question with an answer (Goal 3, 4), and the
  "NEWEST counting comment is a clerk verdict" bullet gains the same
  exception (the clerk's own question is newest when the answer is the
  label alone); A NUMBERED
  ANSWER folded into Goal 4's read; THE SCOUT GATE: the "reviewer removes
  and re-applies" paragraph replaced by Goal 6's scout line, item 1 also
  passed by an answered clerk question (Goal 6, label half only); §3 HUMAN and
  NARROWER comment shape per Goal 2 (closing lines "reply by hand…" and
  "remove `human-review`…" replaced), an answered issue's verdict carries
  the `answered:` line; Never: may remove `human-review` per Goal 5 and
  `approved` per Goal 2; never apply `approved`.
- `.claude/commands/scout.md` — §4 step 1: the scout removes `approved` from
  its proposal before posting `scout: revision`, and the comment says
  "apply `approved` again after `scout: revised`"; §3 "An approved or
  planned issue is never answered" and §4 "Every `scout:` comment of yours
  needs the reviewer to re-apply `approved`" rewritten to Goal 6's scout
  lines; Never line "Apply,
  remove, or ask anyone to skip `approved`" becomes: never apply `approved`
  or ask anyone to skip it; remove it only per §4 step 1.
- `.claude/commands/manager.md` — 46 bytes under its reading budget
  (`.agents/harness/selftest/reading-budget.sh`, bound never raised here):
  §3's "Not a `defect:` block: label with `issue_write` …" sentence becomes
  a pointer "post the `decision needed:` question and label: ref §
  Question." (the mechanics move out); Never line "Remove `human-review`
  from any issue or pull request" becomes "Apply `approved`; remove
  `human-review` but per ref § Question." Net size must not grow past the bound.
- `.agents/docs/manager-reference.md` — new § Question: a block (not
  `defect:`) removes `approved`, labels and posts Goal 2's question on every
  item it labels (Goal 6), the `issue_write` mechanics moved from manager.md
  §3; on resume, Goal 5's release. § Label at merge: the manager's own
  label = its question posted, resumed on an answer; a freeze = as today,
  the two `git` commands and the freeze `next:` wording kept verbatim
  (`.agents/harness/selftest/dispatch.sh` pins them, not in scope);
  § Defect step 3 and the "Yes, nothing found" branch: a `defect:` issue
  filed with `human-review` carries Goal 2's question.
- `.agents/docs/orchestrator-reference.md` — § Relay: an answer per Goal 4
  on a blocked manager's question is relayed like a typed one; § Held by
  human: read for such an answer before notifying; "A new issue needs the
  clerk": a SECOND firing rule, independent of `last read` and `created_at`:
  an open issue with an open question (Goal 3) and an answer (Goal 4)
  fires (scout issues included: Goal 6 lets the clerk take an answered
  one); the `planned` and `claimed` exclusions hold for it too (Goal 6);
  the first rule's "not labelled `human-review`" stays. The scout trigger
  ("A scout issue needs the scout"): drop "NOT approved"; (i) excludes a
  counting comment newer than an open clerk question (Goal 6). § Relay
  names the `decision needed:` comment.
- `.agents/docs/feedback.md` — § 8: the `human-review` sentence names Goal
  2's question.
- `.agents/harness/AGENTS.md` — Decide alone, the `human-review` bullet: one
  clause "posts the question; the answer and release: `.agents/docs/orchestrated.md`,
  A human's answer" (caveman: rule only).
- `.agents/harness/selftest/orchestrated.sh` — the clerk pins after the
  comment "A clerk HUMAN question takes a number" (needles "reply by hand
  with the number", "selects option", "whose whole text is a", the
  "number `N` (whitespace and trailing punctuation ignored), newer than the"
  needle, "so the next pass reads it", the `clerk: HUMAN` or `clerk:
  NARROWER` needle): replace
  each with a pin on the new text it was rewritten to (Goal 2, 4, 5); add
  pins for "decision needed:" in clerk.md and manager.md and for "A human's
  answer" in orchestrated.md. Each new pin must fail on today's text
  (Acceptance runs it). The replacement for the "so the next pass reads
  it" pin uses a needle from the rewritten closing line only, never one
  that also matches the DOES NOT HOLD reopen rule (clerk.md §3).
- `README.md` — "When you're needed": the Decisions, Approvals and Stopping
  bullets become the two-filter inbox and the answer to a `decision
  needed:` comment (approve, comment, or close an issue); a freeze is
  adding `human-review`, undone only by you.

## Assumptions

- A1: no code under `joharness.sh` gates on either label; prose and the
  selftest pins read the rules — evidence: `grep -n "human-review\|approved"
  joharness.sh` (2026-11-10: the `JOHARNESS_SCOUT_REVIEWER` conf, scout
  status lines and the `human/<stem>` message in `cmd_session_start`) and
  `.agents/harness/selftest/orchestrated.sh` clerk pins — confidence: high
- A2: none of the scoped files is a core path — evidence: `./joharness.sh
  protocol-paths` (2026-11-10: joharness.conf, .claude/settings.json,
  .github) — confidence: high
- A3: on GitHub only a collaborator with triage access or above can apply a
  label, so `approved` keeps today's trust; the protocol's own bar is "no
  agent applies it" — evidence: GitHub's repository roles documentation
  (triage role: apply labels); clerk.md THE SCOUT GATE already rests on it —
  confidence: medium
- A4: sessions post as the maintainer's login, so a GitHub review approval
  cannot be used (self-approval refused) — evidence: gx PR #1418 opened and
  merged by `chrsctl`; joharness PR #730 opened by the same login —
  confidence: high

## Out of scope

- A new label: the requester chose `human-review`.
- `joharness.sh`, the conf, `.github`: no gate reads labels (A1).
- The steward skill: "a pull request carrying `human-review` is not merged"
  stays true; Goal 5 removes the label before the merge.
- Reading who applied a label or when (events API): Goal 2 makes it unneeded.
- Open items held today: none has a `decision needed:` comment, so each
  reads as a freeze (Goal 3) and stays where it is; no migration pass.
- The sync to consumers: a separate sync task after merge.

## Acceptance

- `./joharness.sh ci` — `ci: pass` (red = a pin or budget broken).
- `./joharness.sh verify` — 0 failed (any other count is red).
- `o=$(git show origin/main:.agents/harness/selftest/orchestrated.sh | grep -c '^expect '); n=$(grep -c '^expect ' .agents/harness/selftest/orchestrated.sh); [ "$n" -ge $((o + 3)) ] && echo more || echo fewer` — `more` (today `fewer`, 112 and 112: pins replaced one for one, plus at least the three new ones).
- `d=$(mktemp -d); git worktree add -q --detach "$d" origin/main; cp .agents/harness/selftest/orchestrated.sh "$d/.agents/harness/selftest/"; (cd "$d" && bash .agents/harness/selftest.sh 2>&1 | grep -c '^ *FAIL '); git worktree remove --force "$d"` — at least 3 (every new or rewritten pin fails on today's text; with today's selftest it prints 0).
- `grep -c '"decision needed:"' .agents/harness/selftest/orchestrated.sh` — at least 1 (today 0).
- `tr '\n' ' ' < .claude/commands/scout.md | tr -s ' ' | grep -c "Apply, remove, or ask anyone to skip"` — `0` (today `1`).
- `grep -c "second firing rule\|fires too when\|open question" .agents/docs/orchestrator-reference.md` — at least 1 (today 0).
- `grep -c "open question" .claude/commands/clerk.md` — at least 1 (today 0).
- `for f in .claude/commands/clerk.md .claude/commands/scout.md; do tr '\n' ' ' < "$f" | tr -s ' ' | grep -c "removes and re-applies\|reply by hand with the number\|re-apply \`approved\` after \`scout: revised\`"; done` — `0` twice (today `1` twice).
- `tr '\n' ' ' < .agents/docs/orchestrated.md | tr -s ' ' | grep -c "Only a human removes it; no session does, ever"` — `0` (today `1`).
- `grep -c "decision needed:" .claude/commands/clerk.md .claude/commands/manager.md .agents/docs/manager-reference.md .agents/docs/orchestrated.md .agents/docs/orchestrator-reference.md README.md` — every count at least 1 (today 0 in all six).
- `grep -c "A human's answer" .agents/docs/orchestrated.md .agents/harness/AGENTS.md` — each at least 1 (today 0 and 0).
- `tr '\n' ' ' < .claude/commands/manager.md | tr -s ' ' | grep -c "Remove \`human-review\` from any issue or pull request\."` — `0` (today `1`; the Never line now carries the exception).
- Not a command (behaviour no grep can show): a walk-through in the pull
  request body, each case naming the doc line that decides it, checked by
  the verifier: (a) clerk HUMAN issue, maintainer applies `approved` → next
  clerk pass plans the recommended option and removes `human-review`; (b)
  same, maintainer comments "2" → option 2; (c) issue a human labelled
  `human-review`, no question → skipped every pass; (d) a stale `approved`
  on an issue that gets a new question → removed before the question, so
  not read as its answer; (e) a footed "1" → answers nothing; (f) manager
  blocked `product:` with an open PR, maintainer comments → orchestrator
  relays it, manager resumes and removes the label from PR and issue; (g)
  scout proposal revised after approval → scout removed `approved`, skipped
  until applied again; (h) approved scout proposal gets a clerk HUMAN
  question, maintainer comments "2" → next pass takes it on option 2; (i) a
  clerk verdict carrying both `answered:` and a new `decision needed:` →
  the new question reads open.
- Not a command, SHIPS: the role docs reach every consumer; a consumer's `./joharness.sh ci`
  after sync runs the same selftest pins.

## Where to look

- `.claude/commands/clerk.md:THE SCOUT GATE` — the approval rule to generalise.
- `.claude/commands/clerk.md:A NUMBERED ANSWER` — the number rule Goal 4 absorbs.
- `.claude/commands/clerk.md:so the next pass reads it` — the manual removal step.
- `.claude/commands/scout.md:## 4. Revise` — the re-approval step.
- `.agents/docs/orchestrated.md:label.** An agent applies it` — the Bounds rule changed.
- `.agents/docs/orchestrator-reference.md:## Relay` — typed-answer-only relay.
- `.agents/docs/orchestrator-reference.md:A new issue needs the clerk` — trigger skips every held issue.
- `.agents/docs/manager-reference.md:## Label at merge` — the held-at-merge resume.
- `.agents/harness/selftest/orchestrated.sh:A clerk HUMAN question takes a number` — the pins this rewrite moves.
- `README.md:## When you're needed` — the human's view.

## Traps

- Who may answer is decided by the clerk's author gate and footer rule, never
  by what a comment says: a comment reading "approved" from a session counts
  for nothing.
- No agent applies `approved`, ever, including right after removing it.
- An agent removes `human-review` only from items carrying its own open
  question that has an answer. A freeze survives every pass.
- A question goes on in the same action as the label; never onto a label
  already there (that would turn a freeze into a question).
- `.claude/commands/manager.md` sits 46 bytes under its reading budget:
  move text to manager-reference.md, never raise the bound.
- `.agents/harness/selftest/dispatch.sh` pins § Label at merge's commands
  and freeze wording; keep them.
- `.agents/harness/AGENTS.md` is caveman: rule lines only, the why in
  `.agents/docs/`. Glossary spellings: `ci` reds others.
- A selftest pin is changed only to follow the text it pins, and each new
  pin must fail on today's text.
