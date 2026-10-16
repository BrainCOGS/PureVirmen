#!/usr/bin/env python3
"""Check AI attribution in commits: humans author commits, AI help is disclosed.

Canonical copy: agent-tooling, hooks/check_ai_attribution.py. Repos vendor it as
.github/scripts/check_ai_attribution.py. Change the canonical copy (and its tests),
then copy it over; don't edit a vendored copy.

Rules
-----
1. AI help is disclosed with one trailer per agent, spelled exactly

       Assisted-by: <Harness>:<model>

   so `git log --grep='^Assisted-by: '` finds every AI-assisted commit.
   - <Harness> is one word: the agent harness (ClaudeCode, OpenCode, Codex, ...).
     Harnesses in KNOWN_HARNESSES have one spelling ("Claude Code" -> ClaudeCode).
     Any other harness is accepted as long as it is one word.
   - <model> is the exact model id the vendor's API uses, without a provider
     prefix: claude-opus-5-5, gpt-5.1-codex, gemini-3-pro, kimi-k2.6. Models of
     the vendors in MODEL_RULES are checked against that vendor's id format; any
     other model is accepted as long as it is one token with no "/".
2. AI agents and bots never appear in a commit as its author, its committer or a
   Co-authored-by/Signed-off-by, except the non-AI automation in AUTOMATION
   (Dependabot, GitHub Actions, the GitHub web UI, ...). See is_agent().
3. Commit messages carry no "Generated with <agent>" lines; the trailer is the
   disclosure.

Usage
-----
    check_ai_attribution.py COMMIT_MSG_FILE   commit-msg hook: checks the message
                                              and the author/committer git is about
                                              to use
    check_ai_attribution.py --since BASE [--head REV]
                                              CI: checks every commit in BASE..REV
                                              (REV defaults to HEAD; only REV if
                                              BASE is empty, all zeros or unknown).
                                              On pull_request events pass the PR's
                                              head SHA: HEAD is GitHub's synthetic
                                              merge commit, not a real one.

Standard library only, Python >= 3.9, so it runs from prek/pre-commit or a bare
`python3` on any OS.
"""

# Vendored copies must stay byte-identical to the canonical one, so the repos'
# own linters and formatters (each with its own rules and line length) leave this
# file alone. agent-tooling checks it with `ruff check --ignore-noqa`.
# ruff: noqa
# fmt: off
from __future__ import annotations

import argparse
import re
import subprocess
import sys

# --- Harnesses ---------------------------------------------------------------
# Known harnesses, keyed by their name lowercased with everything but letters and
# digits removed. A harness that normalizes to a key must be spelled as the value.
KNOWN_HARNESSES = {
    "claudecode": "ClaudeCode",
    "claudedesktop": "ClaudeDesktop",
    "claudeai": "ClaudeAI",
    "opencode": "OpenCode",
    "codex": "Codex",
    "codexcli": "Codex",
    "copilot": "Copilot",
    "githubcopilot": "Copilot",
    "cursor": "Cursor",
    "geminicli": "GeminiCLI",
    "aider": "Aider",
    "pi": "Pi",
    "windsurf": "Windsurf",
    "junie": "Junie",
    "amp": "Amp",
    "goose": "Goose",
    "cline": "Cline",
    "roocode": "RooCode",
    "kilocode": "KiloCode",
    "zed": "Zed",
}

HARNESS_RE = re.compile(r"[A-Za-z][A-Za-z0-9.+-]*")

# --- Models ------------------------------------------------------------------
# (what marks a model as this vendor's, the vendor's id format, an example).
# Ids are the API's: lowercase, no spaces, no provider prefix.
MODEL_RULES = [
    (
        re.compile(r"claude|opus|sonnet|haiku|fable", re.I),
        re.compile(r"claude(?:-[a-z0-9]+)+"),
        "claude-opus-5-5",
    ),
    (
        re.compile(r"^(?:gpt|chatgpt|o\d|codex)", re.I),
        re.compile(r"(?:gpt|chatgpt|o\d+|codex)[a-z0-9.-]*"),
        "gpt-5.1-codex",
    ),
    (
        re.compile(r"gemini|gemma", re.I),
        re.compile(r"(?:gemini|gemma)-[a-z0-9.-]+"),
        "gemini-3-pro",
    ),
    (re.compile(r"kimi", re.I), re.compile(r"kimi-[a-z0-9.-]+"), "kimi-k2.6"),
    (re.compile(r"glm", re.I), re.compile(r"glm-[a-z0-9.-]+"), "glm-5.1"),
    (
        re.compile(r"deepseek", re.I),
        re.compile(r"deepseek-[a-z0-9.-]+"),
        "deepseek-v3.2",
    ),
    (re.compile(r"qwen", re.I), re.compile(r"qwen[a-z0-9.-]+"), "qwen3-coder-plus"),
    (re.compile(r"grok", re.I), re.compile(r"grok-[a-z0-9.-]+"), "grok-code-fast-1"),
    (
        re.compile(r"mistral|codestral|devstral", re.I),
        re.compile(r"(?:mistral|codestral|devstral)[a-z0-9.-]*"),
        "devstral-medium-2507",
    ),
]

