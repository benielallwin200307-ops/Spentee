# Git Management Workflow for Spentee

Project: Spentee (Flutter)
Repository: https://github.com/benielallwin200307-ops/Spentee.git
Path: C:\Spentee
Branch: main

## Safe Push Workflow (When the user says "Push Spentee" or asks to PUSH)
1. Confirm the terminal is inside `C:\Spentee`.
2. Run `git status` and review all changed files.
3. Verify that no secrets, API keys, passwords, signing keys, or unrelated files will be committed.
4. Run `git add .` to stage the appropriate project changes.
5. Review staged changes using `git status`.
6. Commit with a clear message describing the actual changes (e.g., "Update Spentee app UI").
7. Push the commit to GitHub using `git push origin main`.
8. Verify that the push succeeded and report the commit hash and final Git status.

## Safe Pull Workflow (When the user says "Pull Spentee" or asks to PULL)
1. Confirm the terminal is inside `C:\Spentee`.
2. Run `git status` to check for uncommitted changes.
3. If local changes could conflict with incoming changes, stop and explain the issue in plain language. Never discard work.
4. Confirm remote is `https://github.com/benielallwin200307-ops/Spentee.git`.
5. Pull latest code using `git pull origin main`.
6. Report whether the pull succeeded and summarize the changes received.

## Safety Rules
- Do not rebuild the app or modify application code just to perform Git operations.
- Never use `git reset --hard`, `git clean`, or force-push (`git push --force`).
- Never overwrite or delete the `Assets` folder, logo, mascot images, or other project files.
- Do not create a new repository if one already exists.
- If origin is missing, inspect the repository configuration before adding it.
- If authentication fails, explain simply how the user can sign in to GitHub.
- Execute commands in the terminal and report actual results. Never claim a push or pull succeeded without verification.
- Always explain errors in simple, non-coder friendly language and explain exact next steps.
