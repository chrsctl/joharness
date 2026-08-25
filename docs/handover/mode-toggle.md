---
workstream: mode-toggle
status: in-progress
branch: claude/mode-toggle
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-24
next: Open PR once ci and verify are green on the merged base
---

## Goal

Requester asked to turn unsupervised mode on for a single session, and then
to turn it off again. Two routes already existed — `JOHARNESS_MODE=...` for
one command and `JOHARNESS_CONF=...` for one session — but neither survives
into a session already running, and in a managed container the environment
is configured per environment rather than per session. This adds a third
source between them: an untracked `.joharness-mode` marker, written and
cleared by `./joharness.sh mode <value>`.

## Decisions

- Marker lives in the git directory, not at the repo root. Git tracks
  nothing in there, so the marker cannot be committed in ANY checkout that
  syncs the harness — and a root-level file plus a `.gitignore` line only
  looks equivalent, because `.gitignore` is consumer-own and never synced.
  It also does not survive a clone, which is what makes "session-local"
  true in a fresh container.
- Marker file, not a second conf layer. `joharness.local.conf` would
  override every key and make each setting ask "which file won"; a
  single-purpose file holding one word answers only the question it is for.
  Path overridable by `JOHARNESS_MODE_FILE` so the selftest never writes
  into the checkout.
- Precedence environment, marker, conf — most immediate first. Environment
  keeps winning so a session can always be narrowed for one command even
  with a marker present, and `mode <value>` warns when it writes a marker
  the environment already overrides. A switch that silently did nothing
  would be worse than no switch.
- `mode default` clears rather than writing `supervised`. Clearing returns
  the checkout to whatever the repo says; writing `supervised` would pin it
  against a conf that later opts in.
- Refuses to write anything but the two words. A marker holding a typo
  resolves supervised, which is safe, but reads to a human as an opt-in
  that is not one — the same trap PR47 r4 already paid for on the review
  knob.
- Session start names the marker when autonomy came from it, with the
  clearing command. Session-local autonomy and a repo-wide opt-in look
  identical otherwise and deserve different reactions.
- Gitignored, and the selftest asserts `git check-ignore` agrees rather
  than trusting the pattern by eye.

## Rejected

- Letting `mode` write into `joharness.conf`. Tracked file, so "temporary"
  would be one forgotten `git add` away from permanent.
- A second full conf layer (`joharness.local.conf`). See Decisions; cuts
  against stating each fact once.
- Making the marker win over the environment. Narrowing for one command is
  the safety valve; a marker that outranked it would remove the only way to
  turn autonomy off without touching a file.

## Review

- r1: `mode <value>` written while `JOHARNESS_MODE` is set the other way
  changes nothing, because the environment outranks the marker. Silent, it
  would read as a successful toggle. Now warns, naming the environment
  value and the mode the session actually runs. Covered. (fixed)
- r2: a marker holding an unrecognised word failed closed but said nothing
  on the `mode` path. It goes through the same `mode_unrecognised`
  predicate as the other two sources, so it warns on stderr while stdout
  stays one clean word for the guard. Covered for `yes`, `1`,
  `Unsupervised`, empty and whitespace-only. (fixed)
- r4: security/correctness — the marker was `${ROOT}/.joharness-mode`,
  kept out of commits by a `.gitignore` line. But `.gitignore` is
  consumer-own and explicitly never synced
  (`.agents/scripts/sync-to-consumer.sh:26`), so every consumer would get
  this toggle WITHOUT the rule: a temporary opt-in one `git add -A` from
  becoming that repo's permanent setting, which is the exact failure the
  ignore rule existed to prevent. Moved into the git directory, where git
  tracks nothing and no cooperation from an unsynced file is needed. The
  test now asserts the real property — invisible to `git status` in a
  fixture with no `.gitignore` at all — instead of asserting that a
  pattern exists. (fixed)
- r5: does-it-reproduce — relocating it needed a fallback for a checkout
  that is not a git repo. Falls back to the root path, which is what the
  `.gitignore` entry now covers; both paths tested. (fixed)
- r3: the toggle is a session-granting-itself-autonomy path, and the
  boundary it would escape is the one stopping it editing
  `.agents/harness/`. Raised with the requester before building; they asked
  for both directions anyway. Mitigated rather than blocked: the marker is
  untracked, dies with the container, and session start says the autonomy
  is session-local and how to drop it. (wontfix — requester's call,
  reaffirmed 2026-08-24)

## Blockers

None. Depends on the mode gate, which merged as PR 51 before this branch
was pushed.

## Where to look

- `joharness.sh:mode_raw` — the three sources and their order.
- `joharness.sh:cmd_mode_set` — the write side, and what it refuses.
- `.agents/harness/selftest.sh`, "session-local marker" — both directions,
  the fail-closed cases, and the gitignore assertion.