# --- Identities ----------------------------------------------------------------
# Non-AI automation that may author or commit (matched on the name, lowercased).
AUTOMATION = {
    "dependabot[bot]",
    "github-actions[bot]",
    "renovate[bot]",
    "pre-commit-ci[bot]",
    "github",  # committer of web UI edits and merge-button merges
    "web-flow",
}

# Email domains that only AI agents commit from.
AGENT_EMAIL_DOMAINS = {
    "anthropic.com",
    "openai.com",
    "cursor.com",
    "cursor.sh",
    "aider.chat",
    "codeium.com",
    "windsurf.com",
    "devin.ai",
    "cognition.ai",
    "moonshot.ai",
    "moonshot.cn",
    "z.ai",
    "zhipuai.cn",
    "deepseek.com",
    "mistral.ai",
    "x.ai",
    "opencode.ai",
    "ampcode.com",
    "sweep.dev",
}

# Names (or GitHub logins) that are AI agents. Matched at the start of the name,
# so "Claude", "Claude Opus 5.5" and "Copilot" match but a person whose surname
# is one of these words does not. First names that are also agent names (Devin,
# Kimi, Jules, Cody, Amp) are left out on purpose: those agents commit from a
# bot account or an agent domain, which the other checks catch.
AGENT_NAME_RE = re.compile(
    r"^(?:claude|anthropic|copilot|github copilot|codex|openai|chatgpt|gpt-?\d"
    r"|gemini|cursor(?: ?agent)?|aider|windsurf|codeium|cascade|junie|opencode"
    r"|qwen|deepseek|glm-?\d|tabnine|amazon q|sweep)\b",
    re.I,
)
# "Jane Doe (aider)", the author name aider writes by default, and the like.
AGENT_SUFFIX_RE = re.compile(r"\((?:aider|ai|bot|agent|assistant)\)\s*$", re.I)
# A GitHub App account: login[bot], or its <id>+login[bot]@users.noreply.github.com.
BOT_RE = re.compile(r"\[bot\]", re.I)
NOREPLY_LOGIN_RE = re.compile(
    r"^(?:\d+\+)?(?P<login>[^@]+)@users\.noreply\.github\.com$", re.I
)


def is_agent(name: str, email: str) -> str | None:
    """Why this identity is an AI agent or a non-allowed bot, or None for a person."""
    name, email = name.strip(), email.strip().lower()
    if name.lower() in AUTOMATION:
        return None
    if BOT_RE.search(name) or BOT_RE.search(email):
        return "a bot account (only the automation in AUTOMATION may commit)"
    domain = email.rpartition("@")[2]
    if any(domain == d or domain.endswith("." + d) for d in AGENT_EMAIL_DOMAINS):
        return f"an AI vendor's address ({domain})"
    m = NOREPLY_LOGIN_RE.match(email)
    if m and AGENT_NAME_RE.match(m["login"]):
        return f"an AI agent's GitHub account ({m['login']})"
    if AGENT_NAME_RE.match(name) or AGENT_SUFFIX_RE.search(name):
        return f"an AI agent's name ({name})"
    return None


# --- Messages ------------------------------------------------------------------
# A trailer-like line: "Key: value" at the start of the line.
KEY_RE = re.compile(r"^(?P<key>[A-Za-z][A-Za-z _-]*?)\s*:\s*(?P<value>.*)$")
IDENT_RE = re.compile(r"^(?P<name>.*?)\s*<(?P<email>[^>]*)>\s*$")
ASSISTED_RE = re.compile(r"Assisted-by: (?P<harness>[^\s:]+):(?P<model>\S+)")
IDENTITY_KEYS = {"coauthoredby", "signedoffby"}
GENERATED_RE = re.compile(r"^\W{0,4}generated (?:with|by)\b", re.I)
AGENT_WORD_RE = re.compile(
    r"\b(?:claude|anthropic|copilot|codex|openai|chatgpt|gpt|gemini|cursor|aider"
    r"|windsurf|codeium|junie|opencode|kimi|qwen|deepseek|glm|grok|devin|jules|ai)\b",
    re.I,
)
SCISSORS = "------------------------ >8 ------------------------"

FORMAT_HINT = "write it as `Assisted-by: <Harness>:<model>`, e.g. `Assisted-by: ClaudeCode:claude-opus-5-5`"


def _norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def check_assisted_by(line: str) -> list[str]:
    m = ASSISTED_RE.fullmatch(line)
    if not m:
        return [f"malformed Assisted-by trailer; {FORMAT_HINT}"]
    harness, model = m["harness"], m["model"]
    errors = []
    canonical = KNOWN_HARNESSES.get(_norm(harness))
    if canonical and harness != canonical:
        errors.append(f"spell the harness `{canonical}`, not `{harness}`")
    elif not canonical and not HARNESS_RE.fullmatch(harness):
        errors.append(
            f"the harness must be one word (letters, digits, . + -), not `{harness}`"
        )
    if "/" in model:
        errors.append(
            f"drop the provider prefix from the model: `{model.rpartition('/')[2]}`"
        )
    else:
        for vendor, id_re, example in MODEL_RULES:
            if vendor.search(model):
                if not id_re.fullmatch(model) or not re.search(r"\d", model):
                    errors.append(
                        f"use the exact model id (like `{example}`), not `{model}`: "
                        "lowercase, hyphens, no display name"
                    )
                break
    return errors


