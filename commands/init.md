---
description: Set the repo up for queue lanes - place QUEUE.md, ignore session worktrees, bring the backlog into the Inbox, add the work-queue section to CLAUDE.md
---

**Purpose: after this, any teammate can open a session with `/queue:spec` or `/queue:build` and it knows what to do.** One person runs it once per repo (or once per project folder in a monorepo). Be concise; do the work.

If `$ARGUMENTS` is given, it is where the backlog lives (a file such as `TODO.md`, a list pasted in, or a link) or the folder to set up.

1. **Check first.** Run `git status --short` and `git rev-parse --show-toplevel`. If the folder is not a git repo, stop and change nothing: say "This folder is not a git repo. Run `git init -b main` (and `git remote add origin <url>` if it has a GitHub repo), then `/queue:init` again." If a `QUEUE.md` already exists at one of the lookup paths (below), stop and change nothing: say "Already set up: the queue is at `<path>`." and give the next step: `Next: /queue:spec` if its `## Inbox` or `## Spec` has items, else `Next: /queue:build` if `## Build` has rows; if every lane is empty, say "The queue is empty; add your first ideas to `## Inbox`." and end with `Next: /queue:spec`. Find the default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, else `git symbolic-ref --short refs/remotes/origin/HEAD` without the `origin/` prefix, else `main`. Then check whether the repo is empty: it is when `git rev-parse --verify HEAD` fails (no commits yet) or `git ls-remote --heads origin <default branch>` prints nothing (the remote has no default branch yet). Note too whether `git remote get-url origin` fails (no remote). Step 6 lands a repo with no remote, or an empty repo, differently.

2. **Place the queue.** Lookup order the commands use: the nearest `QUEUE.md` from the launch folder up to (not including) the repo root, then `Documentation/planning/QUEUE.md`, then `QUEUE.md` at the repo root. Pick the path:
   - launched in a monorepo project folder: `<folder>/QUEUE.md`;
   - else, if the repo has a `Documentation/` folder: `Documentation/planning/QUEUE.md`;
   - else `QUEUE.md` at the repo root.

   Copy `${CLAUDE_PLUGIN_ROOT}/templates/QUEUE.md` there. Set the title line to the project's name. Delete the example rows under `## Build`, `## Spec`, `## Meta` and `## Audit`; keep the headings, the "How it works" notes and the comment blocks. If the template file can't be read, write the file yourself with, top to bottom: `# QUEUE — <project>`, `## ▶ NEXT SESSION — START HERE (written <today>)`, `## Settled`, `## Inbox`, `## Build`, `## Spec`, `## Meta`, `## Audit`.

3. **Ignore session worktrees.** If `git check-ignore -q .claude/worktrees/x` fails, append `.claude/worktrees/` to `.gitignore`.

4. **Bring the backlog in.** Copy every open item the repo already tracks (a `TODO.md` or similar, what `$ARGUMENTS` points to, open items the user names) into `## Inbox`, one line each: `- (YYYY-MM-DD) <item> — <source link>`. Keep links to the source. Sort nothing: `/queue:spec` triages the Inbox. If a `TODO.md` or similar exists, ask whether to delete it or add a line at its top pointing to the queue, so the team keeps one list. Ask before reading an outside tracker; never write to one.

5. **Point `CLAUDE.md` at it.** Add this section to the repo's `CLAUDE.md` (create the file if there is none), with the real queue path and default branch. Leave any existing `## /end in this repo` section as it is and add only the `Land:` line if it has none.

   ```markdown
   ## Work queue

   All pending work lives in `<queue path>`, sorted into lanes. Open a session with
   `/queue:build`, `/queue:spec`, `/queue:meta` or `/queue:audit`; each session wraps itself
   with `/queue:end` (type it only if a session stopped before wrapping).

   Git rules (several sessions can share this repo):
   - Stage and commit explicit paths: `git commit -m "..." -- <paths>`.
   - Avoid `git add .`, `git commit -a` and a bare `git commit`.
   - Commit small; `/queue:end` opens the pull request.

   ## /end in this repo

   - Land: pull request against `<default branch>`
   ```

   `Land: push` instead tells `/queue:end` to merge into the launch branch and push directly, for a repo where one person works alone on `main`.

6. **Land the setup.** Stage explicit paths only (the queue, `.gitignore`, `CLAUDE.md`, and a removed or edited `TODO.md`). Commit `[Docs]: add queue lanes (QUEUE.md, CLAUDE.md work-queue section)` with explicit paths.
   - **No `origin` remote** (step 1): there is nowhere to push or open a pull request. Commit on the default branch (create it with `git switch -c <default branch>` if needed) and push nothing.
   - **Empty repo** (step 1): a pull request needs a base branch, and there is none yet. Commit on the default branch (create it with `git switch -c <default branch>` if needed) and run `git push -u origin <default branch>`. Open no pull request.
   - **Otherwise:** if you are on the default branch, run `git switch -c queue-init-<YYYYMMDD>` before committing. Push, and open a pull request against the default branch with `gh pr create`. If `gh` is missing or not signed in (`gh auth status` fails), open no pull request; note which, and print the compare link (`<repo URL>/compare/<default branch>...queue-init-<YYYYMMDD>`, the repo URL from `git remote get-url origin` without `.git`, with an SSH form `git@github.com:<owner>/<repo>` written as `https://github.com/<owner>/<repo>`). Then run `git switch <default branch>`, so the user is not left on the setup branch; the setup is already pushed.

7. **Recap.** The queue path, how many Inbox items came in, and where the setup landed. Fill in every branch name and path; print no `<placeholder>`. End with the `Next:` line.
   - **No `origin` remote:** "Setup committed on `<default branch>` locally; nothing pushed, because the repo has no `origin` remote. To publish it: `git remote add origin <url>`, then `git push -u origin <default branch>`." Then `Next: /queue:spec — turn the Inbox into Build rows.`
   - **Empty repo:** "Setup pushed straight to `<default branch>` as the repo's first commit; no pull request, because an empty repo has no branch to open one against." Then `Next: /queue:spec — turn the Inbox into Build rows.`
   - **Otherwise:** the pull request link, and "Setup was committed on `queue-init-<YYYYMMDD>` and pushed; you are back on `<default branch>`." Without `gh`, say the one cause that applies and its fix: "No pull request was opened because `gh` is not installed; install it from https://cli.github.com, or open it here: <compare link>." or "No pull request was opened because `gh` is not signed in; run `gh auth login`, or open it here: <compare link>." Then "After you merge the pull request: `git switch <default branch>` and `git pull`." Then `Next: /queue:spec — turn the Inbox into Build rows.`
   - When the Inbox is empty, add one line before `Next:`: "The Inbox is empty; add your first ideas to `## Inbox` before running `/queue:spec`."
