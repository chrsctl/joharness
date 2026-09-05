---
workstream: capture-intent
status: review
branch: claude/capture-intent-course-tsexxb
pr: 212
plan: capture-intent
issue: none
session: https://claude.ai/code/session_011xEAaoqw8hGPoLgEEASEYP
agent: opus
updated: 2026-09-05
next: Retire this file again in the last commit before the pull request updates
---

## Goal

Human pasted one URL: the "Capture as intent.md" lesson of Anthropic's
AI-Native SDLC Playbook. Review it against this repo's requirement stage
(`docs/product/`) the way the gastown review was done — as a research node
that says what joharness already has, what it should adopt, and what it
rejects with reason — so the finding outlives this session and the human can
queue any adopt-candidate as a plan. Human narrowed it mid-session: "Just do
research and usability", then resumed the review with the session switched
to opus. No `/code-review` pass ran; three subagent passes did.

## Decisions

- Research node, not a plan: the ask writes no code, and the precedent for
  a human-supplied external source is `docs/research/gastown-ideas.md`
  (`git show ae76075:docs/research/gastown-ideas.md`).
- Graduates to `.agents/docs/product/README.md`, not a prior-art page:
  `a14a804` dissolved `.agents/docs/prior-art.md` into the docs owning each
  decision, and the requirement's shape is owned there.
- Usability measured by running the gates on what the originator would
  write, not by reading the docs and judging: two probe files through
  `ci`, hook and graph (node, Method). One real defect found (F12).
- Review depth escalated sonnet to opus: the human resumed the review with
  the session switched to opus, and depth follows the tier that runs it
  (`.agents/docs/agent-selection.md`, review depth; escalation only).
  Adversarial, separate lenses: grounding (verifier), does-it-reproduce,
  verdict soundness.
- File restored after its retire commit to carry the late review record —
  the two-retire case the protocol names (`.agents/docs/handover/README.md`,
  Survives PR).
- Adopt-candidates stay candidates. Filing them as plans is product
  direction — the human's call (Decide alone, `.agents/harness/AGENTS.md`).

## Rejected

- Answering in chat only: the finding dies with the session; that is the
  one problem the research node exists for.

## Review

Three passes, all spawned at the branch's escalated opus tier, none of
which wrote the diff: a `.claude/agents/verifier.md` grounding pass, a
does-it-reproduce pass, an adversarial pass on verdict soundness. Round 1
is the record of the interrupted first attempt and stays for the reason
the protocol keeps rejected paths.

- r1: no review pass ran at first — the human stopped the verifier and
  declined `/code-review`, and the node shipped marking every finding WEAK.
  The human then resumed the review, so this is history, not the state.
  (fixed by rounds 2 and up)
- r2: (verifier) F2 cited the plan-blocking rule to
  `.agents/docs/plans/README.md`, Lifecycle. That file never mentions the
  `research:` edge — `grep -c research` returns 0. The rule is in
  `.agents/docs/research/README.md` Edges and `.agents/harness/AGENTS.md`
  step 2. The one mechanism F2's adopt-candidate rests on was attributed
  to a file without it. (fixed)
- r3: (verifier) F13's central claim was false: the TEMPLATE comment gives
  the path and `.agents/docs/product/README.md` names both keys and both
  values, three lines from a quote F13 itself carried. The finding
  contradicted itself and was the premise F12 leaned on. (fixed — F13 now
  says what is actually wrong: register and route, not absence)
- r4: (verifier) the Verification section claimed every lesson quote was
  re-grounded by the Method loop. The loop covers eight phrases; the
  findings carry roughly twenty more. A false claim about its own evidence,
  in the section whose job is grounding honesty. (fixed — Method now says
  eight, and the passes cover the rest)
- r5: (verifier) "no session may re-spawn one unasked" was stated as a
  protocol rule to justify shipping without a verifier. No such rule
  exists; step 5 says every depth spawns one. An invention covering a gap.
  (fixed — recorded in the node rather than deleted quietly)
- r6: (verifier) F9's two supporting quotes are both about PLANS; neither
  says anything about event-originated intake. (fixed — re-cited to
  `.agents/docs/unsupervised.md` Bounds, and the mode-scoping stated)
- r7: (verifier) Method's absence grep named no ref while its comment
  claimed "0 hits on origin/main"; as written it returns 17 on this branch.
  The reproduction step for the node's only absence claim was broken.
  (fixed — `origin/main` in the command)
