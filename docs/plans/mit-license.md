---
plan: mit-license
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: LICENSE, README.md
---

## Goal

Repo ships no license file. Human asked for MIT. Without one, nothing in the
tree is legally reusable — consumer repos copy the harness by design, so the
grant has to be explicit.

## Scope

- `LICENSE` — MIT text, verbatim from the canonical template. Copyright holder
  = repo owner, Christian Westhoff. Year = 2026.
- `README.md` — one `## License` section naming the file, plus what the choice
  means for a consumer copy.

## Out of scope

- Per-file SPDX headers. Harness files land in consumer trees under those
  repos' own licenses; a header would follow the copy and misstate that.
- `package.json`, `pyproject.toml` or any manifest license field. Repo has no
  manifest.
- Relicensing or attributing third-party text already cited in
  `.agents/docs/caveman.md`. That note already names its upstream and its MIT
  terms.

## Acceptance

- `test -f LICENSE && head -1 LICENSE` — prints `MIT License`.
- `grep -c '## License' README.md` — prints `1`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: `ci` is what GitHub runs on every consumer sync, and the README link
  it lints is the one a consumer follows.

## Where to look

- `README.md` — section order; License goes last, after "Working in this repo".
- `.agents/docs/caveman.md` — style for the README sentence.

## Traps

- Trust counted numbers, never written numbers: read what `ci` and `verify`
  print, do not copy a pass total out of a doc.
- Retire this plan and the workstream file in the last commit BEFORE the pull
  request opens, never after the merge.
