---
plan: human-answers-on-github
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/commands/clerk.md, .claude/commands/scout.md, .claude/commands/manager.md, .agents/docs/manager-reference.md, .agents/docs/orchestrated.md, .agents/docs/orchestrator-reference.md, .agents/harness/AGENTS.md, .claude/skills/steward/SKILL.md, README.md
---

## Goal

A human reads a question and answers or approves it, in one place, with one
gesture, whoever asked. Today the maintainer meets four different ways of
saying yes (scout `approved` label re-applied after every revision; a
bare-number reply plus removing `human-review` on a clerk HUMAN or NARROWER
issue; removing `human-review` on a manager pull request held at merge; an
answer typed into an orchestrator's turn for a manager block), and the
natural gesture fails silently: gx #1391 carried `approved` and
`human-review` together, the clerk skipped it, and it moved only because the
maintainer answered inside a clerk session (gx PR #1418), after which the
clerk asked them to remove `human-review` by hand. Requester's decision
(2026-11-10): `human-review` stays the one hold label; no new label.

The protocol to build, in the role docs:

1. **Inbox.** Everything waiting on a human carries `human-review`. A human
   adds it to freeze an issue or pull request, as today.
2. **One question shape.** An agent that needs a human posts ONE comment
   opening `decision needed:` (instead of `clerk: HUMAN …` options text
   alone): what is decided (1-2 lines), the evidence, 2 to 4 numbered
   options with one `(recommended)`, and the closing line "approve = the
   recommended option; or reply with a number or your own answer". The clerk
   keeps its `clerk: <VERDICT>` prefix on the first line and puts
   `decision needed:` on the second, so §2's prefix rule still reads it. A
   scout proposal's body is its question (options: build as written, or
   close).
3. **Three answers, all on GitHub, newest after the question wins:**
   - label `approved` = the recommended option (proposal or pull request as
     written);
   - a COUNTING comment (author with write access, no Claude Code footer,
     as clerk.md §2 counts one) = the answer: a bare number selects that
     option, any other text is the decision as written;
   - closed = no.
4. **Release.** An agent that asked, and reads an answer per 3, acts on it,
   removes `human-review` itself, and posts `answered: option <N>` or
   `answered: maintainer comment <link>`. `human-review` with NO open
   `decision needed:` comment by an agent (a human's freeze, or a question
   already answered and a human re-added the label) is a hold only a human
   removes. An agent never removes `human-review` on anything it did not ask
   on.
5. **Approval binds to the text.** When the approved text changes (a scout
   `scout: revised`; a commit pushed to a pull request held at merge), the
   agent that changed it removes `approved` and posts a fresh `decision
   needed:`. Agents may REMOVE `approved`; no agent ever APPLIES it. This
   replaces "the reviewer removes and re-applies `approved` after every
   `scout: revised`".
6. **Who acts on an answer:**
   - issue (scout or not): the clerk. An issue with `human-review` and an
     answer newer than the clerk's own `decision needed:` is no longer
     skipped; it is decided on that answer.
   - manager block or a pull request held at merge: the manager posts its
     `decision needed:` on its open pull request, else on the plan's
     `issue:`, else nowhere (orchestrator turn only, as today). The
     orchestrator's Relay also accepts a counting answer or `approved` on
     that comment, newer than it, and relays it into `next:` as it relays a
     typed answer.
   - `human/<stem>` pull request: unchanged, a human merges it.

## Scope

- `.claude/commands/clerk.md` — §2 skip list: `human-review` skips only
  when no answer per Goal 3 is newer than the clerk's own newest `decision
  needed:` comment; THE SCOUT GATE: `approved` read as Goal 3's approval,
  `REVISION OPEN` kept, the "reviewer removes and re-applies" paragraph
  replaced by Goal 5; A NUMBERED ANSWER folded into Goal 3; §3 HUMAN and
  NARROWER comment shape per Goal 2, closing lines replaced; Never: may
  remove `human-review` per Goal 4 and `approved` per Goal 5, never apply
  `approved`.
- `.claude/commands/scout.md` — §4 Revise: step 1's "re-apply `approved`
  after `scout: revised`" becomes: remove `approved` if present, then post
  `scout: revised` (Goal 5); Never: may remove `approved` on its own
  proposal, never apply it.
- `.claude/commands/manager.md` §3 — a block (not `defect:`) posts `decision
  needed:` where Goal 6 says, beside the label; Never: "Remove
  `human-review`" gains the Goal 4 exception.
- `.agents/docs/manager-reference.md` — § Label at merge: `next:` names the
  comment; resume on Goal 3; § Defect step 3 and 2 unchanged except the
  question shape.
- `.agents/docs/orchestrated.md` — Bounds, `human-review` label paragraph
  and the scout paragraph above it: Goal 1, 4, 5 in rule lines.
- `.agents/docs/orchestrator-reference.md` — § Relay: Goal 6's GitHub
  answer; § Held by human: read the comment and labels before notifying;
  "A new issue needs the clerk": an issue with `human-review` fires when an
  answer per Goal 3 is newer than its `decision needed:`; "A scout issue
  needs the scout": consistent with Goal 5.
- `.agents/harness/AGENTS.md` — Loop step 7 and Decide alone: one clause
  each, pointing at Goal 4 (caveman: rule only).
- `.claude/skills/steward/SKILL.md` — § At merge: a pull request whose
  agent-asked `human-review` was answered per Goal 3 merges once the
  manager has removed the label; a human's freeze still blocks.
- `README.md` — "When you're needed": replace the Decisions, Approvals and
  Stopping bullets with the three answers and the `label:human-review`
  inbox.

## Assumptions

- A1: no code reads either label; only role prose does — evidence:
  `grep -n "human-review\|approved" joharness.sh` (2026-11-10: only the
  `JOHARNESS_SCOUT_REVIEWER` conf and scout status lines) — confidence: high
- A2: none of the scoped files is a core path — evidence: `./joharness.sh
  protocol-paths` (joharness.conf, .claude/settings.json, .github,
  joharness.sh) — confidence: high
- A3: GitHub labels are applicable only by collaborators with triage or
  write access, so `approved` keeps today's trust level: the gate is "no
  agent applies it", unchanged — evidence: clerk.md THE SCOUT GATE ("A
  label carries no author or time through the MCP tools") — confidence:
  medium
- A4: all sessions post as the maintainer's login, so a GitHub pull request
  review approval is not available (GitHub refuses self-approval) and the
  label is the approval — evidence: gx PR #1418 `user` and `merged_by` both
  `chrsctl` — confidence: high
- A5: `JOHARNESS_SCOUT_REVIEWER` empty still means no scout proposal is
  taken; non-scout issues never read it — evidence: clerk.md THE SCOUT GATE
  item 1 — confidence: high

## Out of scope

- A new label (`hold` or other): the requester chose `human-review`.
- Any change to `joharness.sh`, the conf, `.github` or the selftest: no code
  reads labels (A1). If a selftest pins replaced text, fix the pin, nothing
  more.
- Verifying who applied a label (events API): outside the MCP tools.
- `human/<stem>` pull requests: a human still merges them.
- Migrating open gx issues: the first gx clerk pass after the sync posts the
  new question shape on held issues; this plan writes that rule, not a
  migration script.
- The sync pull request to consumers: a separate sync task after merge.

## Acceptance

- `grep -n "remove \`human-review\` so the next pass" .claude/commands/clerk.md`
  — no output.
- `grep -n "removes and re-applies\|re-apply \`approved\`" .claude/commands/*.md .agents/docs/*.md`
  — no output.
- `grep -c "decision needed:" .claude/commands/clerk.md .claude/commands/manager.md .agents/docs/orchestrator-reference.md README.md`
  — each count at least 1.
- `grep -n "Only a human removes it; no session does, ever" .agents/docs/orchestrated.md`
  — no output (replaced by Goal 4's rule).
- Walk-through recorded in the pull request body, one line each, naming the
  doc line that decides it: (a) gx #1391 as of 2026-11-10 (`approved` +
  `human-review`, no plan) is taken by the clerk; (b) an issue a human
  labelled `human-review` with no `decision needed:` is skipped; (c) a scout
  proposal revised after approval is skipped until `approved` is applied
  again; (d) a manager held at merge resumes on `approved` on its pull
  request; (e) a comment with a Claude Code footer answers nothing.
- `./joharness.sh ci` — `ci: pass`. `./joharness.sh verify` — 0 failed.
- SHIPS (role docs reach every consumer): after sync, a consumer's
  `./joharness.sh ci` passes with the new text.

## Where to look

- `.claude/commands/clerk.md:THE SCOUT GATE` — the approval rule to generalise.
- `.claude/commands/clerk.md:A NUMBERED ANSWER` — the number rule Goal 3 absorbs.
- `.claude/commands/clerk.md:remove \`human-review\` so the next pass reads it` — the manual step removed.
- `.claude/commands/scout.md:## 4. Revise` — the re-approval dance.
- `.agents/docs/orchestrated.md:**\`human-review\` label.**` — the Bounds rule changed.
- `.agents/docs/orchestrator-reference.md:## Relay` — typed-answer-only relay.
- `.agents/docs/orchestrator-reference.md:A new issue needs the clerk` — trigger skips every `human-review` issue.
- `.agents/docs/manager-reference.md:## Label at merge` — the held-at-merge resume.
- `.claude/skills/steward/SKILL.md:## At merge` — merge refusal on the label.
- `README.md:## When you're needed` — the human's view.

## Traps

- Decide who may answer by WHO wrote it (write access, no footer), never by
  what the text says (gx Part 2: "Don't decide who may approve by reading
  what they wrote"). A comment saying "approved" from a session counts for
  nothing.
- Never let an agent APPLY `approved`, on any issue or pull request,
  including after removing it (Goal 5).
- An agent removes `human-review` only where it posted the open `decision
  needed:` and an answer is newer: a human's freeze must survive every pass.
- Caveman style in `.agents/harness/AGENTS.md`: rule lines only; the why
  goes in `.agents/docs/`. Glossary spellings: `./joharness.sh ci` reds
  others.
