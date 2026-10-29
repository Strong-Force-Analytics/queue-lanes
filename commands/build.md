---
description: Build lane - read the handoff block /queue:end left and start the work
---

Start this session from the handoff block the previous `/queue:end` wrote. Be concise; do the work, rather than describing it.

**Print `Session start: <git rev-parse --short HEAD>` in your first reply.** `/queue:end` uses that commit as the session's starting point.

`scout`, `runner` and `builder` below are optional subagents from the architect-crew plugin, dispatched as `architect-crew:scout`, `architect-crew:runner` and `architect-crew:builder`; without them, do the step in the main session.

This is the **build** lane, one of four session openers (`/queue:build`, `/queue:spec`, `/queue:meta`, `/queue:audit`) reading the same shared `QUEUE.md`. `/queue:build` always builds; it never re-classifies the session.

**The queue contract (every opener).** A row is added on purpose, by a person or by the `/queue:spec` or `/queue:audit` session opened to write it, rather than as a by-product. A finished row is deleted in the commit that finishes it; the commit message is the record, so no `[done]` rows are kept. A project may cap the queue's size in its `CLAUDE.md` or a hook.

## Claim a session group, then work in its worktree

Several `/queue:build` terminals may start at the same moment. The `## Build` lane is packed into labelled groups (`**Session N —**`), each with a Files line; a group is one terminal's work, its tasks in the order written. The claim is the worktree name: two worktrees cannot share a name, so the first session to create it owns the group.