def message_lines(message: str, comment_char: str = "#") -> list[tuple[int, str]]:
    """(line number, text) for the lines git keeps: no comments, nothing below the scissors."""
    out = []
    for i, line in enumerate(message.splitlines(), 1):
        if line.startswith(comment_char) and SCISSORS in line:
            break
        if line.startswith(comment_char):
            continue
        out.append((i, line.rstrip("\r")))
    return out


def check_message(message: str, comment_char: str = "#") -> list[str]:
    errors = []
    for n, line in message_lines(message, comment_char):
        m = KEY_RE.match(line)
        key = _norm(m["key"]) if m else ""
        if key == "assistedby":
            errors += [f"line {n}: {e}\n    {line}" for e in check_assisted_by(line)]
        elif key in IDENTITY_KEYS:
            ident = IDENT_RE.match(m["value"])
            name, email = (ident["name"], ident["email"]) if ident else (m["value"], "")
            why = is_agent(name, email)
            if why:
                errors.append(
                    f"line {n}: {m['key']} names {why}. AI agents are not authors: "
                    f"remove the line and disclose the help with Assisted-by instead\n    {line}"
                )
        elif GENERATED_RE.match(line) and AGENT_WORD_RE.search(line):
            errors.append(
                f"line {n}: remove the 'Generated with' line; the Assisted-by trailer "
                f"is the disclosure\n    {line}"
            )
    return errors


def check_identities(author: tuple[str, str], committer: tuple[str, str]) -> list[str]:
    errors = []
    for role, (name, email) in (("author", author), ("committer", committer)):
        why = is_agent(name, email)
        if why:
            errors.append(
                f"the commit {role} `{name} <{email}>` is {why}. Commit as yourself and "
                "disclose AI help with Assisted-by. To re-author commits on a branch: "
                "git rebase -x 'git commit --amend --no-edit --reset-author "
                '--trailer "Assisted-by: <Harness>:<model>"\' <base>'
            )
    return errors


# --- Git -----------------------------------------------------------------------
def _git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], check=True, capture_output=True, text=True, encoding="utf-8"
    ).stdout


def _ident(var: str) -> tuple[str, str] | None:
    try:
        m = IDENT_RE.match(_git("var", var).rsplit(" ", 2)[0])
    except (subprocess.CalledProcessError, OSError):
        return None  # no identity configured; git itself will complain
    return (m["name"], m["email"]) if m else None


def _comment_char() -> str:
    try:
        c = _git("config", "core.commentChar").strip()
    except subprocess.CalledProcessError:
        return "#"
    return c if len(c) == 1 else "#"


def check_msg_file(path: str) -> list[str]:
    with open(path, encoding="utf-8", errors="replace") as f:
        errors = check_message(f.read(), _comment_char())
    author, committer = _ident("GIT_AUTHOR_IDENT"), _ident("GIT_COMMITTER_IDENT")
    if author and committer:
        errors += check_identities(author, committer)
    return errors


def check_since(base: str, head: str = "HEAD") -> list[str]:
    known = base and set(base) != {"0"}
    if known:
        try:
            _git("rev-parse", "--quiet", "--verify", f"{base}^{{commit}}")
        except subprocess.CalledProcessError:
            known = False
    if not known:
        print(
            f"check_ai_attribution: base {base!r} unknown, checking {head} only",
            file=sys.stderr,
        )
    commits = _git(
        "rev-list", f"{base}..{head}" if known else "-1", *([] if known else [head])
    )
    commits = commits.split()
    errors = []
    for sha in commits:
        an, ae, cn, ce, body = _git(
            "show", "-s", "--format=%an%x00%ae%x00%cn%x00%ce%x00%B", sha
        ).split("\0", 4)
        errs = check_identities((an, ae), (cn, ce)) + check_message(body)
        errors += [
            f"{sha[:10]} {body.splitlines()[0] if body else ''}\n  {e}" for e in errs
        ]
    print(f"check_ai_attribution: checked {len(commits)} commit(s)", file=sys.stderr)
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "msg_file", nargs="?", help="commit message file (commit-msg hook)"
    )
    group.add_argument(
        "--since", metavar="BASE", help="check the commits in BASE..--head"
    )
    parser.add_argument(
        "--head", default="HEAD", help="last commit to check (default HEAD)"
    )
    args = parser.parse_args(argv)
    if args.since is not None:
        errors = check_since(args.since, args.head or "HEAD")
    else:
        errors = check_msg_file(args.msg_file)
    for e in errors:
        print(e, file=sys.stderr)
    if errors:
        print(
            "\nAI attribution: humans author commits; AI help is disclosed with one "
            "`Assisted-by: <Harness>:<model>` trailer per agent. See the docstring of "
            "check_ai_attribution.py.",
            file=sys.stderr,
        )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
