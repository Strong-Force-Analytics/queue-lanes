# Changelog

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