1. Run `git worktree list` and read `QUEUE.md`. The group id is its label lowercased with "Session" dropped (`Session 3` -> `s3`). **In a folder queue** (a subfolder's own `QUEUE.md`), prefix the id with the folder name (`web-s1`), so one project's Session 1 never collides with another's; a folder queue with no `**Session N —**` labels is one group, the whole `## Build` lane, id from the `[HEAD]` row's label (`Build 2` -> `web-b2`). A folder group is held only by a worktree or commit subject carrying its full scoped id; the bare-number match below is for root groups. Put the scoped id in every commit subject. A folder session edits only its own folder and its own queue; the root `QUEUE.md` still governs root files. Match loosely: a group is held by any live `build-*` worktree whose name carries its id or bare number, or whose branch's `git log <launch-branch>..<branch> --format=%s` subjects name one of the group's row ids. A group whose Files overlap a held group's Files is held too. Also check other branches for the group's row ids (`git branch --list` and `git log` subjects) and open pull requests (`gh pr list --state open --json headRefName,title`); a row already built on another branch, or waiting in an open pull request, is held.
2. Pick the top group that is unheld, not blocked on a person, not owned by a teammate (a group or row marked `Owner: <name>` other than you is theirs: skip it and name the owner; teammates may work without these commands, so the marker is the only hold they leave), and whose "after Session N" condition (if any) is met because that worktree is gone. `$ARGUMENTS` naming a group or task overrides the pick; the same check still runs.
3. Call `EnterWorktree` with `name` = `build-<id>-<YYYYMMDD>` (for example `build-s2-20260107`) and read its result text. `Created` means the group is yours. `Resumed` or "already existed" means another terminal claimed it first: call `ExitWorktree` with `action: "keep"` at once, before any other tool call, then return to step 1 with that group marked held. The result text is the only safeguard that holds at any spacing.
   Then print `Claimed: <group label> - <group's first task>` before any other tool call.
4. The worktree branches from the current local HEAD. Add the worktree path, the launch branch and the group to the `Session start:` line; `/queue:end` rebases the branch onto the base branch, pushes it, opens the pull request and removes the worktree (with `Land: push`, it fast-forwards the launch branch and pushes instead). Skip when the session is already in a worktree. If the `EnterWorktree` tool is unavailable, or the repo does not use worktrees, skip this step and work in the current checkout; the explicit-path git rules still apply. **A worktree is the whole repo:** when the queue is a folder queue, `cd` into the same subfolder inside the worktree (`.claude/worktrees/<name>/apps/web`) before the first read, and write the subfolder and its queue's absolute path on the `Session start:` line, so the folder's own `CLAUDE.md` and queue stay the ones in force and `/queue:end` writes back to them. Subagents you dispatch inherit the worktree; tell them the path anyway.

No claimable group: say so, name what holds each one, and stop rather than editing a held file. Then name any folder queue (a monorepo project folder's own `QUEUE.md`) as where ready work may be: `web has its own queue — launch in apps/web`. Every lane runs in its own worktree; the launch tree only receives work through `/queue:end`.

## Steps

0. **Leave the inbox to `/queue:spec`.** `/queue:build` adds `## Inbox` lines when it finds something worth doing, and never turns them into rows: `/queue:spec` alone triages the Inbox, so every new row passes through its packing step and lands in the group that owns its files. If `## Inbox` holds items, say how many in one line, so the handoff names a `/queue:spec` pass. Then continue.

1. **Find the block.** Read the single `## ▶ NEXT SESSION — START HERE` block from `QUEUE.md` (lookup chain: the nearest folder `QUEUE.md` from the launch directory up to, but excluding, the repo root; then `Documentation/planning/QUEUE.md`; then the repo-root `QUEUE.md`), then its `## Settled` section.

   The handoff block is a thin pointer and the build detail lives in the `## Build` lane. Read the `[HEAD]` item: its **Files**, **Guardrails** and **Done when** lines are the concrete build, and its pre-step (if any) is action 1. The handoff block carries only the one thing and `Blocked on`; decisions live in `## Settled`. Take state (test counts, file sizes) from a tool's output, such as a briefing script the project provides, rather than from a number typed in the handoff block. Apply step 2's verification to the HEAD item's files and guardrails as well as the handoff block.

   **If the HEAD item or the handoff block carries a `**Parallel wave:**` line, dispatch the wave.** Send one `architect-crew:builder` per wave item, all in a single message so they run concurrently, giving each one its item's **Owns** / **Interface** / **Test** lines verbatim. Keep the integration work for yourself: write the hub file the wave line names, review every returned diff rather than its summary, and run each item's test before the wave's. Then move to the next wave. When a builder returns empty, send it another message before concluding there was nothing to do. Waves run in order; items inside a wave run at once.

2. **Verify the block before acting on it.** The block may be days old.
   - If **Blocked on** names something, check it now (a file read, a `gh` call, a grep, a workflow run) rather than assuming it is still true.
   - If **Actions** names files, confirm they exist and roughly match the description.
   - If verification changes anything the block claimed, say so before proceeding.

3. **State it back, briefly.** The one thing, the recommended model, and anything the verification changed. One paragraph of orientation, with no re-plan.

4. **Begin action 1 immediately.** Start the first concrete next action in the block; skip the plan and the menu.

4b. **Drain the claimed group.** The group is the session's unit, rather than its first row. After a row closes (its **Done when** passes, the tests for what the row touched are green, and it is committed with the row deleted), take the group's next row at once, without wrapping. Wrap only when the group is drained or a step-5 stop line is hit.

   **Test cadence.** Per row, run only the tests that cover the files it changed plus any test it added. Run the full suite once, when the group is drained and before invoking `queue:end`, since that is where this branch leaves for the base branch. Run it earlier only when a row touches code that many tests share (the test runner, a widely imported module, the build step). Changes no test reads (docs, queue edits) run no tests.

5. **Keep going through the follow-ons sharing this context.** When the one thing is done and committed, continue into the block's **Follow-ons sharing this context** in the order written, each as its own small unit of work with its own commit. They reuse the context action 1 already loaded, so this is the cheap stretch of the session. Stop at whichever comes first:
   - an item that needs a person: one tagged **blocked by** a pending decision, or any item whose completion turns on spend, credentials, publishing, an irreversible action, or a taste call,
   - an item whose verification (step 2) shows it no longer makes sense,
   - or the point where remaining context is too thin to do the next item well.

   **A pending decision stops only the items it blocks.** `Runs unattended through` names where the numbered actions stop; every follow-on tagged **independent** is still in play. If the block carries no **independent** / **blocked by** markers, decide per follow-on: blocked means the person's answer changes what gets built, and nothing weaker counts.

   Then say plainly where you stopped and why, and report the pending decision alongside the extra work. A batch that ends early because the ground moved is a good outcome reported honestly; continuing past a decision that belongs to a person is the failure.

   If the session was started to run unattended (the user said so, or chained `/queue:end` after `/queue:build`), stop at the same lines. A clean, committed stopping point is the deliverable. Working a follow-on the block listed is never "inventing work"; skipping one that nothing blocks wastes a session.

**If the block is missing, stale, self-contradictory, or too thin to act on:** say exactly what is missing and why you cannot start from it alone, and avoid guessing a plan. Add one `## Inbox` line to `QUEUE.md` naming which part of the handoff was inadequate, so a pattern across sessions is visible. The cause is a previous `/queue:end` that under-delivered.

**If the `## Build` lane and the handoff block are both empty but another lane has items:** say so, name which lane is loaded, and stop rather than doing spec, meta or audit work under `/queue:build`.

**Things waiting on a human.** If the project keeps an `OPEN_QUESTIONS.md` (an optional list of decisions or actions only a person can take), add a bullet there for anything this session leaves waiting, with the date and the row it unblocks. Add one only when a person is needed; a reversible call inside delegated work is yours to make.

**Wrap yourself.** When the work stops (the claimed group is drained, a stop line is hit, or context runs thin), as the session's last step: invoke the `queue:end` skill (the `/queue:end` command); if that is unavailable, tell the user to type `/queue:end`.

If `$ARGUMENTS` is provided, treat it as an override or added focus for what to work on instead of, or alongside, the block's one thing.
