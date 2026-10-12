# Retired stems

Not a plan: every plan reader skips this file, as it skips `TEMPLATE.md` and
`README.md`. A plan retired where it could not be deleted (a manager carried
a branch plan and found it done) lands here, one line per stem:

    - <stem> <ref>

`<ref>` is the pull request (`#N`) or commit that retired it. `ci` refuses a
diff that adds `docs/plans/<stem>.md` for a stem listed here. Removing the
line is the human override. Protocol: `.agents/docs/orchestrated.md`, "A spawn
the human orders carries the plan".
