# Personal Agent Instructions

These are my user-level instructions for coding agents.

# Concurrent edits

Assume David or other agents may be editing the same workspace at the same time. If you encounter unexpected file changes, work with them when they are relevant and leave them alone when they are not. Do not overwrite, revert, or otherwise wipe out changes you did not make unless David explicitly asks you to, or you have asked and received permission.

# Daily Log / Scratch Space

Use this directory for daily notes and scratch files:

```
~/repos/control-room/scratch/days/YYYY-MM-DD/
```

Use today's date for the directory (create it if it doesn't exist). Name the file to uniquely identify the work -- combine the project and the specific task, branch, or topic, e.g. `render-api-concourse-dev-cluster.md`, `personal-site-dark-mode.md`. If an existing file in today's directory clearly matches the current work, append to it; otherwise create a new one.

Do not log every action taken. Log when David asks for something to be recorded. Also use discretion to capture genuinely useful context, such as interesting findings, decisions worth preserving, or a short end-of-session summary.

Keep entries short and practical. The scratch space should preserve context that may matter later, not act as a transcript of the session.

# Linear Scratch Space

When working on a Linear ticket, use the `lineardir` script to create and locate the issue-specific scratch directory:

```
lineardir ISSUE-123
```

The script creates and prints a path under:

```
~/repos/control-room/scratch/linear/<lowercase-issue-key>/
```

All agents should be aware this script exists. When writing artifacts for Linear-ticket work, such as testing output, implementation plans, scratch documents, notes, or investigation results, put them in the appropriate `lineardir` directory.

# Git worktrees

When creating a git worktree, place it under `<repo>/.wt/<name>`, not as a sibling directory of the repo. If one already exists in the wrong place, offer to `git worktree move` it.

# Git commits

Every commit must be signed so it can be verified. Never bypass commit signing or create an unverified commit.

If the 1Password agent prevents signing, assume David could not unlock 1Password at that moment. Continue making productive progress without committing, then tell David at the end of the turn that you were unable to commit.

Do not try to cryptographically verify the signature yourself. GitHub is responsible for validating signatures. Commands like `git verify-commit` will fail locally, and you must never create or modify an allowed-signers file to make them pass. To confirm a commit is signed, just check that a signature is present, e.g. `git cat-file -p HEAD | grep -q '^gpgsig'` or inspect the commit with `git show`.

# GitHub comments

When posting a comment on GitHub on David's behalf, end it with this italicized attribution:

```markdown
_Posted on David's behalf via [harness] [exact model]._
```

Replace the placeholders with the harness and the model's full, exact designation, including its reasoning-effort level when applicable. For example:

```markdown
_Posted on David's behalf via Codex GPT-5.5 Sol High._
_Posted on David's behalf via Claude Code Fable 5 Medium._
```

# Testing Philosophy

Tests create review burden, so favor succinct, high-value tests over broad test volume.

Tests should be easy to extend when future regressions appear, but they should not aim to be exhaustive unless the behavior naturally lends itself to table-driven tests.

Do not be afraid to create local or shared test helpers when they make tests clearer, easier to extend, or less repetitive.
