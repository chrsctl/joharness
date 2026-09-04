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

- `LICENSE` — MIT text, verbatim from the canonical template. Copyright line
  names the repo owner, Christian Westhoff, and contributors — `git log
  --format=%an | sort -u` lists three humans plus Claude, so a sole holder
  would be false. Year = 2026, the only year the history has.
- `README.md` — one `## License` section naming the file, plus what the choice
  means for a consumer copy.

## Out of scope

- Per-file SPDX headers. Harness files land in consumer trees under those
  repos' own licenses; a header would follow the copy and misstate that.
- `package.json`, `pyproject.toml` or any manifest license field. Repo has no
  manifest.
- Attribution for third-party text distilled in `.agents/docs/caveman.md`.
  That file names its upstream and that the upstream is MIT, but carries no
  holder or notice text. Whether the distilled rules are a substantial portion
  is a judgement for the human, not scope for adding a license file.
- Shipping a notice to consumer repos. `sync-to-consumer.sh` copies harness
  files with no notice, and `bootstrap-consumer.sh` purges joharness's own
  docs but leaves a root `LICENSE` in a whole clone. Both are real gaps and
  both need their own plan; a fix here would either overwrite a consumer's
  license or claim this repo's copyright over consumer product code.

## Acceptance

- `test -f LICENSE && head -1 LICENSE` — prints `MIT License`.
- `grep -c '## License' README.md` — prints `1`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: nothing. `ci` reports this plan `canonical-only` and that is correct —
  a root `LICENSE` and this repo's own README reach no consumer. Recorded so
  the verdict is not read as a missed bar.

## Where to look

- `README.md` — section order; License goes last, after "Working in this repo".
- `.agents/docs/caveman.md` — style for the README sentence.

## Traps

- Trust counted numbers, never written numbers: read what `ci` and `verify`
  print, do not copy a pass total out of a doc.
- Retire this plan and the workstream file in the last commit BEFORE the pull
  request opens, never after the merge.
