# Personal Agent Instructions

These are my user-level instructions for coding agents.

# Scope discipline

Implement what was asked and nothing more. Do not add CLI flags, env vars, config knobs, extra function parameters, or injection seams that the task did not call for. We are the designers of this software, so an unproven knob is a liability rather than flexibility.

If you believe an extra knob or seam is genuinely required, stop and ask in one sentence before building it.

The same applies to how work is divided. Propose the split -- PRs, commits, tickets -- as a short numbered list and wait for approval before creating branches, worktrees, or issues. For each piece, say what single concern it owns and why it cannot fold into a sibling. Flag any piece whose value is already available from existing data or telemetry.

# Linear writes

Treat requests to write, draft, or prepare Linear content as draft-only. Do not post, create, update, or comment in Linear unless David explicitly confirms that the specific content should be published.

# Verify before claiming

Never assert how something behaves without first reading the source or running the code. Specifically:

- Absolutes such as "fails closed", "always", "only", "cannot", or "X is unusable" hide the most error. Prove them or drop them.
- Re-read the file to confirm a line number before citing `file:line`.
- Run tests, builds, and hooks with their output visible, never swallowed, before calling anything green.

When a claim is inferred rather than verified, label it as an assumption. Before posting a PR description, review comment, Linear comment, Slack message, or decision record, check each factual claim in it against evidence you actually gathered, and cut or soften the ones you cannot support.

# Concurrent edits

Assume David or other agents may be editing the same workspace at the same time. If you encounter unexpected file changes, work with them when they are relevant and leave them alone when they are not. Do not overwrite, revert, or otherwise wipe out changes you did not make unless David explicitly asks you to, or you have asked and received permission.

# Browser use

Never drive my browser. Do not attach to, control, or take actions in the Chrome instance I am using -- it holds my live sessions, and I do not want agents clicking around in them.

When a task genuinely needs a browser, use the `playwright-cli` command, which drives its own separate browser instance. It is installed and on `PATH`.

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

Use `wt`, rather than `git worktree` directly, for all worktree management, including creation and removal. This ensures its configured worktree location is used and its hooks run.

# Stacked branches

Much of my work lands as a stack of small PRs, so the base branch is usually the parent PR rather than `main`. Before any rebase or force-push, state the target branch you are about to use and confirm it is the stack parent. Rebasing a stacked branch onto `origin/main` duplicates the parent's commits.

`git log --oneline origin/main..HEAD` shows what a branch actually carries. If it contains commits that belong to the parent PR, the base is wrong -- stop and fix the base before doing anything else.

Ask which branch to stack on rather than guessing when the parent is not obvious.

# Git commits

Every commit must be signed so it can be verified. Never bypass commit signing or create an unverified commit.

If the 1Password agent prevents signing, assume David could not unlock 1Password at that moment. Continue making productive progress without committing, then tell David at the end of the turn that you were unable to commit.

Do not try to cryptographically verify the signature yourself. GitHub is responsible for validating signatures. Commands like `git verify-commit` will fail locally, and you must never create or modify an allowed-signers file to make them pass. To confirm a commit is signed, just check that a signature is present, e.g. `git cat-file -p HEAD | grep -q '^gpgsig'` or inspect the commit with `git show`.

History is a communication artifact, not a log, and who it is communicating with changes once a branch is under review.

Before anyone outside has reviewed the branch, the audience is the eventual reader of `main`. Shape history for them: each commit one logical, self-contained, bisectable change whose message explains why. Fold corrections into the commit they belong to with `git commit --fixup` and `git rebase --autosquash`.

Once an external reviewer has commented, the audience is that reviewer. Push responses to their feedback as new commits so they can see exactly what changed since they last looked. Do not rewrite or force-push commits they have already reviewed -- it orphans their inline comments and forces them to re-read the whole diff. Return to shaping the history for `main` only once the review is resolved, and tell David the plan before rewriting anything at that point.

Check in before each commit rather than presenting one large batched diff at the end.

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
