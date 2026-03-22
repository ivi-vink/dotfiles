;; -*- lexical-binding: t; -*-
(require 'package)
(setq ring-bell-function 'ignore)
(tool-bar-mode -1)
(menu-bar-mode -1)
(set-scroll-bar-mode nil)
(setq custom-file "~/.config/emacs/custom.el")
(load custom-file)
(setq backup-directory-alist `(("." . "~/.config/emacs/saves")))
(setq auto-save-file-name-transforms `((".*" "~/.config/emacs/auto-saves/" t)))
(setq lock-file-name-transforms
  '((".*" "~/.config/emacs/lock" t)))
(setq backup-by-copying t)
(setq treesit-extra-load-path '("/usr/local/lib"))

;; set package.el repositories
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/"))

(package-initialize)

(use-package visual-regexp
  :ensure t)

(use-package phi-search
  :ensure t
  :bind (("C-s" . phi-search)
          ("C-r" . phi-search-backward)))

(use-package undo-tree
  :ensure t
  :config
  (keymap-global-set "C-\\" 'undo-tree-undo)
  (keymap-global-set "C-|" 'undo-tree-redo)
  (setq undo-tree-history-directory-alist '(("." . "~/.config/emacs/undo-tree")))
  (global-undo-tree-mode))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :ensure t
  :init
  (savehist-mode))

(defun my/code ()
  "Go to VScode"
  (interactive)
  (start-process
    "code" nil "code" "--goto"
    (string-join
      (list (buffer-file-name) (int-to-string (line-number-at-pos))) ":")))

(defun my/open () (interactive) (start-process "open" nil "f"))

(use-package clipetty
  :ensure t
  :config
  (global-clipetty-mode))

;; Emacs minibuffer configurations.
(use-package emacs
  :ensure t
  :bind
  (("C-c f" . find-file-at-point)
    ("C-c c" . my/code)
    ("C-c o" . my/open))
  :config
  (setenv "PICKER" "dmenu.emacs")
  (column-number-mode)
  (repeat-mode)
  (global-display-line-numbers-mode)
  :custom
  (grep-command (cons "rg -i --no-ignore-vcs --vimgrep --no-column '' ." 46))
  ;; TAB cycle if there are only few candidates
  ;; (completion-cycle-threshold 3)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)

  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)

  ;; Hide commands in M-x which do not apply to the current mode.  Corfu
  ;; commands are hidden, since they are not used via M-x. This setting is
  ;; useful beyond Corfu.
  (read-extended-command-predicate #'command-completion-default-include-p)

  ;; Enable context menu. `vertico-multiform-mode' adds a menu in the minibuffer
  ;; to switch display modes.
  (context-menu-mode t)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
    '(read-only t cursor-intangible t face minibuffer-prompt)))

(use-package orderless
  :ensure t
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  ;; (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) ;; Disable defaults, use our settings
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring

;; Use Dabbrev with Corfu!
(use-package dabbrev
  :ensure t
  ;; Swap M-/ and C-M-/
  :bind (("M-/" . dabbrev-completion)
          ("C-M-/" . dabbrev-expand))
  :config
  (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")
  (add-to-list 'dabbrev-ignored-buffer-modes 'authinfo-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode)
  (defun my-capf-prepend-cape-dabbrev ()
    "Make `cape-dabbrev` the first CAPF in this buffer."
    (setq-local completion-at-point-functions
      (cons #'cape-dabbrev
        (remove #'cape-dabbrev completion-at-point-functions))))
  (add-hook 'after-change-major-mode-hook #'my-capf-prepend-cape-dabbrev))

(use-package yaml-pro
  :ensure t
  :config
  (add-hook 'yaml-mode-hook 'yaml-ts-mode 100)
  (add-hook 'yaml-ts-mode-hook 'yaml-pro-ts-mode 100)
  (add-hook 'yaml-pro-ts-mode-hook (lambda () (setq-local indent-line-function 'yaml-indent-line)) 100)

  (keymap-set yaml-pro-ts-mode-map "C-M-n" #'yaml-pro-ts-next-subtree)
  (keymap-set yaml-pro-ts-mode-map "C-M-p" #'yaml-pro-ts-prev-subtree)
  (keymap-set yaml-pro-ts-mode-map "C-M-u" #'yaml-pro-ts-up-level)
  (keymap-set yaml-pro-ts-mode-map "C-M-d" #'yaml-pro-ts-down-level)
  (keymap-set yaml-pro-ts-mode-map "C-M-k" #'yaml-pro-ts-kill-subtree)
  (keymap-set yaml-pro-ts-mode-map "C-M-<backspace>" #'yaml-pro-ts-kill-subtree)
  (keymap-set yaml-pro-ts-mode-map "C-M-a" #'yaml-pro-ts-first-sibling)
  (keymap-set yaml-pro-ts-mode-map "C-M-e" #'yaml-pro-ts-last-sibling)

  (keymap-set yaml-pro-ts-mode-map "M-<up>" #'yaml-pro-ts-move-subtree-up)
  (keymap-set yaml-pro-ts-mode-map "M-<down>" #'yaml-pro-ts-move-subtree-down)
  (keymap-set yaml-pro-ts-mode-map "C-c C-f" #'yaml-pro-fold-at-point)
  (keymap-set yaml-pro-ts-mode-map "C-c C-o" #'yaml-pro-unfold-at-point)

  (defvar-keymap my/yaml-pro/tree-repeat-mapo
    :repeat t
    "n" #'yaml-pro-ts-next-subtree
    "p" #'yaml-pro-ts-prev-subtree
    "u" #'yaml-pro-ts-up-level
    "d" #'yaml-pro-ts-down-level
    "m" #'yaml-pro-ts-mark-subtree
    "k" #'yaml-pro-ts-kill-subtree
    "a" #'yaml-pro-ts-first-sibling
    "e" #'yaml-pro-ts-last-sibling
    "SPC" #'my/yaml-pro/set-mark
    "f" #'yaml-pro-fold-at-point
    "o" #'yaml-pro-unfold-at-point
    )

  (defun my/yaml-pro/set-mark ()
    (interactive)
    (my/region/set-mark 'my/yaml-pro/set-mark))

  (defun my/region/set-mark (command-name)
    (if (eq last-command command-name)
      (if (region-active-p)
        (progn
          (deactivate-mark)
          (message "Mark deactivated"))
        (activate-mark)
        (message "Mark activated"))
      (set-mark-command nil))))

(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

;; Example configuration for Consult
(use-package consult
  :ensure t
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
          ("C-c M-x" . consult-mode-command)
          ("C-c h" . consult-history)
          ("C-c k" . consult-kmacro)
          ("C-c m" . consult-man)
          ("C-c i" . consult-info)
          ([remap Info-search] . consult-info)
          ;; C-x bindings in `ctl-x-map'
          ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
          ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
          ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
          ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
          ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
          ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
          ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
          ;; Custom M-# bindings for fast register access
          ("M-#" . consult-register-load)
          ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
          ("C-M-#" . consult-register)
          ;; Other custom bindings
          ("M-y" . consult-yank-pop)                ;; orig. yank-pop
          ;; M-g bindings in `goto-map'
          ("M-g e" . consult-compile-error)
          ("M-g r" . consult-grep-match)
          ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
          ("M-g g" . consult-goto-line)             ;; orig. goto-line
          ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
          ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
          ("M-g m" . consult-mark)
          ("M-g k" . consult-global-mark)
          ("M-g i" . consult-imenu)
          ("M-g I" . consult-imenu-multi)
          ;; M-s bindings in `search-map'
          ("M-s d" . consult-find)                  ;; Alternative: consult-fd
          ("M-s c" . consult-locate)
          ("M-s g" . consult-grep)
          ("M-s G" . consult-git-grep)
          ("M-s r" . consult-ripgrep)
          ("M-s l" . consult-line)
          ("M-s L" . consult-line-multi)
          ("M-s k" . consult-keep-lines)
          ("M-s u" . consult-focus-lines)
          ;; Isearch integration
          ("M-s e" . consult-isearch-history)
          :map isearch-mode-map
          ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
          ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
          ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
          ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
          ;; Minibuffer history
          :map minibuffer-local-map
          ("M-s" . consult-history)                 ;; orig. next-matching-history-element
          ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  ;; :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
    xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
    consult-theme :preview-key '(:debounce 0.2 any)
    consult-ripgrep consult-git-grep consult-grep consult-man
    consult-bookmark consult-recent-file consult-xref
    consult-source-bookmark consult-source-file-register
    consult-source-recent-file consult-source-project-recent-file
    ;; :preview-key "M-."
    :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )

(unless (display-graphic-p)
  (add-hook 'after-make-frame-functions
    '(lambda
       ;; Take advantage of iterm2's CSI u support (https://gitlab.com/gnachman/iterm2/-/issues/8382).
       (xterm--init-modify-other-keys)

       ;; Courtesy https://emacs.stackexchange.com/a/13957, modified per
       ;; https://gitlab.com/gnachman/iterm2/-/issues/8382#note_365264207
       (defun character-apply-modifiers (c &rest modifiers)
         "Apply modifiers to the character C.
MODIFIERS must be a list of symbols amongst (meta control shift).
Return an event vector."
         (if (memq 'control modifiers) (setq c (if (and (<= ?a c) (<= c ?z))
                                                 (logand c ?\x1f)
                                                 (logior (lsh 1 26) c))))
         (if (memq 'meta modifiers) (setq c (logior (lsh 1 27) c)))
         (if (memq 'shift modifiers) (setq c (logior (lsh 1 25) c)))
         (vector c))
       (when (and (boundp 'xterm-extra-capabilities) (boundp 'xterm-function-map))
         (let ((c 32))
           (while (<= c 126)
             (mapc (lambda (x)
                     (define-key xterm-function-map (format (car x) c)
                       (apply 'character-apply-modifiers c (cdr x))))
               '(;; with ?.VT100.formatOtherKeys: 0
                  ("\e\[27;3;%d~" meta)
                  ("\e\[27;5;%d~" control)
                  ("\e\[27;6;%d~" control shift)
                  ("\e\[27;7;%d~" control meta)
                  ("\e\[27;8;%d~" control meta shift)
                  ;; with ?.VT100.formatOtherKeys: 1
                  ("\e\[%d;3u" meta)
                  ("\e\[%d;5u" control)
                  ("\e\[%d;6u" control shift)
                  ("\e\[%d;7u" control meta)
                  ("\e\[%d;8u" control meta shift)))
             (setq c (1+ c)))))
       )))

(use-package terraform-mode
  :ensure t
  :config
  (setq terraform-format-on-save t)
  (add-hook 'terraform-mode-hook 'terraform-format-on-save-mode 100))

(use-package go-mode
  :ensure t
  :config
  (add-hook 'before-save-hook #'gofmt-before-save))

(use-package dap-mode
  :ensure t)

(defun dap-exec-with-args (cmd)
  (interactive "scmd: ")
  (dap-register-debug-template
    "exec"
    (list
      :type "go"
      :request "launch"
      :name "Launch Executable"
      :mode "exec"
      :program nil
      :args (split-string-shell-command cmd)
      :env nil)))


(use-package multiple-cursors
  :ensure t
  :config
  (defvar-keymap my/mc/repeat
    :repeat t
    "n" #'mc/mark-next-like-this
    "p" #'mc/mark-previous-like-this
    "N" #'mc/skip-to-next-like-this
    "P" #'mc/skip-to-previous-like-this
    "," #'mc/remove-current-cursor
    "(" #'mc/cycle-backward
    ")" #'mc/cycle-forward)
  (add-hook 'multiple-cursors-mode-hook (lambda() (corfu-mode -1)))
  (global-set-key (kbd "C-c n") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-c p") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c N") 'mc/skip-to-next-like-this)
  (global-set-key (kbd "C-c P") 'mc/skip-to-previous-like-this)
  (global-set-key (kbd "C-c M-s") 'mc/edit-lines)
  (global-set-key (kbd "C-c s") 'vr/mc-mark)
  (global-set-key (kbd "C-c ,") 'mc/remove-current-cursor)
  (global-set-key (kbd "C-c M-(") 'mc/cycle-backward)
  (global-set-key (kbd "C-c M-)") 'mc/cycle-forward))

(defun my/pick-line-from-shell (command)
  "Run COMMAND, prompt user to pick one output line, return the chosen line."
  (let* ((out (string-trim-right (shell-command-to-string command)))
          (lines (split-string out "\n" t)))
    (completing-read "Pick: " lines nil t)))

(defun my/issue ()
  "Get issue number."

  (interactive)
  (let ((issue
          (my/pick-line-from-shell "{ echo 000; gh issue list --assignee='ivi-vink'; }")))
    (save-match-data (when (string-match "\\([0-9]+\\).*" issue) (match-string 1 issue)))))

(defun my/issue-insert ()
  "Get issue number."

  (interactive)
  (insert (string-join (list "issue:" (string-join (list "#" (my/issue)) "")) " ")))

(defun my/issue-commit ()
  "Make a commit with a message starting with ISSUE-ID."

  (interactive)
  (let
    ((id (my/issue)))
    (magit-commit-create
      (append
        (list "-e" (format "--trailer=issue:#%s" id))
        (magit-commit-arguments)))
    ))

(use-package magit
  :ensure t
  :config
  (transient-append-suffix 'magit-commit "c" '("I" "Issue commit" my/issue-commit)))

(use-package latex)
(use-package auctex
  :ensure t
  :config
  (setq TeX-engine-alist '((default
                             "Tectonic"
                             "tectonic -X compile -f plain %T"
                             "tectonic -X watch"
                             nil)))
  (setq LaTeX-command-style '(("" "%(latex)")))
  (setq TeX-process-asynchronous t
    TeX-check-TeX nil
    TeX-engine 'default)

  (let ((tex-list (assoc "TeX" TeX-command-list))
         (latex-list (assoc "LaTeX" TeX-command-list)))
    (setf (cadr tex-list) "%(tex)"
      (cadr latex-list) "%l"))
  (TeX-source-correlate-mode)

  (when (executable-find "zathura")
    (add-to-list 'TeX-view-program-selection
      '(output-pdf "Zathura")))
  (when (executable-find "sioyek")

    (add-to-list 'TeX-view-program-selection
      '(output-pdf "Sioyek")))
  )

(defun without-flags (args-list)
  (seq-filter (lambda (args) (not (string-match "\\-" args))) args-list))

(defun without-flags-other (args-list)
  (cond
    ((seq-filter (lambda (args) (string-match "\\-" args)) args-list)
      (append (seq-filter (lambda (args) (not (string-match "\\-" args))) args-list) '("")))
    (args-list)))

(defun pcomplete/pistarchio ()
  (let*
    ((cmd (without-flags-other pcomplete-args))
      (args (string-join (butlast cmd)  " "))
      (subcmds (cdr (pcomplete-from-help (concat args " --help") :margin "^  " :argument "[a-z]+" :narrow-start "\n\n"))))
    (while (not (member (car (last cmd)) subcmds))
      (message (concat args " group: " (car (last cmd))))

      (pcomplete-here* (completion-table-merge
		        subcmds
		        (pcomplete-from-help (concat args " --help"))
		        )))
    (let ((subcmd (pcomplete-arg -1)))
      (message (concat args " subcmd: " subcmd))
      (if (pcomplete-match "\\`-" 0)
        (pcomplete-here (pcomplete-from-help
                          (concat args " --help"))
          (pcomplete-here (pcomplete-entries)))
        ))))

(defun y/auto-update-theme ()
  "Depending on time use different theme."
  ;; very early => gruvbox-light, solarized-light, nord-light
  (let* ((hour (nth 2 (decode-time (current-time))))
         (theme (cond ((<= 7 hour 8)   'doom-gruvbox-light)
                      ((= 9 hour)      'doom-solarized-light)
                      ((<= 10 hour 16) 'doom-nord-light)
                      ((<= 17 hour 18) 'doom-gruvbox-light)
                      ((<= 19 hour 22) 'doom-oceanic-next)
                      (t               'doom-laserwave))))
    (when (not (equal (car custom-enabled-themes) theme))
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t))
    ;; run that function again next hour
    (run-at-time (format "%02d:%02d" (+ hour 1) 0) nil 'y/auto-update-theme)))

(use-package gruber-darker-theme
  :ensure t
  :config
  (load-theme 'gruber-darker t))

(use-package org
  :bind (("C-c a" . org-agenda) ("C-c j" . my/goto-today-journal-entry))
  :config
  (add-to-list 'org-file-apps '("\\.svg\\'" . "/Applications/Inkscape.app/Contents/MacOS/inkscape %s"))
  (setq org-startup-with-inline-images t)
  (defun my/org-create-and-open-drawing ()
    "Insert a timestamped SVG drawing link, create the file, and open in Inkscape."
    (interactive)
    (let* ((dir "drawings/")
            (filename (concat "sketch-" (format-time-string "%Y%m%d-%H%M%S") ".svg"))
            (fullpath (expand-file-name filename dir)))
      ;; Ensure drawings dir exists
      (unless (file-directory-p dir)
        (make-directory dir))
      ;; Create minimal SVG if it doesn't exist
      (unless (file-exists-p fullpath)
        (with-temp-file fullpath
          (insert "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n"
            "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" width=\"1024\" height=\"768\">\n"
            "</svg>")))
      ;; Insert link in org buffer
      (insert (format "[[file:%s]]\n" fullpath))
      (org-display-inline-images)
      ;; Open in Inkscape
      (start-process "inkscape" nil "/Applications/Inkscape.app/Contents/MacOS/inkscape" fullpath)))

  (global-set-key (kbd "C-c d") 'my/org-create-and-open-drawing)

  (defun my/postcommand()
    (cond
      ((equal this-command 'org-ctrl-c-ctrl-c)
        (org-display-inline-images))))

  (add-hook 'post-command-hook #'my/postcommand t)
  (setq org-directory "~/Sync/my/notes")
  (setq org-agenda-files (list org-directory))
  (setq org-confirm-babel-evaluate nil)
  (setq org-startup-folded t)
  (setq org-default-notes-file (concat org-directory "/notes.org"))
  (setq org-datetree-add-timestamp t)
  (setq org-capture-templates
    '(("j" "Journal" entry (file+olp+datetree "~/Sync/my/notes/notes.org")
        "* %?\n  Entered on %U\n  %c\n  %i\n  %a")))
  (defun my/goto-today-journal-entry ()
    "Go to today's journal entry in the datetree and narrow to subtree."
    (interactive)
    (find-file "~/Sync/my/notes/notes.org")
    (widen)
    (org-datetree-find-date-create (calendar-current-date))
    (org-narrow-to-subtree)))



(use-package lsp-pyright
  :ensure t
  :custom
  (lsp-pyright-langserver-command "pyright"))  ; or lsp-deferred

(use-package auth-source-pass
  :ensure t
  :config
  (auth-source-pass-enable))

(use-package eglot
  :ensure nil
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0) ;; EMACS-31 -- do we still need it?
  (eglot-events-buffer-config '(:size 0 :format full))
  (eglot-prefer-plaintext nil)
  (jsonrpc-event-hook nil)
  (eglot-code-action-indications nil) ;; EMACS-31 -- annoying as hell
  :init
  (fset #'jsonrpc--log-event #'ignore)

  (setq-default eglot-workspace-configuration (quote
                                                (:gopls (:hints (:parameterNames t)))))

  (defun emacs-solo/eglot-setup ()
    "Setup eglot mode with specific exclusions."
    (unless (memq major-mode '(emacs-lisp-mode lisp-mode))
      (eglot-ensure)))

  (add-hook 'prog-mode-hook #'emacs-solo/eglot-setup)

  (with-eval-after-load 'eglot
    (add-to-list
      'eglot-server-programs
      '((ruby-mode ruby-ts-mode) "ruby-lsp")))

  (with-eval-after-load 'eglot
    (add-to-list
      'eglot-server-programs
      '((tsx-ts-mode typescript-ts-mode js-mode js-jsx-mode js-ts-mode)
         . ("rass"
             "--"
             "typescript-language-server" "--stdio"
             "--"
             "eslint-lsp" "--stdio"
             "--"
             "tailwindcss-language-server" "--stdio"))))

  :bind (:map
          eglot-mode-map
          ("C-c l a" . eglot-code-actions)
          ("C-c l o" . eglot-code-action-organize-imports)
          ("C-c l r" . eglot-rename)
          ("C-c l d" . eglot-find-typeDefinition)
          ("C-c l i" . eglot-find-implementation)
          ("C-c l g" . eglot-find-declaration)
          ("C-c l f" . eglot-format)))

(use-package icomplete
  :bind ((:map icomplete-minibuffer-map
           ("C-n" . icomplete-forward-completions)
           ("C-p" . icomplete-backward-completions)
           ("C-v" . icomplete-vertical-toggle)
           ("RET" . icomplete-force-complete-and-exit))
          (:map icomplete-vertical-mode-minibuffer-map
            ("C-n" . icomplete-forward-completions)
            ("C-p" . icomplete-backward-completions)
            ("C-v" . icomplete-vertical-toggle)
            ("TAB" . icomplete-force-complete)
            ;; ("TAB" . minibuffer-complete)
            ("RET" . my/icomplete-force-complete-and-exit)
            ("C-j" . exit-minibuffer))
          );; So we can exit commands like
  ;; `multi-file-replace-regexp-as-diff'
  :hook
  (after-init-hook .
    (lambda ()
      (fido-mode -1)
      (icomplete-vertical-mode 1)))
  :config
  (defun my/icomplete-force-complete-and-exit ()
    (interactive)
    (if
      (or
        (and
          minibuffer-completing-file-name
          (string-suffix-p "/" (icomplete--field-string)))
        (and
          (equal (icomplete--field-string) icomplete--initial-input)
          (not (equal icomplete--initial-input ""))))
      (exit-minibuffer)
      (icomplete-force-complete-and-exit))
    )
  (defun my-find-file-predicate (file)
    (not (string= file "./")))
  (defun my-hide-completions-after-capf (&rest _)
    (unless (minibufferp)
      (minibuffer-hide-completions)))
  (advice-add 'completion-at-point
    :after #'my-hide-completions-after-capf)

  (define-advice find-file-read-args
    (:override (prompt mustmatch) filter-dot-slash)
    (list
      (read-file-name prompt nil default-directory mustmatch nil
        #'my-find-file-predicate)
      t))
  (setq icomplete-delay-completions-threshold 0)
  (setq icomplete-compute-delay 0)
  (setq icomplete-show-matches-on-no-input t)
  (setq icomplete-hide-common-prefix nil)
  (setq icomplete-prospects-height 10)
  (setq icomplete-separator " . ")
  (setq icomplete-with-completion-tables t)
  (setq icomplete-in-buffer t)
  (setq icomplete-max-delay-chars 0)
  (setq icomplete-scroll t)

  (setq icomplete-vertical-in-buffer-adjust-list t)
  (setq icomplete-vertical-render-prefix-indicator t)

  )

(defun uv-activate ()
  "Activate Python environment managed by uv based on current project directory.
Looks for .venv directory in project root and activates the Python interpreter."
  (interactive)
  (let* ((project-root default-directory)
         (venv-path (expand-file-name ".venv" project-root))
         (python-path (expand-file-name
                       (if (eq system-type 'windows-nt)
                           "Scripts/python.exe"
                         "bin/python")
                       venv-path)))
    (if (file-exists-p python-path)
        (progn
          ;; Set Python interpreter path
          (setq python-shell-interpreter python-path)

          ;; Update exec-path to include the venv's bin directory
          (let ((venv-bin-dir (file-name-directory python-path)))
            (setq exec-path (cons venv-bin-dir
                                  (remove venv-bin-dir exec-path))))

          ;; Update PATH environment variable
          (setenv "PATH" (concat (string-remove-suffix "/" (file-name-directory python-path))
                                 path-separator
                                 (getenv "PATH")))

          ;; Update VIRTUAL_ENV environment variable
          (setenv "VIRTUAL_ENV" venv-path)

          (message "Activated UV Python environment at %s" venv-path))
      (error "No UV Python environment found in %s" project-root))))

(use-package paredit
  :ensure t
  :hook (lisp-interaction-mode . paredit-mode)
  :config
  (add-hook 'lisp-interaction-mode-hook
    (lambda ()
      (local-set-key (kbd "C-c C-j") #'eval-print-last-sexp))))

(use-package vterm
  :ensure t)

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c C-'" . claude-code-ide-menu) ; Set your favorite keybinding
  :config
  (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools

(defun my/remove-labels ()
  (dolist (topic (forge--list-topics
                  (forge--topics-spec :type 'issue :state 'open)
                  (forge-get-repository "https://github.com/pionative/quickstart")))
    (let* ((labels (oref topic labels))
           (filtered (seq-remove
                      (lambda (label)
			(member (cadr label) '("infra-as-code" "business-administratie" "meerwerk")))
                      labels)))
      (when (< (length filtered) (length labels))
	(forge--set-topic-labels (forge-get-repository "https://github.com/pionative/quickstart") topic filtered)))))
