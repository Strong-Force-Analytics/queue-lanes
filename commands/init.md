---
description: Set the repo up for queue lanes - place QUEUE.md, ignore session worktrees, bring the backlog into the Inbox, add the work-queue section to CLAUDE.md
---

**Purpose: after this, any teammate can open a session with `/queue:spec` or `/queue:build` and it knows what to do.** One person runs it once per repo (or once per project folder in a monorepo). Be concise; do the work.

If `$ARGUMENTS` is given, it is where the backlog lives (a file such as `TODO.md`, a list pasted in, or a link) or the folder to set up.

1. **Check first.** Run `git status --short` and `git rev-parse --show-toplevel`. If a `QUEUE.md` already exists at one of the lookup paths (below), stop: say where it is and that the repo is already set up. Find the default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, else `git symbolic-ref --short refs/remotes/origin/HEAD` without the `origin/` prefix, else `main`. Then check whether the repo is empty: it is when `git rev-parse --verify HEAD` fails (no commits yet) or `git ls-remote --heads origin <default branch>` prints nothing (the remote has no default branch yet). Note too whether `git remote get-url origin` fails (no remote). Step 6 lands an empty repo differently.

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
   - **Empty repo** (step 1): a pull request needs a base branch, and there is none yet. Commit on the default branch (create it with `git switch -c <default branch>` if needed) and run `git push -u origin <default branch>`. Open no pull request. With no `origin` remote, commit locally only and tell the user to add a remote and push.
   - **Otherwise:** if you are on the default branch, run `git switch -c queue-init-<YYYYMMDD>` before committing. Push, and open a pull request against the default branch with `gh pr create`. If `gh` is missing, print the compare link instead. Then run `git switch <default branch>`, so the user is not left on the setup branch; the setup is already pushed.

7. **Recap.** The queue path, how many Inbox items came in, and where the setup landed:
   - **Empty repo:** "Setup pushed straight to `<default branch>` as the repo's first commit; no pull request." Next step: run `/queue:spec` to turn the Inbox into Build rows.
   - **Otherwise:** the pull request link, and "Setup was committed on `queue-init-<YYYYMMDD>` and pushed; you are back on `<default branch>`." Next step: once the pull request is merged, run `git switch <default branch>` and `git pull`, then run `/queue:spec` to turn the Inbox into Build rows.
