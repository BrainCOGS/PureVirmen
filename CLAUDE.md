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

- Errors reported in Slack: use the `bugfix-from-slack` skill (agent-tooling). The braincogs-claude-agent bot opens issues and PRs; commits and pushes are the user's.
- Commits end with one `Assisted-by: <Harness>:<model>` trailer per agent, e.g. `Assisted-by: ClaudeCode:claude-opus-5-5`. No AI co-authors, and no `Generated with` lines. `prek install` sets up the `ai-attribution` commit-msg hook (`.github/scripts/check_ai_attribution.py`, vendored from agent-tooling), and CI checks every commit of a PR.
- PRs target `master` on `BrainCOGS/PureVirmen`. Merge PRs the bot opened with **Rebase and merge**, not Squash: GitHub attributes a squash commit to the PR's opener.
