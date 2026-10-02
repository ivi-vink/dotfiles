---
name: magit-commit
description: 'This skill should be used when the user invokes "/magit-commit" to commit with magit via emacsclient.'
tools: Bash
disable-model-invocation: true
---

# Commit git index with Emacs magit via emacsclient

Commit git index with magit using `emacsclient --eval`. If index is empty adds all changes, including untracked files, first. Opens the magit commit editor prefilled with a message for the user to review and finish.

## Strategy

1. Read the changes to be committed: `git -C <repo> diff --cached`. If that is empty, read `git -C <repo> diff` and `git -C <repo> status` instead, since everything will be staged.
2. Invoke the `ponytail` skill and write the commit message from those changes.
3. Locate `agent-skill-magit-commit.el`, which lives alongside this skill file at `skills/magit-commit/agent-skill-magit-commit.el`, and run:

```sh
emacsclient --eval "$(cat <<'EOF'
(progn
  (load "/path/to/skills/magit-commit/agent-skill-magit-commit.el" nil t)
  (agent-skill-magit-commit
    :repo "/abs/path/to/repo"
    :message "Subject line

Body."))
EOF
)"
```

## Rules

- Escape `"` as `\"` and `\` as `\\` inside the `:message` string.
- Pass the absolute path of the repo you mean as `:repo` and to `git -C`; do not rely on the shell's working directory.
- Locate `agent-skill-magit-commit.el` relative to this skill file's directory.
- Run the `emacsclient --eval` command via the Bash tool.
