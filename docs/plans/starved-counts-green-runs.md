---
plan: starved-counts-green-runs
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .claude/commands/manager.md, .agents/docs/manager-reference.md, .agents/docs/consumer-repos.md, .agents/docs/product.md
---

## Goal

STARVED (`.claude/commands/manager.md` §4, `conflict: base outran finish`)
is meant to fire when a green `finish` keeps losing the race to a fast
base. On 2026-11-11 it fired twice in chrsctl/gx. Both times the blocked
question went to a human, and the human's answer was the same steps the
manager had already run. The manager counted every `finish` that came back
BEHIND, so one block came from a branch with no green run at all.

Evidence, read from the session transcripts with `list_events` on
2026-11-11:

- gx #1495 (session_01J1YMK7KWSCjwGtCL8t8DsM): no full run was ever green.
  - Both full runs (11:16:59 → ~11:50 and 12:21:29 → ~12:55) started
    `0 behind origin/main (fetched just now)` and ended
    `local-check: FAILED (exit 1)`, at `elapsed 1997s` and `elapsed 2006s`.
  - The cause was that the local service stand-ins were not exported; it
    was not the base.
  - The three counted "behind" runs (1, 4, 7) were BEHIND refusals at
    START, each about 10 s with `ci and verify NOT run`, and each came
    after a red run.
  - The block's `next:` said "three finish runs ended BEHIND …; checks were
    green on earlier heads". Neither half of that was what the output said.
- gx #1488 (session_01J1YMK3ETxDE1iiuLELheH7): STARVED fired as written,
  but the human had nothing to decide.
  - Run 1 was a full run: 29.5 min, pass, then 2 behind.
  - Run 2 took about 40 s, the length of a CATCH-UP; it was then 4 behind.
  - Run 3 took about 9 min, a full run, because the base had changed
    `local-check` itself, which refuses CATCH-UP by design; it was then 2
    behind.
  - The relayed human answer was "Merge origin/main, run finish at once …
    Behind again = merge origin/main and finish again (CATCH-UP); the
    STARVED count restarts from this answer". That is the same loop with
    the counter reset. No human judgement went into it.

So the count measures the wrong event, and the question it sends a human
does not ask anything only a human can answer. `finish` already holds the
fact that separates the two cases: the certificate (`checks_cert_file`).
It is written only on a full green and removed when a full run starts. This
plan makes `finish` print that fact on a BEHIND refusal, and makes §4 count
from that line.

## Scope

- `joharness.sh:checks_gate`. A second record beside the certificate,
  `checks_green_file` (git dir, `joharness-finish-green`, one `head=` line):
  removed when any suite run starts (full or CATCH-UP), written with the
  pinned head when that run ends green. Amended on the branch (plan-checker
  r2): the certificate alone is not "the last run was green" — a red
  CATCH-UP keeps it, and an ancestor test passes a head carrying own
  commits no run saw. The certificate and CATCH-UP's rules are unchanged.
- `joharness.sh:checks_gate`, in the BEHIND branch. When HEAD is behind,
  print one more line saying which case this is:
  - When the green record exists, its `head=` is an ancestor of HEAD, and
    HEAD is that head or its tree is the clean merge
    (`merge-tree --write-tree`) of that head with `merge-base HEAD <ref>`
    (only base merged in since), print
    `  OUTRUN       a green run at <short> was outrun by <ref>: merge it in, finish again`
    and, indented under it, `(counts as finish behind)`.
  - Otherwise print
    `  NOT OUTRUN   no green run covers this head (last run red, unfinished, never ran, or own commits since): fix that; not a finish behind`
    (wrapped over two lines).
  - Read only; never write or remove either record on this path.
- `.agents/harness/selftest/checks.sh`, CATCH-UP section. Add cases, each
  run on `origin/main`'s `joharness.sh` first (must fail) and on the branch:
  1. Full green, then the base moves one commit, then `finish` →
     `OUTRUN       a green run at`.
  2. Full red local-check, then the base moves, then `finish` →
     `NOT OUTRUN`, and refute the prefix `OUTRUN       a green run`.
  3. No run ever on this branch, base moved → `NOT OUTRUN`.
  4. Another branch's green in the same worktree (its head not an ancestor
     of HEAD) → `NOT OUTRUN`.
  5. Green, then an own commit, base moved → `NOT OUTRUN`.
  6. Green, merge base in, `finish` a CATCH-UP whose ci goes red, base
     moved → `NOT OUTRUN`.
  7. Green, base merged in (no run), base moved again → `OUTRUN`.
- `.claude/commands/manager.md` §4, the STARVED paragraph. Count only runs
  that print `OUTRUN` (`finish behind: <n>`); `NOT OUTRUN` is a red to fix
  on the ordinary path. The rest goes to a new `## Starved` in
  `manager-reference.md`: manager.md's reading budget
  (`selftest/reading-budget.sh`, 54 bytes free) is not raised.
