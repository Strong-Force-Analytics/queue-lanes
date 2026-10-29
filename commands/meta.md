---
description: Open a meta session — improve how the work gets done, from the Meta lane of the queue
---

This is a **meta** session. The subject is the process itself: the commands, skills, conventions, tooling, and workflow that produce the work, rather than the work's own content. Be concise; ship a change, never a proposal.

**Print `Session start: <git rev-parse --short HEAD>` in your first reply.** `/queue:end` uses that commit as the session's starting point.

**Work in a worktree.** Every lane runs in its own worktree, so the launch tree only receives work through `/queue:end`. Before any other tool call, call `EnterWorktree` with `name` = `<lane>-<N>-<YYYYMMDD>` (for example `meta-2-20260925`), where `<N>` is the lowest number no live `<lane>-*` entry in `git worktree list` already uses. Read its result text. `Created` means the name is yours. `Resumed` means another terminal took the name first: call `ExitWorktree` with `action: "keep"` at once, then bump `<N>` and retry. Never enter an existing worktree by `path`, because that puts two sessions in one tree. Add the worktree path and the launch branch to the `Session start:` line. Skip this only when the session is already in a worktree. If the `EnterWorktree` tool is unavailable, or the repo does not use worktrees, skip this step and work in the current checkout; the explicit-path git rules still apply. **Keep the launch folder.** Before `EnterWorktree`, run `git rev-parse --show-prefix` in the launch directory. When it prints a subfolder (`apps/web/`), the worktree still opens at the repo root, so `cd` into that same subfolder inside it right after entering, write the subfolder and its queue's absolute path on the `Session start:` line, and read that queue by that path for the rest of the session. Otherwise a lane launched in a monorepo project folder reads the root queue and the root `CLAUDE.md`. Tell any subagent you dispatch the worktree path.

**Claim your item right after reading the queue, so a parallel session skips it.** Run `git config --get-regexp 'branch\..*\.description'` and pass over any item a live `<lane>-*` worktree already holds. Record yours with `git config branch.<your-branch>.description "<item title, first ~80 chars>"` (branch config lives in the shared `.git/config`, so every worktree sees it). Verify by re-running the regexp: if another live `<lane>-*` branch holds the same item, the lower `<N>` keeps it, and the higher one runs `git config --unset branch.<your-branch>.description` and picks the next unheld item. Print `Claimed: <item>` once the claim stands. It is a record of what this terminal holds, rather than a gate.

**The queue contract (every opener).** A row is added on purpose, by the user or by the `/queue:spec` or `/queue:audit` session opened to write it, rather than as a by-product. A finished row is deleted in the commit that finishes it; the commit message is the record, so no `[done]` rows are kept. A project may cap the queue's size in its `CLAUDE.md` or a hook.

**Where a defect gets fixed.** The order of precedence is `CLAUDE.md` > `QUEUE.md` > `/queue:meta` > `/queue:audit` > `/queue:spec` > `/queue:build`. A fault at a high rung corrupts everything beneath it silently, so when something is wrong or keeps recurring, find the highest rung that governs it and fix it there. Climb only to the rung that is actually blocking, then come back down. `/queue:build` is the point of the other five: when two consecutive sessions have ended above `/queue:build`, the next one is `/queue:build` unless something genuinely blocks it, and a session that ends above `/queue:build` says so in its wrap.

1. **Find the queue.** The queue is the nearest `QUEUE.md` from the launch directory up to, but excluding, the repo root (a monorepo keeps one per project folder, e.g. `apps/web/QUEUE.md`); with none, `Documentation/planning/QUEUE.md`, then `QUEUE.md` at the repo root. Use that chain in every repo; invent no other location. **A root session leaves folder queues alone:** launched at the repo root, it reads, plans and edits nothing inside a subfolder that has its own `QUEUE.md`, and works only the root queue. When the root lane has nothing this session can take, it names each folder queue as where work sits (`web has its own queue — launch in apps/web`) and stops. That project is worked only from a session launched in its folder. If the repo has a briefing script (for example `scripts/brief.py`), run it for the queue `[HEAD]`, counts, working-tree state and the last full test run. Otherwise read the file's `## ▶ NEXT SESSION — START HERE` block, `## Settled`, and the lane sections (`## Inbox`, `## Build`, `## Spec`, `## Meta`, `## Audit`), and run `git status --short`.

2. **The capped files are this lane's job.** Report the size of each capped file (any file the project's `CLAUDE.md` or hook gives a byte cap) against its cap in one line. If any is over 80%, reducing it is part of this session, before the lane's item, since a full file blocks every session after it.

   Reduce by moving, rather than trimming prose. A capped file is an index: decisions, pointers and `file:line`. Measured evidence, a census, or a table of findings belongs in the project's docs or wiki, with one pointer line left behind. Deleting finished rows is the other lever; trimming wording destroys evidence.

   Every other session type pays only for its own addition: one line in, one line out, named in the commit. No session outside this lane runs a general trim.

3. **Leave `## Inbox` to `/queue:spec`.** Only `/queue:spec` triages the Inbox, so every new row goes through its packing step. Add Inbox lines as needed; leave existing ones where they are.

4. **Take the top item of `## Meta`.** That is this session's work. Read every item in the lane before choosing: file order is arrival order, rather than priority.

   Each item carries `Files`, `Guardrails` (the condition to hold so the change lands right), and `Done when`. Read all three before starting.

   **Fallback chain if the lane is empty:**
   1. The repo's cadence tooling output, if it has any (for example `tools/cadence.py`): run it and take what it flags as due.
   2. Else, the friction this project keeps repeating: a step done by hand more than twice, a rule in `CLAUDE.md` that keeps getting missed, a command whose fallback chain misfires, a script living in a scratchpad that belongs in the repo. Name the evidence, rather than a hunch.
   3. Else, say the Meta lane is empty, name what you checked, and ask.

5. **Apply the automation hierarchy.** Automated beats assisted beats manual. Before building anything, classify the friction: truly gated (needs a person, an account, a legal step, or has no API) or not yet automated (an API or hook exists, just unwired). Only the gated kind is real manual surface; automate the rest. Ask whether a native mechanism already covers it before writing a custom script.

6. **Make the change in the place that survives.** Edit the committed file (the command, skill, `CLAUDE.md`, hook or script in the repo), never an installed copy or a scratchpad.

7. **Sweep the references.** A process change that leaves its documentation stale is half-done: update every doc, index or file table that describes the behavior you just altered.

8. **Delete the item from `## Meta` in the same commit, and report** what changed and what it now saves.

Where a step calls for `scout` (large reads and tracing), `runner` (suites, builds, scripts) or `builder` (an already-decided edit), dispatch that subagent (optional subagents from the architect-crew plugin, dispatched as `architect-crew:scout`, `architect-crew:runner` and `architect-crew:builder`; without them, do the step in the main session). Review the diff an `architect-crew:builder` returns, rather than its summary.

**Wrap yourself.** When the work stops (the lane item is done, a stop line is hit, or context runs thin), as the session's last step: invoke the `queue:end` skill (the `/queue:end` command); if that is unavailable, tell the user to type `/queue:end`.

If `$ARGUMENTS` is provided, treat it as the meta topic to work, ahead of the lane's top item.
