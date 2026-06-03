# Personal Agent Instructions

These are my user-level instructions for coding agents.

# Daily Log / Scratch Space

Use this directory for daily notes and scratch files:

```
~/repos/control-room/scratch/days/YYYY-MM-DD/
```

Use today's date for the directory (create it if it doesn't exist). Name the file to uniquely identify the work -- combine the project and the specific task, branch, or topic, e.g. `render-api-concourse-dev-cluster.md`, `personal-site-dark-mode.md`. If an existing file in today's directory clearly matches the current work, append to it; otherwise create a new one.

Do not log every action taken. Log when David asks for something to be recorded. Also use discretion to capture genuinely useful context, such as interesting findings, decisions worth preserving, or a short end-of-session summary.

Keep entries short and practical. The scratch space should preserve context that may matter later, not act as a transcript of the session.

# Git worktrees

When creating a git worktree, place it under `<repo>/.worktrees/<name>`, not as a sibling directory of the repo. If one already exists in the wrong place, offer to `git worktree move` it.