- `.agents/docs/manager-reference.md`, new `## Starved`: the counting rule,
  the NOT OUTRUN path (fix it, or block `defect:`/`hardware:` with the real
  cause, never `conflict:`), the block's `next:` exactly
  `conflict: base outran finish: <n> green runs outrun (behind <b1>,<b2>,<b3>); human: hold merges until this one lands, or merge it as-is <k> behind, or raise JOHARNESS_CATCHUP_COMMITS`
  (`<bi>` = the BEHIND count each OUTRUN refusal printed, `<k>` = the
  latest), never `next:` text telling the human to re-run finish; the
  2026-11-11 evidence (gx #1495 and #1488, one line each) and the why.
- `.agents/docs/consumer-repos.md` § Local checks: one sentence naming the
  OUTRUN / NOT OUTRUN line (the phrase "still behind after three" is not
  there). `.agents/docs/product.md`, "Conflict at finish": "still behind
  after three" becomes three `OUTRUN` runs. Wording only.

## Assumptions

- A1: The certificate exists if and only if the last full run on this
  worktree was green. The `rm -f "$cf"` call happens before a full run's
  suites; the write happens only at `rc -eq 0 && catchup = 0`; a CATCH-UP
  green leaves it in place, and so does a red CATCH-UP (plan-checker r2:
  hence the green record).
  — evidence: `joharness.sh:checks_gate` (`rm -f "$cf"`, `printf 'head=%s\nbase=%s\n'`)
  — confidence: high.
- A2: A BEHIND refusal returns before the catch-up/rm step, so a
  certificate survives a refusal.
  — evidence: `joharness.sh:checks_gate`, the `ci and verify NOT run: they would answer about the wrong tree` return above `checks_catch_up "$ref"`
  — confidence: high (read 2026-11-11; the new selftest case 1 must print
  OUTRUN, which confirms it).
- A3: In gx #1495, no run printed `finish: pass`.
  — evidence: transcript, session_01J1YMK7KWSCjwGtCL8t8DsM, runs at 11:16:59
  and 12:21:29, `local-check: FAILED (exit 1)`
  — confidence: high.
- A4: gx #1488's run 2 was a CATCH-UP.
  — evidence: duration only (11:23:40 → 11:24:30). The finish output was
  never printed into the transcript.
  — confidence: medium. The plan does not depend on it.
- A5: A container restart between a green run and the next `finish` keeps
  the git dir, so the certificate survives. If the git dir is lost,
  NOT OUTRUN is the safe failure: no false starvation.
  — evidence: none measured
  — confidence: low. Fine either way.

## Out of scope

- Changing CATCH-UP's rules: the bound, the shared-path refusal, or the
  `local-check`-changed refusal. In #1488, CATCH-UP did what it is
  documented to do (`consumer-repos.md` § Local checks).
- Making `finish` itself merge `origin/main` or loop. The manager does the
  merge (manager.md §4).
- Criterion-id collisions between sibling branches in gx (renumbering on
  merge). That is the consumer's own plan, gx `docs/plans/criterion-id-blocks.md`.
- `block_reason_ok`. The prefix `conflict:` stays valid.
- Wall-clock bounds or timers on STARVED.

## Acceptance

- `./joharness.sh ci` — prints `ci: pass`; `ci: FAILED` = not done.
- `./joharness.sh verify` — `0 failed`, passed count at least 7 above
  `origin/main`'s (the new cases); any failed count above 0 = not done.
- `bash .agents/harness/selftest.sh` in a `git worktree` of `origin/main`
  with the branch's `checks.sh` copied in — the new cases print `FAIL`; on
  the branch they pass. Both counts in `## Review`.
- `grep -n "OUTRUN" .claude/commands/manager.md` — at least one hit, between
  `## 4. Finish` and `## Never`; none = not done.
- `grep -n "still behind after three" .agents/docs/product.md` — no hit.

## Where to look

- `joharness.sh:checks_gate` — the BEHIND branch (`BEHIND       %s commit(s) behind`) and the certificate handling.
- `joharness.sh:checks_cert_file` — where the certificate lives.
- `joharness.sh:checks_catch_up` — how the certificate is read (head= / base= parsing, ancestor test); reuse that parsing.
- `.agents/harness/selftest/checks.sh:kccu_sync` — the CATCH-UP fixture helpers to extend.
- `.claude/commands/manager.md` — §4 Finish, "Behind again at merge?".
- `.agents/docs/manager-reference.md` — "A STARVED merge (manager.md §4) is this case too".

## Traps

- Never skip, disable or quarantine a selftest to get green.
  `harness/AGENTS.md` Loop 5.
- A test for the fix must FAIL without it. Run the new cases on
  `origin/main` first.
- Core paths (`joharness.conf`, `.claude/settings.json`, `.github`) are not
  touched. `JOHARNESS_CATCHUP_COMMITS` is named in `next:` text only, never
  changed here.
- Glossary spellings: `ci` fails on the others (`.agents/docs/glossary.md`).
