---
workstream: gate-review-verifier-tag
status: review
branch: claude/current-state-review-oxfb7f
pr: none
plan: gate-review-verifier-tag
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Retire this file and the plan in the last commit before the pull request, then open and merge it
---

## Goal

`review_report` checks that a branch recorded SOME findings under `## Review`
at the edge. It never checks that any came from the verifier — the
independent reader step 5 says every depth spawns, tagged `(verifier)`. So a
branch that only self-reviews passes exactly as if the verifier had run. Close
the gap the plan's own source finding (r6) names.

## Decisions

- **Taken by a supervised session, which is the point.** The plan's scope is
  protocol text and its own Traps record the run that started implementing it
  unattended and was caught by the handover-guard stop hook. `authority` reads
  `mode supervised, verdict NOT CLAIMED` here, so the constraint does not
  apply.
- **Tier escalated sonnet to opus.** The plan asks for `sonnet`; escalation is
  allowed, downgrade is not. This gate fires on every branch in this repo and
  in every consumer `joharness.sh` syncs to, and the plan's last Trap says the
  branch owes its own verifier round under the rule it is enforcing.

## Rejected

- **Asking the question with a second parser beside the existing one.** The
  first cut ran `fb_findings | grep -qF '(verifier)'` next to `review_count`,
  which is what the plan's Where to look recommends. Two extra awks per
  workstream file, and `review` went 260 to 348 against a 274 ceiling
  (`./joharness.sh perf`, 2026-09-02) — a per-item fork put back inside a
  loop, which is the one thing that budget exists to name.
- **Raising the budget to match.** Available and wrong here: the forks were
  removable. `review_at_edge` was forking one awk per field over the same
  frontmatter, which `gr_fields`' own comment already calls the defect it
  exists to fix.

## Review

Round one — verifier at opus on 284a260, three passes (correctness,
does-it-reproduce, style); each finding re-checked here against its source
before being accepted. Two container restarts lost an earlier round before it
reported; this is the round that ran to completion, against the head that has
merged PR 196 and PR 197.

- r1: (verifier) the tag red fired on workstream files the branch INHERITED,
  not only the ones it wrote. `review_report` loops `lint_nodes docs/handover`,
  a `find` over the tree. Before this change an inherited file could only red
  by having an EMPTY `## Review`; now any record written before the tag rule
  existed reds — 44 of 70 workstream-file versions on `origin/main`
  (`git rev-list origin/main -200` with this file's own `review_marks`,
  counted 2026-09-02). It collides with two written rules: step 4's "DIFF
  against merge base, never read the tree", and `fin_gate`'s own carve-out,
  "a gate that fails for somebody else's omission is one sessions route
  around" (fixed — `lint_ws_in_diff` names what this branch wrote, one fork
  for the whole run; an inherited untagged record is NAMED and never red)
- r2: (verifier) `fin_strength` forks `gr_field status` one line after it
  already holds that value, which is the pattern the new `review_at_edge`
  signature exists to remove (fixed — one `gr_fields pr status` there too)
- r3: (verifier) `review_marks`' count is a THIRD literal copy of an awk
  `review_count` and the handover hook also carry, under a comment claiming
  they "can never disagree". They agree today — 180 workstream-file versions
  from `git rev-list origin/main -400`, 0 mismatches — but nothing enforces
  it (fixed as far as this plan goes — the comment now says they agree and
  that nothing holds them there; folding the three is its own change)
- r4: (verifier) the section bound was pinned by NOTHING. Dropping `in_r &&`
  from the tag rule — a `(verifier)` anywhere in the file — left the suite at
  1281 passed, 0 failed. Under that mutation THIS file satisfies the gate
  with a wholly untagged review, because its `## Goal` says `(verifier)`
  (fixed — a case builds exactly that file and requires it to red)
- r5: (verifier) the tag was read on any LINE of the section, and the rule's
  bar is one FINDING. A session that pastes the red it just got into its
  `## Review` clears the gate; so does a heading, or a sentence of prose.
  Reproduced here before accepting it: the paste shape returned `1 0` after
  the fix and green before it (fixed — a bullet is folded on the same
  `^  [^ ]` rule `fb_findings` uses and only the folded bullet is tested)
- r6: (verifier) "mid-build counts the finding" greps the whole `== review`
  block, and `ws.md` was also printing `1 finding(s) recorded` — so the case
  passed with `mid.md`'s section EMPTY (fixed — two findings, so the count in
  the assertion belongs to the file the case names)
- r7: (verifier) the wrapped-tag case's comment said `fb_findings` folds and
  "a line-by-line scan would red this branch", while the code WAS a
  line-by-line scan and that is why the case was green — the comment told a
  reader the opposite of what ran (fixed by r5, and the comment rewritten)
- r8: (verifier) two statements inside `joharness.sh` — the env-var header
  and the session-start banner — still described the gate as "with no review
  recorded" and "ci checks record, not count". The banner's own comment says
  it exists so a session does not learn about the gate from a red `ci`
  (fixed — both name the tag)
- r9: (verifier) `.agents/scripts/bootstrap-consumer.sh` seeds every consumer
  a `joharness.conf` carrying the same stale criterion, which is the
  counter-example to the plan's Acceptance line "No consumer-only file to
  update" (fixed)
- r10: (verifier) five more documents state the old criterion, and
  `TEMPLATE.md` — the text a session copies — never mentions `(verifier)`
  (fixed for `TEMPLATE.md` and the two `.agents` files that state the
  criterion as a rule; `README.md` and `joharness.conf`'s own comment are
  left, and the failure message now cites where the rule is written)
- r11: (verifier) the `260 to 348` pair does not re-count. 260 holds only at
  `84b492a`, this branch's commit before the change — the same command prints
  259 at the base the file now sits on — and the 348 tree was never committed
  (fixed — the comment names the commit, says which half is re-countable, and
  says the pair is kept for its shape rather than as a measurement)

## Blockers

None.

## Where to look

- `docs/plans/gate-review-verifier-tag.md` — the plan; its Where to look
  names every anchor and its Traps name the three things not to do.