- r8: (verifier) the fetch prompt was quoted with an internal ellipsis,
  against "web queries are commands; quote them". (fixed — quoted whole,
  tool named)
- r9: (verifier) F11's "any markdown file under docs/product/ is a
  requirement" is wrong at the edges: both readers exclude `TEMPLATE.md`,
  `README.md` and `VISION.md`. (fixed)
- r10: (verifier) node declared `agent: sonnet` while the workstream
  declared opus, so the queue would schedule the question below the tier
  that answered it. (fixed — node now opus/high, escalation only)
- r11: (verifier) unsourced claims: F7's "none is planned", F8's "nothing
  in the harness cares which client made the commit". (fixed — first
  dropped, second replaced by a grep and the one reader of authorship)
- r12: (adversarial) F3 rested on a graph.md rule about DERIVED state,
  while the repo's own `scope:` is a hand-written path list it accepts
  because it "rots visibly in review" — the counter-example, uncited. The
  finding also asserted design intent ("on purpose") that no file states.
  (fixed — counter-example carried, invention removed)
- r13: (adversarial) F5 was graded convergent while demanding a new README
  sentence, against this node's own settle rule. (fixed — adopt-candidate)
- r14: (adversarial) F9 carried two verdicts and F13 carried a fourth word
  ("folds into F6") outside the declared vocabulary. (fixed — one verdict
  each, from the three)
- r15: (adversarial) F12's proposed fix — read unknown as `normal` —
  collided with two uncited rules in the file it would edit: the PR 140
  incident where a value that "lints clean and renders as nothing" cost a
  plan, and the malformed-`issue:` red for "a claim that looks accepted and
  silently is not". Silently downgrading an urgent requirement is the same
  class. (fixed — the fix is reversed: keep the red, move the guard earlier)
- r16: (adversarial) the Question, Sweep and settle criterion were rewritten
  in the same commit that added F11-F13, so the usability criterion was
  written after its own findings — the ordering the protocol exists to
  prevent. (fixed as far as it can be: stated as a limit, with the reason
  the usability verdicts survive it, rather than back-dated)
- r17: (adversarial) the Echo was never amended for the usability half of
  the question. (fixed)
- r18: (adversarial) the sweep promised every practice and missed one: who
  may write to the intent home. (fixed — F14, and the Legacy-systems
  pointer named beside F7)
- r19: (adversarial) `graduates:` is single-valued, but the node said the
  two rejections belong beside rules living in three other files. (fixed —
  the graduation writes one paragraph in the target that POINTS at the
  owning rules, which keeps the diff inside "Not a plan")
- r20: (adversarial) F10 used "trust counted numbers" as a rule against
  measuring, and missed `feedback` and `scorecard` as the read-time
  precedent. (fixed)
- r21: (reproduce) Method's failing-run transcript was abridged: the real
  red run prints no `edges sound` line, and exit codes were absent.
  (fixed)
- r22: (reproduce) F12's severity was understated — `lint_nodes` walks the
  worktree, not a diff, so a bad `priority` on `main` reds later pull
  request runs for files they never touched, and step 7 then blocks
  merges. (fixed — severity corrected upward)
- r23: (reproduce) F11's hook behaviour was read from code and labelled
  unobserved. The pass observed it, against a dangling commit through
  `HANDOVER_BASE_BRANCH`. (fixed — Method carries the observed output)
- r24: (adversarial) style: one 131-character line left by the mid-run
  edit, hedging in three places, and the origin/main caveat stated three
  times. (fixed — the node now wraps at 79 except pasted output, which
  stays byte-exact)
- r25: (adversarial) the workstream file was retired before any review
  existed, leaving the findings no protocol-shaped home and `review` no
  way to resolve depth. (fixed — restored, this record written, retired
  again; the two-retire case the protocol names)
- r26: (verifier) this file's own Goal and r1 disagreed about whether a
  verifier ran, and "Where to look" omitted F12, the one measured defect.
  (fixed)

## Blockers

None.

## Where to look

- `docs/research/capture-intent.md` — the node. F12 is the one measured
  defect; F2, F5, F6, F10 and F14 are the other adopt-candidates.
- `.agents/docs/product/TEMPLATE.md` — what F2 would change.
