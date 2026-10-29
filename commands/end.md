---
description: Wrap the session — keep the top ideas, and leave the next session one handoff block it can act on alone
---

**Purpose: the next session starts cleanly from one block, and the session's best ideas persist in the queue.** The wrap stays fast: it records what the session learned and re-runs nothing. Be concise; do the work.

**Project steps.** If the project's `CLAUDE.md` has a `## /end in this repo` section, run its steps too; where it conflicts with this file, it wins.

**Queue lookup.** The queue is the one the session read: the nearest `QUEUE.md` from the launch folder up to, but excluding, the repo root (a monorepo project folder's own queue); else `Documentation/planning/QUEUE.md`; else `QUEUE.md` at the repo root. A session launched in a project folder with its own queue writes its handoff block, `## Settled` lines, Inbox ideas and `Next:` line into that file and leaves the root queue alone. It holds, top to bottom: the title, `## ▶ NEXT SESSION — START HERE`, `## Settled`, then the lanes `## Inbox`, `## Build`, `## Spec`, `## Meta`, `## Audit`. Find sections by a line-anchored match (`\n## Build\n`), because the queue header may name the lane headings inline and a bare match lands text in the wrong place.

(`scout`, `runner` and `builder` below are optional subagents from the architect-crew plugin, dispatched as `architect-crew:scout`, `architect-crew:runner` and `architect-crew:builder`; without them, do the step in the main session.)

0. **Settle background work.** List what is still running: background commands, monitors, subagents. Wait for any whose output the wrap needs; stop the rest. Nothing may outlive the wrap.

1. **Keep the top ideas.** Sweep the transcript for what exists only in it, and send each item to one home:
   - **Ideas worth doing** (a feature, a fix, a question worth a session) go to `QUEUE.md` `## Inbox` as one line: `- (YYYY-MM-DD) <idea> — <what it produces or unblocks>`. No count cap; the bar is importance. An idea whose only product is another check (a test of a test, a tracker for tracking) is dropped. `/queue:spec` triages the Inbox, so the wrap decides no lane.
   - **Decisions and "do not re-open" deferrals** go to `QUEUE.md` `## Settled`: append one line, `- YYYY-MM-DD — <decision>, <reason>`. Append only; never rewrite the list.
   - **Findings and corrections that cost real effort** go in the body of the commit that acted on them. A reusable finding (a measured number, a verified fact, a disproved claim) belongs on the repo's reference page or findings doc, written when it was found; this step catches what the session missed.
   - Everything else goes in a `Dropped:` section in the wrap commit's body, one line per item, so `git log --grep=Dropped: -p` can recover any of them later.
   - Anything that waits on a human (an answer, an approval, an account step) goes into `OPEN_QUESTIONS.md` as a `- **<what they do>**` bullet with the date and the row it unblocks, if the repo keeps that optional file. Add one only when a person is really needed.

2. **Write the handoff block.** Replace the single existing block in `QUEUE.md` (a second `/queue:end` in the same session replaces it rather than adding another). Keep the heading text verbatim. There is no session note: the wrap commit's body carries what shipped, and `git log` is the record.

   ```markdown
   ## ▶ NEXT SESSION — START HERE (written YYYY-MM-DD HH:MM)

   **The one thing:** <one sentence — the single highest-leverage next move>
   **Why:** <one or two sentences>
   **Blocked on:** <nothing | what, who clears it, and how this was verified>

   **Actions:**
   1. <action> — files: `<paths>`. Guardrails: <the condition to hold so this lands right>. Done when: <check>
   2. ...

   **Follow-ons sharing this context** (each tagged **independent** or **blocked by <decision>**):
   - <action> — **independent**. Guardrails: <...>

   **Runs unattended through:** actions 1-<N> plus every independent follow-on. The first item needing a person is <which>, because <what they decide>.

   **Recommended model:** <model> — <reason>
   ```

   - Every action names its files, its guardrail and its done-check. Follow-ons are chosen because they reuse the files the one thing loads, never by priority; write none rather than pad. Convert relative dates to absolute. Use local time.
   - **When the queue has a `## Build` lane**, the block's Actions is one pointer: *"Take `QUEUE.md` `## Build` `[HEAD]`; its Files, Guardrails and Done when are the build."* The build detail stays in the row. If this session finished a row and its `Done when` passed, delete the row and move `[HEAD]` to the next one. A finished row that is not `[HEAD]` (a Spec, Meta or Audit row, or a Build row a parallel session finished) is deleted without moving `[HEAD]`, along with its line in any ranking table; search for any other line that still names its id and edit it. Closing finished rows and adding the step 1 Inbox lines are the only queue edits a wrap makes.
   - **When `## Inbox` holds items at wrap time**, the block says so in one line: *"Inbox holds N items — the next free session runs `/queue:spec` to turn them into rows and pack them before claiming a build group."* Only `/queue:spec` triages the Inbox.

3. **Cold-read: a re-read, never a re-run.** Read the block once as a fresh session would, and fix what reads wrong. Run no tests and no builds here; cite the results the session already produced. A claim the session never checked gets `(unverified)`. Check that no number or hash is stale and that each action names its files and done-check.

4. **Commit, land, recap.**
   - **Refresh generated pages.** If the project's `/end in this repo` section names generators for pages that should stay current, start them all at once in the background, carry on, and stage their output before the commit. A generator that fails is named in the recap, never retried in a loop.
   - **No `QUEUE.md` in the repo?** Create one with the sections listed under "Queue lookup", at `Documentation/planning/QUEUE.md` when that folder exists, else the repo root (a session in a monorepo project folder creates it in that folder). Move the handoff block's actions into `## Build` with the first marked `[HEAD]`.
   - **Pick the branch before committing.** With the default pull-request landing (see "Land the work" below), a session that is not in a worktree and sits on the base branch first runs `git switch -c <lane>-<id>-<YYYYMMDD>` (`<id>` as below), so the wrap commit and any earlier session commits not yet pushed land on that branch and nothing is committed to the base.
   - Run `git status --short`. Stage explicit paths only; never `git add .` or `git commit -a`. A modified file this session does not own belongs to another session mid-edit, so leave it alone. Commit with explicit paths, never a bare `git commit`, which would sweep in another session's staged work: `git commit -F <message-file> -- <paths>`. Subject: `[Docs]: /queue:end — <one thing>`.
   - **Land the work.** Read the `Land:` line in the project's `/end in this repo` section. No section or no line means a pull request against the repo's default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, else `main`); a branch named on the line replaces the default.
     - **Pull request (the default).** The session branch is the worktree's branch, or, without a worktree, the branch picked above. Its name carries the claim id (the Build group id such as `s3` or `web-s1`, or the lane item such as `spec-4`). Run `git fetch origin` and `git rebase origin/<base>` on the session branch, then `git push -u origin <branch>`. If the branch already has an open pull request (`gh pr view <branch>`), the push updates it; otherwise run `gh pr create --base <base> --head <branch>` with a title that starts with the claim id and the row ids it finished (`[s3: Build 7, Build 8] <one thing>`), so `/queue:build` on any machine sees the claim, and the wrap commit's body (what shipped, Inbox ideas, `Dropped:`, what waits on a person) as the body. In a lane worktree, then call `ExitWorktree` with `action: "keep"` and from the launch tree run `git worktree remove .claude/worktrees/<name>`; keep the local branch, because `/queue:build` reads it as the claim until the pull request merges. Never merge the pull request here: a person merges it. If `gh` is missing or signed out, push the branch and print the compare link (`<repo URL>/compare/<base>...<branch>`) instead. The next session reads the queue from the base branch, so the recap says the queue update lands when this pull request merges.
     - **`Land: push`.** Without a worktree: `git pull --rebase --autostash` and `git push`. In a lane worktree (the opener entered one with `EnterWorktree`; the `Session start:` line names the launch branch): run `git rebase <launch-branch>` inside the worktree, then `ExitWorktree` with `action: "keep"`, then from the launch tree run `git merge --ff-only <worktree-branch>`, `git push`, `git worktree remove .claude/worktrees/<name>` and `git branch -d <worktree-branch>`. If another session merged first and the fast-forward refuses, re-run the rebase. If the launch tree has a merged file modified (another session mid-edit), leave the branch unmerged, keep the worktree, and say so in the recap.
   - **Parallel sessions.** Each wrap replaces the handoff block it started from. On a rebase conflict in the block, keep both blocks, newer first; the next wrap folds them into one. `## Settled` lines are append-only, so a conflict there keeps both. Queue rows: keep both sessions' rows, never drop the other session's.
   - **Recap:** what shipped; the pull request link (or the compare link); the ideas added to the Inbox; the dropped list; anything left waiting on a human; the one thing and the recommended model.
   - **Sizes, one line:** each file the project caps (its `CLAUDE.md` or hook names them, typically `CLAUDE.md` and `QUEUE.md`) as `bytes / target`. Over target is allowed and is never trimmed here; the next process-improvement session (`/queue:meta`) moves material out.
   - **Next session type.** Decide it from the queue this session read and print it as the recap's last line: `Next: /queue:build` (an unclaimed `**Session N —**` group whose Files no other live session holds; name the group), else `Next: /queue:spec` (the Spec lane has rows), else `Next: /queue:audit` (the Audit lane has rows), else `Next: /queue:meta` (every lane empty, or name the friction this session hit). A group blocked on a person is named as such, with the question, rather than counted as claimable. A folder session names its folder in the line (`Next: /queue:build in apps/web — Build 3`). The line covers only the queue this session read: a folder session names its folder's next types, a root session the root's, and neither reports on the other.
   - **How many at once.** The Next line carries a count and names the groups: `Next: /queue:build ×2 — Sessions 3 and 4 (files disjoint)`. The count is the number of claimable groups whose Files are pairwise disjoint and none of which depends on another's output. A group that reads what another writes waits, and is named as the follow-on. `×1` is written as plainly as `×3`. The line names groups and assigns none: each terminal runs `/queue:build`'s own pick, so the handoff block carries no per-terminal split.

If `$ARGUMENTS` is given, treat it as extra focus for the wrap.
