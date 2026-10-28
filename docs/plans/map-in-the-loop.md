---
plan: map-in-the-loop
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/map.sh, .claude/commands/map.md, shared:.agents/harness/AGENTS.md
---

## Goal

User ask: the folder map is part of the harness, and the harness itself
knows when and how to generate it. Today `docs/MAP.md` exists only if a human
types `/map`, so a consumer never gets a map on its own. Make the Loop own
it. `finish` refuses a merge that changes the product folder set (a folder
added or removed) while the map does not reflect it, and that includes a
consumer with product folders and no map at all. `/map` builds the map from
nothing and commits on the branch that asked, so the map lands in the same
pull request as the change. One line in Loop step 4 says both. Adoption is incremental (user ask): a
project that takes the harness late maps folders as branches create them,
never all at once, and an unmapped old folder never warns or blocks.

## Scope

- `joharness.sh` — new `finish_map <ref>`, run by `cmd_finish` as check
  `map` after `workstream files`:
  - `map_scan nostale`. Empty product set: print `map: no product folders`,
    return 0.
  - DRIFT = the `missing` and `gone` rows; with no `docs/MAP.md`, every
    product folder counts as missing.
  - TOUCHED = every directory, and each ancestor, of a file the branch adds
    or deletes, measured from the merge base with `<ref>`.
  - Counts: a `missing` folder in TOUCHED that did not exist at the merge
    base (this branch created it); a `gone` folder that existed at the merge
    base and not at `HEAD` (this branch deleted it). Any count: print each
    row, then `run /map <these folders> on this branch: it brings them into
    docs/MAP.md`, and return 1. Otherwise
    print `map: reflects this branch` (plus `<n> drift rows this branch did
    not cause` when any) and return 0.
  - `stale` never fails.
- `joharness.sh` `lint_map`: warn on `gone` rows only. An unmapped folder
  is expected in a project that adopted the harness late.
- `.claude/commands/map.md`: `/map <folder>...` maps only the named
  folders (what `finish` names); bare `/map` maps every missing and stale
  folder. Also:
  - Step 1: `none` means the folder list printed under it is the work list,
    and the file starts with `# Map` and a blank line.
  - Step 5: on a branch you already claimed (the `finish` case), commit
    `docs/MAP.md` there. Otherwise branch from fresh `origin/main` and run
    Loop steps 5 and 7.
- `.agents/harness/AGENTS.md`, Loop step 4: replace the `docs/MAP.md`
  sentence with "`docs/MAP.md`: read it before grepping; absent or drifting =
  `/map` generates it (`finish` asks)."
- `.agents/harness/selftest/map.sh` — finish cases on the existing fixture,
  each on its own branch off `main`:
  - a branch adding a file in a new product folder with no map entry:
    `finish` fails naming `missing : <folder>/` and `run /map`;
  - the same branch after the map line is added: no map failure;
  - a branch only modifying a file in a mapped folder: no map failure,
    stale or not;
  - no `docs/MAP.md` and a branch adding a product folder: fails;
  - no product folders changed: no map failure;
  - a new file in an old unmapped folder: no map failure; a new subfolder
    under it: fails naming the subfolder only;
  - a branch deleting a mapped folder: fails naming `gone : <folder>/`;
  - `ci` does not warn on an unmapped folder.

## Assumptions

- A1: Nothing generates the map without a human — evidence: `grep -rn
  'MAP.md\|/map' .agents/harness/AGENTS.md .claude/commands` names only
  step 4's read and `map.md` itself — confidence: high.
- A2: `run_check` counts any return other than 0 or 3 as a failure —
  evidence: `joharness.sh:run_check` — confidence: high.
- A3: The canonical repo has no product folders, so its `finish` is
  unaffected — evidence: `./joharness.sh map` prints only `none — /map
  creates it` here — confidence: high.
- A4: Selftest fixtures that run `finish` add no files in product folders
  on a branch — confidence: low. `verify` re-takes it.

## Out of scope

- Generating `docs/MAP.md` in this repository: it has no product folders.
- A dispatch item, role or session-start line for the map.
- Failing on `stale`, or on drift a branch did not cause.

## Acceptance

- `./joharness.sh verify` — `0 failed`; the `joharness.sh map` topic prints
  PASS for each new finish case.
- The new cases fail without `finish_map`: remove its `run_check` line, run
  `./joharness.sh verify`, see them FAIL; restore. Recorded in `## Review`.
- `./joharness.sh ci` — `ci: pass`.
- `JOHARNESS_CHECKS=local ./joharness.sh finish` on this branch — `finish:
  pass`; with `-v`, the `map` check reads `map: no product folders`.

## Where to look

- `joharness.sh:map_scan` — the rows and counts it fills.
- `joharness.sh:cmd_finish` — where checks run.
- `joharness.sh:finish_adds` — a finish check's shape.
- `.agents/harness/selftest/map.sh:settle map` — the fixture to extend.
- `.claude/commands/map.md:Branch from fresh` — step 5.

## Traps

- `joharness.sh` and `.agents/harness/AGENTS.md` are shared with other
  plans: merge their lines in, never drop them.
- `.agents/harness/AGENTS.md` loads into every session: one sentence.
- Never skip, disable or quarantine a test to get green.
