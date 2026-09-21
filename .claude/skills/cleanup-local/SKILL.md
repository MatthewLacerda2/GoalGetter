---
name: cleanup-local
description: Use when the user asks to clean up, tidy, prune or "enxugar" the repository — stale worktrees, merged or empty branches — or after a PR merges, or when a session starts on a main checkout that is many commits behind origin.
---

# Cleanup Local

Bring the repository back to "only work in flight exists": `main` current, every merged
or empty worktree and branch gone, and the remote free of branches whose PR is finished. **Nothing that is still open ever moves.**

**Every deletion decision comes from the PR's state on GitHub, not from git ancestry.**
PRs here are squash-merged, and a squash-merged branch tip is not an ancestor of anything
— ancestry lies, `gh` does not.

Run from the main checkout, never from inside a worktree. From a worktree, the root is
`cd "$(git rev-parse --git-common-dir)/.."`.

## Steps, in order

1. `git fetch --prune origin`, then `git pull --ff-only` on `main`. If `main` has local
   commits that are not on origin, **stop and report them** — never reset them away.
2. Classify every worktree and local branch (table below). Remove worktrees first, then
   `git worktree prune`, then `git branch -D` the branches.
3. Classify every remote branch; `git push origin --delete` the ones marked delete.
4. Report (shape below).

**Do not rebuild the root `docker compose` stack.** On this machine ports 8000 and 8080
belong to another project, and the stack includes `cloudflared` — bringing it up opens
the public tunnel. That is a deploy decision, not a cleanup step.

## Classification

Fetch PR state once:
`gh pr list --state all --limit 500 --json number,headRefName,state,mergeCommit,mergedAt`.
A branch with no match is re-checked with `gh pr list --head <branch> --state all` before
it is called "no PR".

| Target | Delete when | Keep when |
|---|---|---|
| Worktree | Tree clean **and** its branch is deletable below **and** no process runs from it | Any uncommitted change; a dev server or backend running from it; it is the worktree this session runs in |
| Local branch | PR `MERGED` with no local commits beyond `origin/<branch>`; or `git rev-list --count main..<branch>` is `0` | Open PR; local commits not on origin; checked out in a worktree that stays; `main` |
| Remote branch | PR `MERGED` or `CLOSED` | Open PR; no PR at all (someone's WIP); `main` |

**Merged means the PR's `mergeCommit` is in `origin/main`** (or in the PR's base, for a
PR stacked on another branch): `git merge-base --is-ancestor <mergeCommit> origin/<base>`.

**A running process pins its worktree.** Check before removing:
`lsof +D <worktree> 2>/dev/null | head` or `pgrep -af <worktree>`. The Flutter dev server
and the backend both run from a worktree; removing it out from under them breaks the app
the user may be looking at on their phone. Name the stop command in the report instead.

A branch with commits of its own, no PR, and not in `main` is never deleted by this
skill. Name it in the report.

## Report

End with exactly these lines, filled in:

- main: `<sha>` (`<n>` commits pulled)
- worktrees removed: `<list>` · kept: `<list, each with its reason>`
- local branches deleted: `<count>` (`<n>` merged, `<n>` empty)
- remote branches deleted: `<list with PR #>` · kept: `<list with reason>`
- left for the user: `<commands, if any>`

## Common mistakes

- Reading PR numbers as merge order. Read `mergedAt`.
- Testing the branch tip for ancestry after a squash merge — use `mergeCommit`.
- Removing a worktree that a dev server is serving from.
