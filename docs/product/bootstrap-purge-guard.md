---
requirement: bootstrap-purge-guard
priority: normal
---

<!-- Proposed by extensions-research session 2026-08-23. Merge = ratify.
Security-sweep follow-up (PR #25), filed so it outlives that merged
workstream file. -->

## Goal

`bootstrap-consumer.sh` whole-clone path deletes live workstream files
from the target. `sync-to-consumer.sh` refuses paths with a symlink
ancestor before writing; bootstrap's purge has no such guard — a symlink
inside the target can aim the delete outside it. Same rule both tools.

## Satisfied when

- Purge refuses a path with a symlink ancestor, sync's rule.
- Selftest case: symlinked docs dir in whole-clone target; purge refuses;
  nothing outside target touched. Skips on filesystems without symlinks,
  like existing cases.

## Constraints

- Sweep session measured (2026-08-23): deletion path Linux-only, not
  verified on Windows. Repro in sandbox before fix — no guessed patch.
