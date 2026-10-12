# Retired stems

Not a plan: every plan reader skips this file, as it skips `TEMPLATE.md` and
`README.md`. A carried branch plan's retire lands here (built or found done),
one line per stem:

    - <stem> <ref>

`<ref>` names the retire: the retiring branch, its pull request (`#N`) or
commit. `ci` refuses a diff that adds `docs/plans/<stem>.md` for a stem listed
here. Removing the line is the human override. Protocol:
`.agents/docs/orchestrated.md`, "A spawn the human orders carries the plan".
