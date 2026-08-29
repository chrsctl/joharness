---
workstream: moment-feedback-hooks
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: moment-feedback-hooks
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Run ci and verify, retire the plan and this file, open the PR.
---

## Goal

Stage 4 of the feedback loop — Prevent, the only stage that changes an
outcome — rides on the model remembering to ask. A PreToolUse hook injects a
file's recorded findings the moment a tool is about to edit it.

## Decisions

- **The contract was verified before a line of the emitter, and the plan's
  central trap is real.** Official docs, checked this session: a PreToolUse
  hook reaches the model ONLY through
  `hookSpecificOutput.additionalContext`, with `hookEventName: "PreToolUse"`
  required beside it. Plain stdout goes to the debug log and is shown to
  nobody. Exit 2 is the one code that BLOCKS a tool call, so this hook can
  never produce it by its own logic; stdout over 1 MB is truncated silently,
  and a truncated envelope parses as nothing.
- **"Never exits 2" needed a shell outside the script to hold it.** The file
  cannot promise bash reaches its logic: a truncated or CRLF-mangled copy
  dies at parse time with exactly status 2. The registration ends
  `|| exit 0` for that, and the file's header says so instead of claiming an
  absolute it does not own.
- **The plan's figures were stale in the direction that matters.**
  `./joharness.sh feedback joharness.sh`, this tree, 2026-08-29: **4536 /
  4724 / 4781 ms** uncached against the plan's 3802 / 3942 / 3783, at 123
  merged edges with 50 read. The cache is more load-bearing than the plan
  argues, not less. (An earlier note here read 6774 / 6648 / 6846; that was
  measured before the `fb_report_path` rewrite below and does not reproduce
  on this tree — see r11.)
- **The cache lives in `fb_collect`, gated on an env var the hook sets.** Off
  unless `JOHARNESS_FEEDBACK_CACHE` names a directory, so every command-line
  run walks history exactly as before — proven by diffing full and per-path
  output, cached against uncached: identical, and now asserted. Keyed by base
  tip and edge cap, NOT by HEAD: keying on HEAD would pay the walk again
  after every commit, which is most of the cost back.
- **A per-finding `grep` in `fb_report_path` was the rest of the cost.**
  Cached, a call still took 2808 ms, because the report forked a `grep -qxF`
  and two `cut`s per line of history — ~750 forks. One awk instead: same
  measurement today reads **4527 ms cold, 79 and 75 ms warm**, output
  byte-identical. Same shape as `review_prior` last plan, found the same way
  — by measuring once something started calling it often.
- **The injection is capped at 8 findings.** Uncapped, this repo's hottest
  file injects 30,342 bytes before the first edit of it (measured
  2026-08-29, `./joharness.sh feedback joharness.sh --quiet | wc -c`).
  Capped: 2,763, carrying the exact count of what was left out and the
  command that shows the rest. "Hook output is paid on every fire" is the
  plan's own rule and 30KB is not caveman.

## Rejected

- **Anchoring the key read on "the first `file_path` match".** It was the
  shape already there, and the escaped-content case was written to catch it
  — but the case passes either way, because well-formed JSON escapes the
  quotes inside a string and the byte sequence `"file_path"` never occurs
  there. Kept the anchor anyway, on the raw-text case that does separate
  them (r2, and the pair of tests under it).

## Review

Round 1, opus, `.claude/agents/verifier.md` (verifier) — 14 findings on the
branch diff. Every one is recorded here before its fix and in the same
commit as it.

- r1: (verifier) `fb_cache_load` ran `eval "$k=$v"` behind
  `case "$k" in FB_[A-Z_]*)`, which is `FB_`, one character, then `*` — it
  matches anything, so a cache file holding `FB_A$(cmd)=1` executed `cmd`,
  at a predictable name under a shared temp root. The comment above it
  claimed "digits and names only, never arbitrary text"; that was false, and
  a comment asserting a property the code lacks is what stops the next
  reader checking. (fixed — explicit `case` over the eleven names it may
  set, no eval; refuted with the payload, which no longer runs)
