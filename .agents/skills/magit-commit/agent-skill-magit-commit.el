;; -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'magit)

(cl-defun agent-skill-magit-commit (&key repo message)
  "Commit the index of REPO with magit.

REPO is any path inside the repository.  If nothing is staged, stage
all changes, including untracked files, first.  MESSAGE prefills the
commit editor via `git commit --message --edit' for the user to review."
  (let ((default-directory (or (magit-toplevel repo)
                               (user-error "Not a git repo: %s" repo))))
    (unless (magit-anything-staged-p)
      (magit-stage-modified t))
    (magit-commit-create (list "--edit" (concat "--message=" message)))))

(provide 'agent-skill-magit-commit)
