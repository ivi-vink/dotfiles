(require 'package)
(setq ring-bell-function 'ignore)
(tool-bar-mode -1)
(menu-bar-mode -1)
(setq backup-directory-alist `(("." . "~/.config/emacs/saves")))
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

(use-package vertico
  :ensure t
  :custom
  ;; (vertico-scroll-margin 0) ;; Different scroll margin
  (vertico-count 20) ;; Show more candidates
  (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :ensure t
  :init
  (savehist-mode))

;; Emacs minibuffer configurations.
(use-package emacs
  :ensure t
  :custom
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
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) ;; Disable defaults, use our settings
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring

(use-package corfu
  :ensure t
  ;; TAB-and-Go customizations
  :custom
  (corfu-cycle t)           ;; Enable cycling for `corfu-next/previous'
  (corfu-preselect 'prompt) ;; Always preselect the prompt
  (global-corfu-minibuffer nil)
  :config
  (define-key corfu-map [remap next-line] nil)
  (define-key corfu-map [remap previous-line] nil)
  (setq corfu-auto        t
    corfu-auto-delay  0  ;; TOO SMALL - NOT RECOMMENDED!
    corfu-auto-prefix 0) ;; TOO SMALL - NOT RECOMMENDED!
  (add-hook
    'corfu-mode-hook
    (lambda ()
      ;; Settings only for Corfu
      (setq-local
        completion-styles '(basic)
        completion-category-overrides nil
        completion-category-defaults nil)))
  (global-corfu-mode))



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
  (add-hook 'yaml-pro-ts-mode-hook (lambda () (setq-local indent-line-function 'yaml-indent-line)) 100))

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
  :hook (completion-list-mode . consult-preview-at-point-mode)

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

(repeat-mode)
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

(keymap-set yaml-pro-ts-mode-map "C-M-n" #'yaml-pro-ts-next-subtree)
(keymap-set yaml-pro-ts-mode-map "C-M-p" #'yaml-pro-ts-prev-subtree)
(keymap-set yaml-pro-ts-mode-map "C-M-u" #'yaml-pro-ts-up-level)
(keymap-set yaml-pro-ts-mode-map "C-M-d" #'yaml-pro-ts-down-level)
(keymap-set yaml-pro-ts-mode-map "C-M-k" #'yaml-pro-ts-kill-subtree)
(keymap-set yaml-pro-ts-mode-map "C-M-<backspace>" #'yaml-pro-ts-kill-subtree)
(keymap-set yaml-pro-ts-mode-map "C-M-a" #'yaml-pro-ts-first-sibling)
(keymap-set yaml-pro-ts-mode-map "C-M-e" #'yaml-pro-ts-last-sibling)

(defvar-keymap my/yaml-pro/tree-repeat-map
  :repeat t
  "n" #'yaml-pro-ts-next-subtree
  "p" #'yaml-pro-ts-prev-subtree
  "u" #'yaml-pro-ts-up-level
  "d" #'yaml-pro-ts-down-level
  "m" #'yaml-pro-ts-mark-subtree
  "k" #'yaml-pro-ts-kill-subtree
  "a" #'yaml-pro-ts-first-sibling
  "e" #'yaml-pro-ts-last-sibling
  "SPC" #'my/yaml-pro/set-mark)

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
    (set-mark-command nil)))


(defun my/pick-line-from-shell (command)
  "Run COMMAND, prompt user to pick one output line, return the chosen line."
  (let* ((out (string-trim-right (shell-command-to-string command)))
          (lines (split-string out "\n" t)))
    (completing-read "Pick: " lines nil t)))

(defun my/issue-commit ()
  "Make a commit with a message starting with ISSUE-ID."

  (interactive)
  (let*
    ((issue (my/pick-line-from-shell "gh issue list --assignee='ivi-vink'"))
      (id (save-match-data (when (string-match "\\([0-9]+\\).*" issue) (match-string 1 issue)))))
    (magit-commit-create
      (append
        (list "-e" (format "--trailer=issue:#%s" id))
        (magit-commit-arguments)))
    ))

(use-package magit
  :ensure t
  :config
  (transient-append-suffix 'magit-commit "c" '("I" "Issue commit" my/issue-commit)))

(use-package paredit
  :ensure t)

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
  "depending on time use different theme"
  ;; very early => gruvbox-light, solarized-light, nord-light
  (let* ((hour (nth 2 (decode-time (current-time))))
         (theme (cond ((<= 7 hour 8)   'doom-gruvbox-light)
                      ((= 9 hour)      'doom-solarized-light)
                      ((<= 10 hour 16) 'doom-nord-light)
                      ((<= 17 hour 18) 'doom-gruvbox-light)
                      ((<= 19 hour 22) 'doom-oceanic-next)
                      (t               'doom-laserwave))))
    (when (not (equal (car custom-enabled-themes) theme))
      (load-theme theme t))
    ;; run that function again next hour
    (run-at-time (format "%02d:%02d" (+ hour 1) 0) nil 'y/auto-update-theme)))
(y/auto-update-theme)

(use-package org
  :config
  (add-to-list 'org-file-apps '("\\.svg\\'" . "/Applications/Inkscape.app/Contents/MacOS/inkscape %s")))

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
(setq org-startup-folded t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
    '("dd4582661a1c6b865a33b89312c97a13a3885dc95992e2e5fc57456b4c545176"
       "0325a6b5eea7e5febae709dab35ec8648908af12cf2d2b569bedc8da0a3a81c1"
       "4990532659bb6a285fee01ede3dfa1b1bdf302c5c3c8de9fad9b6bc63a9252f7"
       "f1e8339b04aef8f145dd4782d03499d9d716fdc0361319411ac2efc603249326"
       "c5975101a4597094704ee78f89fb9ad872f965a84fb52d3e01b9102168e8dc40"
       "6bf350570e023cd6e5b4337a6571c0325cec3f575963ac7de6832803df4d210a"
       "0adcffc4894e2dd21283672da7c3d1025b5586bcef770fdc3e2616bdb2a771cd"
       "5e39e95c703e17a743fb05a132d727aa1d69d9d2c9cde9353f5350e545c793d4"
       "01a9797244146bbae39b18ef37e6f2ca5bebded90d9fe3a2f342a9e863aaa4fd"
       default))
 '(org-babel-load-languages '((dot . t) (shell . t) (emacs-lisp . t)))
 '(package-selected-packages
    '(## async auctex cape consult corfu counsel dap-dlv-go dap-mode
       dash-functional direnv doom-themes eat embark embark-consult
       flycheck go-mode graphviz-dot-mode gruber-darker-theme helm
       ido-completing-read+ ivy kakoune lsp-mode magit marginalia
       mc-extras meow modus-themes multiple-cursors nix-mode orderless
       paredit phi-search rust-mode smex spacious-padding
       terraform-mode treemacs undo-tree vertico visual-regexp
       visual-regexp-steroids vterm yaml-mode yaml-pro))
 '(safe-local-variable-values
    '((tex-indent-basic . 2) (tex-indent-item . 2) (tex-indent-arg . 4)
       (TeX-brace-indent-level . 2) (LaTeX-indent-level . 2)
       (LaTeX-item-indent . -2))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
