# Add queue lanes to an existing repo

About 15 minutes. One person sets up the repo; every teammate installs the commands once.

## 1. Each teammate, once per machine

```text
/plugin marketplace add Strong-Force-Analytics/claude-plugins
/plugin install queue@sfa-plugins
/plugin install architect-crew@sfa-plugins
```

architect-crew is optional; without it each session does the reading and editing itself.

Check: start Claude Code anywhere and type `/queue` — `/queue:build`, `/queue:spec`, `/queue:meta`, `/queue:audit` and `/queue:end` appear in the list.

The queue file is created with `/queue:init`, which does the setup steps this guide describes.

## 2. One person, in the existing repo


**a. Place the queue.** If the repo already has a `Documentation/` folder, use
`Documentation/planning/QUEUE.md`; otherwise `QUEUE.md` at the repo root. In a monorepo, a project folder may hold its own
`QUEUE.md` (for example `apps/web/QUEUE.md`); launch Claude Code in that folder. The commands look,
in order, for the nearest `QUEUE.md` from the launch folder up to (not including) the repo root,
then `Documentation/planning/QUEUE.md`, then the repo-root `QUEUE.md`.

Start from the template, [`templates/QUEUE.md`](../templates/QUEUE.md) in this repo
(`/queue:init` copies it for you).

Edit the title line, and delete the example rows under `## Build`, `## Spec`, `## Meta` and
`## Audit` (keep the headings and the comment blocks).

**b. Ignore session worktrees.**

```bash
echo ".claude/worktrees/" >> .gitignore
```

**c. Bring the existing backlog in.** Paste every open item you already track (a `TODO.md`,
issue titles, Trello cards, notes) into `## Inbox`, one line each. Keep links to the source.
Leave sorting for step 3; that is `/queue:spec`'s job. Asking Claude works too:
*"Copy every open item in TODO.md into the ## Inbox section of QUEUE.md, one line each."*

If the repo has a `TODO.md` or similar, either delete it in the same commit or add a line to its
top pointing at `QUEUE.md`, so the team keeps one list.

**d. Point `CLAUDE.md` at it.** Add this section to the repo's `CLAUDE.md` (create the file if
there is none):

```markdown
## Work queue

All pending work lives in `Documentation/planning/QUEUE.md` (adjust the path), sorted into
lanes. Open a session with `/queue:build`, `/queue:spec`, `/queue:meta` or `/queue:audit`; close every session with `/queue:end`.

Git rules (several sessions can share this repo):
- Stage and commit explicit paths: `git commit -m "..." -- <paths>`.
- Avoid `git add .`, `git commit -a` and a bare `git commit`.
- Commit small; `/queue:end` opens the pull request.

## /end in this repo

- Land: pull request against `main`
<!-- Optional: extra wrap steps, e.g. "re-run scripts/build_docs.py".
     `Land: push` merges and pushes directly instead of opening a pull request. -->
```

**e. Commit and open a pull request.**

```bash
git switch -c queue-init
git add Documentation/planning/QUEUE.md .gitignore CLAUDE.md
git commit -m "[Docs]: add queue lanes (QUEUE.md, CLAUDE.md work-queue section)" -- Documentation/planning/QUEUE.md .gitignore CLAUDE.md
git push -u origin queue-init
gh pr create --fill
```

Merge it before the first session, so `/queue:spec` reads the queue from the default branch.

## 3. First session

Run `/queue:spec`. It sorts `## Inbox`: each item becomes a Build, Spec, Meta or Audit row, gets done
on the spot, or is dropped with a reason in the commit. It then packs Build rows into
`Session N` groups and ends with `/queue:end`, which prints which command to run next
(for example `Next: /queue:build ×2`).

From then on: `/queue:build` in as many terminals as `/queue:end` says, `/queue:spec` when the Inbox fills up,
`/queue:audit` now and then, `/queue:meta` when the same friction shows up twice.

## Checks that setup worked

- `QUEUE.md` is at one of the lookup paths and has the seven headings
  (`▶ NEXT SESSION`, `Settled`, `Inbox`, `Build`, `Spec`, `Meta`, `Audit`).
- `git check-ignore .claude/worktrees/x` prints the path.
- After the first `/queue:spec` + `/queue:end`: the `## ▶ NEXT SESSION` block is filled in, `## Inbox` is
  empty, and at least one Build row carries `[HEAD]`.

## Common questions

- **We already use GitHub Issues / Trello.** Keep them for discussion and outside requests;
  copy what is ready to work on into `## Inbox`. `QUEUE.md` is what Claude sessions read.
- **Monorepo with several projects.** Each project folder may hold its own `QUEUE.md`; launch
  Claude Code in that folder and the lanes work that queue. A session launched at the repo root
  works only the root queue. Each row's `Files` line keeps groups from colliding.
- **No worktree support in our Claude Code version.** The commands fall back to the current
  checkout; run one session at a time per checkout and follow the git rules above.
