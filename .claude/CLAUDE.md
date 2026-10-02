# Commit attribution

End commit messages with this trailer instead of the default one. Replace `<model>` with the model you are currently running as (e.g. `Claude Opus 5.5`), leaving out the context size, and `<email>` with the output of `git config user.email` in the repo being committed to. Never hardcode either:

```
Assisted-By: <model> (ACP, agent-shell, emacs) <<email>>
```
