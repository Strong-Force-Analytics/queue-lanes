---
description: Check the repo is ready for a chain run (spec, build, audit with no person) and print the one line that starts it
type: Runbook
title: /queue:chain — Chain readiness command
tags: [queue-lanes, command]
status: draft
generated: { by: "human:Russel", at: "2026-11-26T15:35:00Z" }
---

This command **checks and prints; it never starts the chain.** A chain runs lane after lane, each in a fresh headless session, so it is started by a script in the terminal, which waits for free and has no time limit. A Claude session that started it would sit waiting, using tokens, and closing it could stop the chain halfway.

Run each check, one line each, `ok` or what to fix:

1. **A queue.** `QUEUE.md` is found the way every lane finds it, and `## Inbox`, `## Spec` or `## Build` holds work.
2. **A clean tree on the base branch.** `git status --porcelain` prints nothing, and the current branch is the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`, without `origin/`). The chain branches from here.
3. **GitHub signed in.** `gh auth status` succeeds: the runner opens the pull request at the end.
4. **The plugin loads headless.** `claude plugin list` shows `queue@`. A run with plugins turned off would start sessions that cannot open a lane; the runner also stops when a session writes no new handoff block.
5. **Tests run from a worktree.** Find the test command in `CLAUDE.md`. Each lane works in its own worktree, which has no gitignored folders, so a command such as `.venv/Scripts/python -m pytest` fails there. If it calls a gitignored folder by a relative path, say so and give the fix from `/queue:init` step 5 (the launch tree's absolute path).
6. **Low risk.** Ask the user, in one line, to confirm the repo neither trades, moves money nor publishes anything. A chain has no person watching.

If every check is `ok`, print the line to paste into a terminal (Git Bash on Windows), with the real paths filled in:

```bash
bash "<this plugin's folder>/scripts/run-chain.sh" "<repo path>" 6 8
```

- The plugin's folder is `${CLAUDE_PLUGIN_ROOT}`; if that reads empty, take the newest match of `ls -d ~/.claude/plugins/cache/*/queue/*/` .
- `6` is the most sessions and `8` the most dollars (list price) for the whole chain. Each session is also capped at 2 dollars, 80 turns and 20 minutes, and a third failed audit stops the chain.
- When the test command needs a tool the runner does not allow by default, put it in front: `EXTRA_TOOLS="Bash(<test command> *)"`. The runner allows no open shell.
- Add `FIRST_LANE=build` in front to skip spec when `## Build` already holds the rows.

Then say what happens: the runner makes branch `chain-<date-time>` from the base, runs spec, build and audit on it as each handoff's `Next lane` says, and opens one pull request for a person to review and merge. It never pushes to the base and never merges. The log lands next to the repo in `chain-<date-time>/`.
