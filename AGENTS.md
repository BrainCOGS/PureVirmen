# PureVirmen

A standalone ViRMEn with the transformation functions for the mini rigs (MATLAB,
with prebuilt MEX binaries). Run with `virmen` from MATLAB after adding the folder,
with subfolders, to the path.

## Tests

No automated tests. Say in the PR how you checked a change in MATLAB or on a
mini rig.

Lint: `uvx prek run --all-files` (the same as CI's Lint workflow). The hooks only look for secrets,
merge-conflict markers, workflow problems and the AI trailer; nothing reformats
MATLAB files. GitHub Actions are turned off in this repo, so CI doesn't run.

## Agent workflow

- Bugs: when you fix an error the user reported, first file an agent bug report issue from the user's account (`gh issue create -R BrainCOGS/PureVirmen`, template `.github/ISSUE_TEMPLATE/agent_bug_report.md`). Put the error exactly as the user pasted it under **Reported error**; don't ask for or invent a Slack link. Then fix it with the `bugfix-from-slack` skill (`.claude/skills/bugfix-from-slack/`, vendored from [agent-tooling](https://github.com/BrainCOGS/agent-tooling)); the PR says `Fixes #<issue>`. Commits, pushes, issues and PRs all go through the user's account.
- Commits end with one `Assisted-by: <Harness>:<model>` trailer per agent, e.g. `Assisted-by: ClaudeCode:claude-opus-5-5`. No AI co-authors, and no `Generated with` lines. `prek install` sets up the `ai-attribution` commit-msg hook (`.github/scripts/check_ai_attribution.py`, vendored from agent-tooling), and CI checks every commit of a PR.
- PRs target `master` on `BrainCOGS/PureVirmen`, opened from the user's own account.
