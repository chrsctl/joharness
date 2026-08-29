---
workstream: finding-id-lint
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: finding-id-lint
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire the plan and this file, open the PR, merge it.
---

## Goal

A third of recorded findings reach nothing: the fix map keys on
`^\+- r[0-9]+:`, so a bullet without an id-then-colon is invisible to the
loop that serves findings back. A `ci` stage names the malformed bullets on
this branch's diff. WARN, never red.

## Decisions

- Reading every anchor the plan names, in full, before writing a line. Last
  plan the anchor was read for the section I wanted and not the eleven lines
  that mattered, and the fix reinstated a rule this repo had rejected three
  times. That cost a verifier round and a full revert.
- **The two anchors disagreed, and reading both is what found it.**
  `fb_fix_map` attributes on `r[0-9]+:` — any number of digits. `fb_collect`'s
  NOID classifier matched `r[0-9] | r[0-9][0-9]` — one or two. Counted
  2026-08-29 across every merged workstream file in this repo's history: **23**
  findings carry a three-digit id, all of them attributed correctly by the map
  and reported as unattributable by the counter that exists to measure exactly
  that. `feedback`'s volume line read `223 carry no r1: id` before and **200**
  after, at `JOHARNESS_FEEDBACK_EDGES=0` — the default 50-edge window gives
  209 and 186 on the same two trees. The delta of 23 is the same in both, and
  the command belongs beside the number (r109).
  In scope because the plan's own Goal quotes that counter, and because the
  fix is not "teach the map new prefixes" (its Out of scope) but the reverse —
  removing a disagreement. `fb_keyable()` is now the single spelling both
  readers call, and `lint_finding_ids` calls it too: the defect this plan
  exists to name was itself caused by that rule living in two places.
- **The stage reads the DIFF, never the tree**, which is the plan's second
  Trap. A branch inherits every workstream file its base carries, so a
  tree-walking version names somebody else's findings on every `ci` run of
  every branch. Refuted by swapping the walk for a `find`.
  The precise claim, after r105: a file the branch never touched is never
  read. A file it DID touch is read whole, including bullets it inherited —
  the plan's Scope is "every workstream file the branch's diff touches", and
  a file this branch edited is one it answers for. Both halves have a case.
- **Warn, never red**, and asserted as such: `ci` exits 0 on a fixture branch
  whose `## Review` is full of malformed bullets. `churn` and `review` each
  earned their gate on a backtest and this has none.

## Rejected

- **Tightening `review_count` to the same rule.** The plan's first Trap: two
  counters, two questions. `review_count` asks whether a review happened and
  matches a looser `^- ` deliberately, sharing its awk with the handover hook
  so gate and hook can never disagree. Tightening it would turn a formatting
  slip into "no review recorded" and red a compliant branch.
- **Rewriting the 122 unkeyable findings already in history.** Out of scope by
  the plan and right: a record edited to satisfy a later rule stops being a
  record.
- **Changing `review_report`'s tree walk** to match this stage's diff walk.
  It is the pattern the Trap forbids and the plan says explicitly it is not
  this plan's to change. Left alone; the comment beside the new code says why
  it must not be copied.

## Review

Round 1, opus, `.claude/agents/verifier.md` (verifier) — 12 findings.
Recorded before their fixes and in the same commit. Three of them are
corrections to claims I made.

- r101: (verifier) The "THE DIFF, NEVER THE TREE" block was green over
  nothing: on the inheriting branch the stage printed `no workstream file in
  this branch's diff`, so the `refute` passed on silence and the `expect`
  passed on the same silence. Deleting the fixture outright left the suite
  green. (fixed — the branch now writes its OWN malformed finding so the
  stage is speaking, the base branch's copy is asserted to exist before the
  refute runs, and a separate case covers the no-workstream-file branch.
  Refuted by deleting the fixture, which now reds)
- r102: (verifier) Indented bullets were invisible and the stage said "clean"
  over them. `fb_findings` folds `^  [^ ]` into the bullet above, so a nested
  `- v2:` read as part of the previous finding — a positive claim about
  findings never read, which is the silence this stage exists to end. (fixed
  — the stage reads each bullet's FIRST line and names indented bullets
  separately with the reason; folding is right for reading a finding and
  wrong for counting them, so it no longer reuses it. Refuted)