- r2: (verifier) `NotebookEdit` was registered and could never fire: its
  parameter is `notebook_path`, not `file_path`, so the hook matched the
  event and exited empty every time — a dead branch under a green matcher.
  Also flagged a `Write` whose content carries `"file_path": "..."`. (fixed
  — key by tool, and the read anchored to where JSON puts a key. The content
  half is half true: see Rejected)
- r3: (verifier) Raw control characters (`\f`, ESC, `\b`, `\v`) void the
  whole JSON envelope, and a voided envelope is silence, not an error
  anyone sees. Only `"` `\` `\t` were handled. (fixed — every U+0000–U+001F
  goes out as `\uXXXX`, with `\t` and `\r` in their short forms)
- r4: (verifier) `fb_cache_save` published `.vars` first, so a crash between
  renames left a cache that loaded clean and answered "no findings"
  authoritatively for the rest of the session — with the hook's own
  already-seen marker suppressing the second chance. (fixed — `.vars` last,
  and the loader requires all three files)
- r5: (verifier) The traversal case asserted `${TMP}/pwned` and
  `${ptf_scratch}/pwned`; the real escape target is `${ptf_scratch}/g/pwned`,
  so the case was green with the sanitizer deleted. (fixed — asserts the
  reachable path; refuted by deleting `tr -cd`, which turns it red)
- r6: (verifier) The cache had no test coverage at all: deleting
  `fb_cache_load` and `fb_cache_save` left the suite green. (fixed — eight
  cases, including one that empties the cached blob to prove the report
  READS it; refuted by stubbing `fb_cache_load` to `return 1`)
- r7: (verifier) The absolute-path arm is the only one production takes and
  no case exercised it; it dies silently on a symlinked project dir or a
  trailing slash. (fixed — both spellings tried, four cases; refuted by
  removing the `%/` strip and the physical prefix)
- r8: (verifier) The file's "nothing here can produce exit 2" is not a
  promise the file can keep — a bash parse error is status 2 before line 1
  runs. (fixed — `|| exit 0` in the registration, and the header says where
  the guarantee actually lives)
- r9: (verifier) The quiet banner printed before any finding matched, so an
  injection could read "This file has drawn review findings before:"
  followed by nothing but the summary. (fixed — the banner waits for a
  match, and quiet returns silent when there is none)
- r10: (verifier) Quiet output dropped the caveat that findings are
  attributed by COMMIT, so some may concern another file the same fix
  touched — the one caveat the reader of an unasked-for injection most
  needs. (fixed — it is in the quiet banner)
- r11: (verifier) The recorded `6774 / 6648 / 6846 ms` does not reproduce;
  the verifier measured 4538 / 4290 / 4260. Mine was taken before the
  `fb_report_path` rewrite. (fixed — re-measured on this tree today, 4536 /
  4724 / 4781, and the note says which tree the old figure was from)
- r12: (verifier) Cold start is ~4.5s, unbudgeted, with no `timeout` on the
  registration, and the already-seen marker was written after the walk — so
  a killed run paid the same seconds on the next edit, and the one after.
  (fixed — `"timeout": 20`, and the marker is written before the walk)
- r13: (verifier) This file said the cap ships "with the exact count
  omitted"; the opposite is true, the count is present and exact. (fixed —
  Decisions says what shipped)
- r14: (verifier) `feedback --quiet` with no path was read as a request for
  a file named `--quiet`. (fixed — `--quiet` in either position)

## Scope notes

- One file outside the plan's `scope:` — `.agents/docs/feedback.md`. It
  describes stage 4 as a bar the loop has to clear and named no machinery for
  it, which stopped being true in this diff. Two sentences naming the hook.
  Decided alone, small, flagged here.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_feedback` — the report this serves; where the quiet
  shape lands.
- `joharness.sh:fb_collect` — the one history walk the cache answers.
- `.agents/harness/handover-guard.sh` — stdin handling and fail-open.
