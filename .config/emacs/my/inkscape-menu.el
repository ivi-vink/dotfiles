;; e -*- lexical-binding: t; -*-
;;;; Run commands in a popup frame

(defun prot-window-delete-popup-frame (&rest _)
  "Kill selected selected frame if it has parameter `prot-window-popup-frame'.
Use this function via a hook."
  (when (frame-parameter nil 'prot-window-popup-frame)
    (delete-frame)))

(defun ns-raise-emacs-with-frame (frame)
  "Raise Emacs and select the provided frame."
  (with-selected-frame frame
    (when (and (featurep 'ns) (eq system-type 'darwin))
      (x-focus-frame frame))))

(defun make-frame-bottom (arglist)
  "Create a new frame at the bottom half of the display."
  (let* ((display-w (display-pixel-width))
          (display-h (display-pixel-height))
          (frame-h   (/ display-h 2)))
    (make-frame (append `((left   . 0)
                           (top    . ,frame-h)
                           (width  . (text-pixels . ,display-w))
                           (height . (text-pixels . ,frame-h))
                           )
                  arglist))))

(defmacro x:define-with-popup-frame (command)
  "Define interactive function which calls COMMAND in a new frame.
Make the new frame have the `prot-window-popup-frame' parameter."
  `(defun ,(intern (format "prot-window-popup-%s" command)) ()
     ,(format "Run `%s' in a popup frame with `prot-window-popup-frame' parameter.
Also see `prot-window-delete-popup-frame'." command)
     (interactive)

     (let ((frame (make-frame-bottom '((x:is-inkscape-menu-frame . t)))))
       (select-frame frame)
       (ns-raise-emacs-with-frame frame)
       (switch-to-buffer " prot-window-hidden-buffer-for-popup-frame")
       (condition-case nil
           (call-interactively ',command)
         ((quit error user-error)
          (delete-frame frame))))))

;; (declare-function org-capture "org-capture" (&optional goto keys))
;; (defvar org-capture-after-finalize-hook)

;;;###autoload (autoload 'prot-window-popup-org-capture "prot-window")
;; (prot-window-define-with-popup-frame org-capture)

;; (add-hook 'org-capture-after-finalize-hook #'prot-window-delete-popup-frame)
(x:define-with-popup-frame x:inkscape)
(add-hook 'transient-quit-hook #'x:inkscape-return)

(defun x:inkscape-delete-popup-frame (&rest _)
  "Kill selected selected frame if it has parameter `prot-window-popup-frame'.
Use this function via a hook."
  (when (frame-parameter nil 'x:is-inkscape-menu-frame)
    (delete-frame)))

(defun x:inkscape-paste-svg ()
  (interactive)
  (x:inkscape-return))

(defun x:inkscape-return (&optional paste paste-style)
  (interactive)
  (x:inkscape-delete-popup-frame)
  (ns-do-applescript "tell application \"Inkscape\" to activate")

  (when paste
    (ns-do-applescript "tell application \"System Events\" to keystroke \"v\" using command down"))

  (when paste-style
    (ns-do-applescript "tell application \"System Events\" to keystroke \"v\" using {command down, shift down}")))

(defun x:inkscape-menu-edit-latex ()
  (interactive)
  (switch-to-buffer (get-buffer-create "*inkscape-latex*"))
  (erase-buffer)
  (insert "\\(\\)")
  (goto-char 3)
  (add-hook 'kill-buffer-hook #'x:inkscape-return nil t)
  (latex-mode)
  (setq header-line-format
    (substitute-command-keys
      "Edit, then exit with ‘C-c C-c’ or abort with ‘C-c C-k’"))
  (local-set-key (kbd "C-c C-c") #'x:inkscape-compile-to-clipboard)
  (local-set-key (kbd "C-c C-k") #'x:inkscape-return)
  (keyboard-quit))

(defcustom x:inkscape-menu-latex "\\documentclass{article}
\\usepackage[usenames]{color}
\\usepackage{amsmath}
\\pagestyle{empty}
\\setlength{\\textwidth}{\\paperwidth}
\\addtolength{\\textwidth}{-3cm}
\\setlength{\\oddsidemargin}{1.5cm}
\\addtolength{\\oddsidemargin}{-2.54cm}
\\setlength{\\evensidemargin}{\\oddsidemargin}
\\setlength{\\textheight}{\\paperheight}
\\addtolength{\\textheight}{-\\headheight}
\\addtolength{\\textheight}{-\\headsep}
\\addtolength{\\textheight}{-\\footskip}
\\addtolength{\\textheight}{-3cm}
\\setlength{\\topmargin}{1.5cm}
\\addtolength{\\topmargin}{-2.54cm}
\\begin{document}
%s
\\end{document}"
  "The document header used for processing LaTeX fragments.
It is imperative that this header make sure that no page number
appears on the page.  The package defined in the variables
`org-latex-default-packages-alist' and `org-latex-packages-alist'
will either replace the placeholder \"[PACKAGES]\" in this
header, or they will be appended." :group 'x:inkscape-menu :type 'string)

(defun x:inkscape-scale-svg (input output scale)
  "Wrap SVG content in a scale transform."
  (with-temp-file output
    (insert-file-contents input)
    (goto-char (point-min))
    ;; Keep viewBox in original pt coords, wrap content in scale()
    (when (re-search-forward "<g fill=" nil t)
      (goto-char (match-beginning 0))
      (insert (format "<g transform=\"scale(%s)\">\n" scale)))
    (goto-char (point-max))
    (when (re-search-backward "</svg>" nil t)
      (insert "</g>\n"))))

(defun x:inkscape-compile-to-clipboard ()
  (interactive)
  (let ((content (buffer-string))
         (name "/tmp/emacs.inkscape.tex"))
    (with-temp-file name
      (insert (format x:inkscape-menu-latex content)))
    (when (> (call-process "tectonic" nil "*Tectonic*" nil "-Z" "shell-escape-cwd=/tmp" "--outfmt" "pdf" "--outdir" "/tmp" name) 0)
      (error "tectonic compile error"))
    ;; "convert -density %D -trim -antialias %f -quality 300 %O"
    (let ((default-directory "/tmp"))
      (when (> (call-process "pdf2svg" nil "*Tectonic*" nil "emacs.inkscape.pdf" "emacs.inkscape.svg") 0)
        (error "pdf2svg runtime error"))
      ;; inkscape-clipboard "image/svg+xml" <sketch-20260517-000609.svg
      (let ((pt->mm (* (/ 25.4 72.0) 8.0))) ; 3x scale, tweak to taste
        (x:inkscape-scale-svg "/tmp/emacs.inkscape.svg"
          "/tmp/emacs.inkscape.scaled.svg"
          pt->mm))
      (when (> (call-process "inkscape-clipboard" "/tmp/emacs.inkscape.scaled.svg" "*Tectonic*" nil "image/svg+xml") 0)
        (error "pdf2svg runtime error"))
      (x:inkscape-return t))))

(defun x:inkscape-latex-kill ()
  (interactive)
  (kill-buffer (current-buffer)))

(defcustom x:inkscape-style
  '(("stroke-opacity" . "1"))
  "Default style for inkscape paste."
  :group 'x:inkscape-menu
  :type '(alist :key-type string :value-type string))

(defun x:inkscape--build-style-svg (style-alist)
  "Build an inkscape clipboard SVG from STYLE-ALIST."
  (let ((style-string
          (mapconcat (lambda (kv)
                       (format "%s: %s" (car kv) (cdr kv)))
            style-alist
            ;; (sort style-alist (lambda (a b)
            ;;                     (string< (car a) (car b))))
            ";")))
    (format "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\"
     xmlns:inkscape=\"http://www.inkscape.org/namespaces/inkscape\">
<inkscape:clipboard style=\"%s\" /></svg>"
      style-string)))

(defun x:inkscape--build-style (args)
  (let ((result
          (mapcar
            (lambda (arg)
              (pcase arg
                ("white" '(("fill" . "white")
                            ("fill-opacity" . "1")))
                ("black" '(("fill" . "black")
                            ("fill-opacity" . "1")))
                ("fill" '(("fill" . "black")
                           ("fill-opacity" . "0.12")))))
            args)))
    (apply #'append result)))

(transient-define-suffix x:inkscape-paste-style (args)
  (interactive (list (transient-args 'x:inkscape)))
  (let* ((style (x:inkscape--build-style args))
         (svg (x:inkscape--build-style-svg style))
         (tmp "/tmp/emacs.inkscape.style.svg"))
    (message svg)
    (with-temp-file tmp (insert svg))
    (when (> (call-process "inkscape-clipboard" tmp "*Tectonic*" nil "image/x-inkscape-svg") 0)
      (error "clipboard error"))
    (x:inkscape-return nil t)))


(defclass x:inkscape-style-switch-naked (transient-argument)
  ()
  "A transient switch that carries a style key/value pair.")

(cl-defmethod transient-infix-read ((obj x:inkscape-style-switch-naked))
  (x:inkscape-)
  t)

(transient-define-argument x:inkscape--fill ()
  :description "Fill"
  :class 'transient-switch
  :key "f"
  :argument "fill")

(transient-define-argument x:inkscape--black ()
  :description "Black"
  :class 'transient-switch
  :key "b"
  :argument "black")

(transient-define-argument x:inkscape--white ()
  :description "White"
  :class 'transient-switch
  :key "w"
  :argument "white")

(transient-define-prefix x:inkscape ()
  "Mode interacting with inkscape by clipboard."
  ;; :display-action '(x:inkscape-menu-popup)
  ["Style"
    (x:inkscape--fill)
    (x:inkscape--black)
    (x:inkscape--white)]
  ["Paste"
    ("e" "Edit latex"   x:inkscape-menu-edit-latex :transient t)
    ("v" "Style" x:inkscape-paste-style)]
  ["Other"
    ("q" "Quit"       x:inkscape-return)])

(defvar x:inkscape-popup-frame nil
  "The popup frame used for inkscape interaction.")

(defun x:inkscape-menu-popup (buffer alist)
  (let ((window (display-buffer-pop-up-frame buffer alist)))
    (let ((frame (window-frame window)))
      (setq x:inkscape-popup-frame frame)
      (set-frame-parameter frame 'x:is-inkscape-menu-frame t)
      (x-focus-frame frame)
      window)))

(defun x:inkscape-menu ()
  (interactive)
  (let ((transient-display-buffer-action
          '(x:inkscape-menu-popup)))
    (x:inkscape)))

;;;; The emacsclient call depends on the daemon or `server-mode' (I use the latter)
(use-package server
  :ensure nil
  :defer 1
  :config
  (unless (server-running-p)
    (server-start)))

;;;; The emacsclient calls that need ot be bound to system-wide keys

;; emacsclient -e '(prot-window-popup-org-capture)'
;; emacsclient -e '(prot-window-popup-tmr)'
;; (add-to-list 'org-preview-latex-process-alist '(tectonic :programs ("tectonic" "convert")
;;                :description "pdf > png"
;;                :message "you need install the programs: tectonic and imagemagick."
;;                :image-input-type "pdf"
;;                :image-output-type "png"
;;                :image-size-adjust (1.0 . 1.0)
;;                :latex-compiler
;;                  ("tectonic -Z shell-escape-cwd=%o --outfmt pdf --outdir %o %f")
;;                :image-converter
;;                ("convert -density %D -trim -antialias %f -quality 300 %O")))
(provide 'inkscape-menu)
