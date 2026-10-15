---
name: Agent bug report
about: Filed by an AI agent for an error reported on Slack
title: "[BUG]"
labels: ''
assignees: tabedzki

---

:robot: _AI text below_ :robot:

**Report**
Slack: <link to the message that reported the error>

```
<error text or traceback, verbatim>
```

**Regression test**
`<tests/path.py::test_name>` reproduces the error: it fails on `<base commit>` with the traceback above and passes with the fix.

**Root cause**
What is wrong in the code and why it produced this error, with `file.py:line` references.

**Linked PR**
<#PR number, opened with the regression test before the fix>
