# Changelog

## 0.1.1

Fixes first-run friction found while trying the plugin on a new repo.

- `/queue:init` handles an empty repo: with no commits yet, it pushes the setup as the first
  commit on the default branch instead of failing to open a pull request.
- `/queue:init` switches back to the default branch after opening its pull request, and the
  recap names the setup branch. With no `origin` remote it commits on the default branch and
  says how to add a remote and push; in a folder that is not a git repo, or a repo already set
  up, it stops, changes nothing and says what to run next.
- `/queue:init` and `/queue:end` say why no pull request was opened when `gh` is missing or
  signed out, with the fix and a compare link.
- `/queue:end` without a worktree moves the base branch back to `origin/<base>` after carrying
  unpushed session commits onto the session branch, so `git pull` after a squash merge
  fast-forwards instead of diverging.
- `/queue:init` and `/queue:end` remind you to run `git switch <base>` and `git pull` after
  merging. `/queue:end` names the branch when it switched to a new one.
- Docs no longer tell you to type `/queue:end` after every session: spec, build, audit and meta
  already run it as their last step. The `CLAUDE.md` work-queue section that `/queue:init` writes
  says the same.
- Docs explain that a line added to `QUEUE.md` by hand must be committed before the next
  session, and how to recover when it blocks `git pull`, including a conflict on
  `git stash pop`.
- The starter `QUEUE.md` no longer tells you to copy it and delete the examples, which
  `/queue:init` already does.

## 0.1.0

- First release as a Claude Code plugin, `queue`. The commands are Brett Ragozzine's
  queue-lanes session commands: `/queue:build`, `/queue:spec`, `/queue:audit`, `/queue:meta`
  and `/queue:end`.
- New `/queue:init` sets a repo up: places `QUEUE.md`, ignores session worktrees, brings the
  existing backlog into `## Inbox` and adds the work-queue section to `CLAUDE.md`.
- `/queue:end` lands the session through a pull request against the repo's default branch.
  A repo that wants the original direct push sets `Land: push` in its `## /end in this repo`
  section.
- The commands hand bounded work to the architect-crew plugin's scout, runner and builder.
  The kit's own copies of those agents are gone; without architect-crew, the session does the
  work itself.
- MIT license.
