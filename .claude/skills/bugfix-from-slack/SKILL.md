---
name: bugfix-from-slack
description: Use when the user pastes or mentions an error (a traceback, a failed cron job or alert, a rig error, a Slack report) or you hit a bug while working in a BrainCOGS repo. Reproduces it with a regression test, files an agent bug report issue with the error exactly as the user pasted it, fixes it, commits with the standard Assisted-by trailer and opens a draft PR. All from the user's account.
---

# Report and fix an error in a BrainCOGS repo

Canonical copy: <https://github.com/BrainCOGS/agent-tooling>
(`skills/bugfix-from-slack/SKILL.md`). Repos vendor it byte-identical at
`.claude/skills/bugfix-from-slack/SKILL.md`; change it in agent-tooling and
re-run `bin/vendor`, don't edit a vendored copy.

Everything goes through the user's own account: commits (their git config),
the push (their credentials), and the issue and PR (their `gh` login). The agent
has no GitHub identity of its own. Humans author commits; AI help is disclosed
with an `Assisted-by` trailer, never credited as an author.

This applies to any bug you hit or are asked to fix in a BrainCOGS repo, not
only ones reported in Slack. The user's data pipelines
(U19-pipeline-python, U19-pipeline-matlab) and the Streamlit apps
(tech_calendar_streamlit) are where it matters most: always file the issue
before you change code there, even for a small fix. That is how bugs get logged.

## 0. Read the repo's instructions

Read the repo's `AGENTS.md` for how to run its tests, its version pins and any
other quirks. Find the default branch with
`gh repo view BrainCOGS/<repo> --json defaultBranchRef -q .defaultBranchRef.name`.

## 1. Reproduce with a regression test first

- Keep the error text exactly as the user pasted it (traceback, log lines).
  Don't paraphrase or trim it, and don't ask for or invent a Slack link.
- Write a test that fails the same way the report does, before you change any
  code. Run it and confirm it fails with that error on the base commit. Note the
  base commit's short SHA.
- Cover the corner cases around the bug too: empty, zero, `None`, one versus many,
  numpy arrays versus lists, missing keys.

## 2. File the issue

Fill in `.github/ISSUE_TEMPLATE/agent_bug_report.md` from the repo (the
canonical copy is `templates/agent_bug_report.md` in agent-tooling). Keep its
`:robot: _AI text below_ :robot:` line at the top and fill in every section:

- **Reported error**: the pasted error text in a code block, verbatim.
- **Regression test**: `path::test_name`, and that it fails on `<base sha>`
  with that error.
- **Root cause**: what is wrong and why, with `file.py:line` references.
- **Linked PR**: leave as `TBD` for now; step 5 fills it in.

```bash
gh issue create -R BrainCOGS/<repo> --title "[BUG] <one-line summary>" --body-file <issue.md>
```

Skip this step only if the repo has issues turned off (element-array-ephys,
element-calcium-imaging, iblapps). Put the same sections in the PR body instead.

## 3. Fix on a branch

- Branch from the default branch: `<user>/fix/<id>`, where `<user>` comes from
  `gh api user --jq .login`.
- Make the smallest fix that makes the regression test pass. Then run the full
  test suite and `uvx prek run --all-files`.

## 4. Commit as the user, with one trailer

Use Conventional Commits, and end the message with one trailer per agent:

```
fix: <summary>

<what was wrong, why, and how it's fixed>

Assisted-by: ClaudeCode:claude-opus-5-5
```

- `Assisted-by: <Harness>:<model>`. `<Harness>` is one word (`ClaudeCode` for
  Claude Code). `<model>` is the exact model ID the harness reports
  (`claude-opus-5-5`, never `claude-opus-5.5` or `Opus 5`), with no provider
  prefix.
- Never add `Co-authored-by` or `Signed-off-by` for an AI, or a
  `Generated with ...` line. Never commit with an AI's name or email as
  author or committer. If the harness adds its own commit or PR attribution
  text, turn it off (Claude Code: `"attribution": {"commit": "", "pr": ""}` in
  `~/.claude/settings.json`).

## 5. Push and open the PR

```bash
git push -u origin <branch>
gh pr create -R BrainCOGS/<repo> --base <default-branch> --head <branch> \
  --draft --title "fix: <summary>" --body-file <pr.md>
gh issue edit <issue> -R BrainCOGS/<repo> --body-file <issue.md>  # Linked PR: #<pr>
```

Always pass `-R BrainCOGS/<repo>`. The element repos are forks, so a bare
`gh pr create` targets the DataJoint upstream.

The PR body:
- starts with `:robot: _AI text below_ :robot:`
- has `Fixes #<issue>` (or, for a repo without issues, the **Reported error**,
  **Regression test** and **Root cause** sections from step 2)
- covers the problem, the fix, and the tests, including that the regression
  test failed before the fix
- ends with the same `Assisted-by` trailer

When the work is done, mark the PR ready (`gh pr ready ...`). Keep the
branch's commits clean: one or a few Conventional Commits, each with the
trailer, and no "fix typo" or "address review" commits (amend or fixup them
instead).

## Agents that commit as themselves

Some cloud agents (Copilot coding agent, other GitHub Apps) commit as a bot.
Before merging such a branch, a human re-authors the commits and adds the
trailer. CI fails until they do:

```bash
git rebase -x 'git commit --amend --no-edit --reset-author --trailer "Assisted-by: Copilot:<model>"' origin/<default-branch>
git push --force-with-lease
```