- r103: (verifier) `--diff-filter=ACMRT` on the endpoint diff made the stage
  silent at the one moment `ci` runs for the record: step 7 puts the
  workstream file's deletion in the last commit before the pull request, and
  a file added AND deleted on the branch is absent from `git diff base HEAD`
  entirely. (fixed — the file list comes from `log --name-only base..HEAD`,
  which still carries it and is also how `fb_fix_map` sees it. Refuted)
- r104: (verifier) `[ -f "${ROOT}/${ws}" ]` was a tree read inside a diff
  walk — the exact bug this stage was written to avoid — and made it
  contradict git: an uncommitted `rm` printed "no workstream file" while git
  listed the file. (fixed — content comes from `git show HEAD:` and, for a
  file this branch retired, from the commit before the one that removed it.
  Refuted by a case that was missing: everything else in the topic is
  committed, so nothing else could tell `cat` from `git show`)
- r105: (verifier) The diff walk is file-granular, so touching an inherited
  workstream file reports every finding it already carried, and my Decisions
  claimed the walk means the stage "never names somebody else's findings".
  (recorded, not fixed: the plan's Scope says "every workstream file the
  branch's diff touches", and a file this branch edited is one it is
  answering for. The claim is corrected below rather than the code widened)
- r106: (verifier) `printf '%.72s'` truncates by BYTES and left two of an em
  dash's three behind. So does `${text:0:72}`, which was my first fix —
  bash slices by character only in a multibyte locale and `ci` sets none.
  (fixed — the cut lands on an ASCII space, which cannot be inside a
  multibyte character; no space in the first 72 bytes means no sentence and
  the line goes out whole. Refuted with an em dash positioned to straddle
  byte 72)
- r107: (verifier) TEMPLATE.md shipped a joharness-specific measurement to
  every consumer — `.agents/docs` is a whole-tree sync entry — with a date
  and a window and no command. (fixed — the shape lesson stays, the number
  goes, and two commands let any repo count its own)
- r108: (verifier) "21 cases added, each refuted" is not true. The five
  stated mutations cover 18 of 21. `malformed findings do not red ci` needs a
  sixth (make the stage `|| rc=1`), and the two three-digit cases pin
  `fb_findings`/`fb_fix_map` and cannot fail for any change to `fb_keyable`
  or the stage. (corrected — the commit for this round states coverage per
  mutation instead of claiming "each")
- r109: (verifier) "223 before and 200 after" needs
  `JOHARNESS_FEEDBACK_EDGES=0`, which neither the handover nor the commit
  said; the default window gives 209 and 186. (fixed — Decisions carries the
  knob, and both windows)
- r110: (verifier) `not measurable here (no merge-base; shallow checkout or
  base branch)` names causes that cannot produce it — on the base branch
  there IS a merge-base. Copied from two pre-existing lines. (fixed here;
  the two it was copied from are not this plan's to touch)
- r111: (verifier) Two `mkdir -p` calls went dead when `write_ws` took the
  job, and one still carried the comment claiming to own that guard. The
  "Six occurrences in one session" note is a claim with no command. (fixed —
  dead calls removed, the comment points at the helper, and the count is
  replaced by the grep that answers it)
- r112: (verifier) `.agents/harness/selftest/feedback.sh` is outside the
  plan's declared `scope:`, and `.agents/docs/feedback.md` — which the plan's
  own "Where to look" names — still described the blind spot with no mention
  of the stage. (fixed for the doc; the scope note is below)

## Scope notes

- Two files outside the plan's `scope:` line. `.agents/harness/selftest/feedback.sh`,
  because the `fb_keyable` fix changes what `fb_collect` counts and an
  untested fix is what the last two rounds punished. `.agents/docs/feedback.md`,
  because its "What this cannot see" entry described a blind spot this branch
  partly closes, and the plan pointed at that entry. Both decided alone,
  small, flagged here.

## Blockers

None.

## Where to look

- `joharness.sh:fb_fix_map` — the `^\+- r[0-9]+:` match that decides
  attribution. This is the form the stage must check against.
- `joharness.sh:fb_collect` — the inline `${line%%:*}` id classifier.
- `joharness.sh:review_count` — a LOOSER rule (`^- `) on purpose. Two
  counters, two questions; the plan's first Trap is not to conflate them.
- `.agents/docs/feedback.md`, "What this cannot see" — the blind spot.
