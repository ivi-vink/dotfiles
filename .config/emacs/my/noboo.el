;; -*- lexical-binding: t; -*-
(require 'transient)
(require 'cl-lib)

;; noboo menu
(transient-define-prefix noboo-menu ()
  "Interact with notes db"
  ["Flags"
    (noboo--menu-flag-mode)
    (noboo--menu-flag-book)
    (noboo--menu-flag-chapter)]
  ["Noboo"
    [("e" "Edit" noboo-edit)
      ("i" "Insert" noboo-insert)
      ("l" "Log" noboo-roam-capture-log)]
    [("E" "Edit current" noboo-roam-capture-log)
      ("I" "Insert current" noboo-roam-capture-log)]])

(transient-define-infix noboo--menu-flag-mode () "--mode"
  :class 'transient-switches
  :description "EditMode for Note"
  :key "m"
  :argument-format "--mode=%s"
  :argument-regexp "pen|figure"
  :choices '("pen" "figure"))

(transient-define-infix noboo--menu-flag-book () "--book"
  :class 'transient-option
  :description "Book"
  :key "-b"
  :argument "--book="
  :init-value (lambda (obj)
                (when-let* ((file-name (expand-file-name default-directory))
                             (books-dir (plist-get (noboo--read-config) :books-dir))
                             ((< (length books-dir) (length file-name)))
                             (rel (substring-no-properties file-name (+ 1 (length books-dir))))
                             (book (seq-filter
                                     (lambda (book-name) (string-match-p (regexp-quote book-name) rel))
                                     (cdr (process-lines "noboo" "get" "books")))))
                  (oset obj value (car book))))
  :reader (lambda (prompt initial-input history)
            (funcall
              (noboo--pick-line-from-command "noboo" "get" "books")
              prompt initial-input history)))

(transient-define-infix noboo--menu-flag-chapter () "--chapter"
  :class 'transient-option
  :description "Chapter"
  :key "-c"
  :argument "--chapter="
  ;; :init-value (lambda (obj) (oset obj value "log"))
  :reader
  (lambda (prompt initial-input history)
    (let* ((book-value
             (when-let* ((suffix (car (seq-filter
                                   (lambda (s)
                                     (when (cl-typep s 'transient-option)
                                       (equal (oref s argument) "--book=")))
                                   transient--suffixes))))
               (oref suffix value))))
      (funcall
        (apply #'noboo--pick-line-from-command
          (append '("noboo" "get" "chapters")
            (when book-value (list "--book" book-value))))
        prompt initial-input history))))

(setq noboo--config nil)
(defun noboo--read-config ()
  (if noboo--config
    noboo--config
    (let
      ((cfg
         (flatten-list
           (mapcar
             (lambda (line)
               (let ((parts (string-split line "=")))
                 (list (intern (string-join (list ":" (car parts)))) (cdr parts))))
             (seq-filter (lambda (l) (> (length l) 0))  (process-lines "noboo" "config" "list"))))))
      (setq noboo--config cfg)
      cfg)))

(defun noboo--parse-note-row (line)
  (flatten-list (seq-mapn (lambda (key value) (list key value))
    (list :book :chapter :name :title :file)
    (string-split line "[[:space:]]+"))))

(defun noboo--pick-line-from-command (program &rest args)
  "Run COMMAND, prompt user to pick one output line, return the chosen line."
  (let* ((lines (seq-filter (lambda (l) (> (length l) 0))
                  (apply #'process-lines (append (list program) args)))))
    (lambda (prompt initial-input history)
      (completing-read prompt (cdr lines) nil nil initial-input history))))

(defun noboo-edit ()
  (interactive)
  (apply #'start-process (append (list "noboo" "*noboo*" "noboo" "edit") (transient-args 'noboo-menu))))

(defun noboo-insert ()
  (interactive)
  (when (> (apply #'start-process (append (list "noboo" "*noboo*" "noboo" "insert") (transient-args 'noboo-menu))) 0)
      (error "tectonic compile error")))

(defun noboo-get-notes (book chapter name)
  (interactive)
  (let ((bookflag (if book (list "-book" book) '()))
         (chapterflag (if chapter (list "-chapter" chapter) '()))
         (nameflag (if name (list "-name" name) '())))
    (noboo--parse-note-row
      (let ((reader (apply #'noboo--pick-line-from-command
                      (append '("noboo" "get" "notes") bookflag chapterflag nameflag))))
        (funcall reader "Note: " nil nil)))))

(defun noboo-roam-capture-log ()
  (interactive)
  (let
    ((org-capture-templates
       (list (list "l" "WorkLog"
               'entry
               (list 'file
                 (let ((note (noboo-get-notes nil "log" nil)))
                   (string-join
                     (list
                       (plist-get (noboo--read-config) :books-dir)
                       (plist-get note :book)
                       (plist-get note :chapter)
                       (plist-get note :name)
                       (plist-get note :file))
                     "/")))
               "* %t

%?"
               :unnarrowed t))))
    (org-capture nil "l")))

;; inkscape menu
(setq noboo--inkscape-style-pixels 1.327)
(setq noboo--inkscape-style-normal-width (* 0.4 noboo--inkscape-style-pixels))
(setq noboo--inkscape-style-thick-width (* 0.8 noboo--inkscape-style-pixels))
(setq noboo--inkscape-style-heavy-width (* 1.2 noboo--inkscape-style-pixels))

(transient-define-prefix noboo-inkscape-menu ()
  "Mode interacting with inkscape by clipboard."
  ["Style"
    ["arrow"
      (noboo--inkscape-style-arrow)
      (noboo--inkscape-style-arrows)]
    ["Fill"
      (noboo--inkscape-style-nofill)
      (noboo--inkscape-style-grey)
      (noboo--inkscape-style-black)
      (noboo--inkscape-style-white)]
    ["Stroke"
      (noboo--inkscape-style-solid)
      (noboo--inkscape-style-dotted)
      (noboo--inkscape-style-dashed)]
    ["Weight"
      (noboo--inkscape-style-normal)
      (noboo--inkscape-style-thick)
      (noboo--inkscape-style-heavy)]]
  ["Actions"
    ("SPC" "Confirm Style" noboo--inkscape-confirm-style)
    ("t" "Edit latex"   noboo--inkscape-edit-latex :transient t)
    ("c" "Save object"   noboo--inkscape-save-object)
    ("v" "Paste object"   noboo--inkscape-paste-object)
    ]
  ["Other"
    ("q" "Quit"       noboo--inkscape-return)])

(defclass noboo--inkscape-style-switch (transient-switch)
  ((style-value :initarg :style-value)
    (style-group :initarg :style-group))
  "hello")

(cl-defmethod transient-infix-read ((obj noboo--inkscape-style-switch))
  (oref obj style-value))

(cl-defmethod transient-infix-value ((obj noboo--inkscape-style-switch))
  (when (oref obj value)
    (cons (oref obj style-group) (oref obj argument))))

(cl-defmethod transient-format-value ((obj noboo--inkscape-style-switch))
  (propertize (oref obj description)
              'face (if (oref obj value)
                        (if (oref obj inapt)
                            'transient-inapt-argument
                          'transient-argument)
                      'transient-inactive-argument)))

(cl-defmethod transient-infix-set ((obj noboo--inkscape-style-switch) value)
  ;; Deactivate all other infixes in the same style-group
  (dolist (other transient--suffixes)
    (when (and (cl-typep other 'noboo--inkscape-style-switch)
            (equal (oref other style-group) (oref obj style-group))
            (not (eq other obj)))
      (oset other value nil)))
  (oset obj value (not (oref obj value))))

(defun noboo--map-put-and-return (m k v) (plist-put m k v))

(transient-define-infix noboo--inkscape-style-nofill () "Style: nofill"
  :class 'noboo--inkscape-style-switch
  :style-group "fill"
  :description "nofill"
  :style-value "nofill"
  :init-value (lambda (obj) (oset obj value t))
  :key "n"
  :argument (lambda (m)
              (thread-first m
                (noboo--map-put-and-return :fill "none")
                (noboo--map-put-and-return :fill-opacity "1"))))
(transient-define-infix noboo--inkscape-style-grey () "Style: grey"
  :class 'noboo--inkscape-style-switch
  :style-group "fill"
  :description "grey"
  :style-value "grey"
  :key "f"
  :argument (lambda (m)
              (thread-first m
                (noboo--map-put-and-return :fill "black")
                (noboo--map-put-and-return :fill-opacity "0.12"))))
(transient-define-infix noboo--inkscape-style-black () "Style: black"
  :class 'noboo--inkscape-style-switch
  :style-group "fill"
  :description "black"
  :style-value "black"
  :key "b"
  :argument (lambda (m)
              (thread-first m
                (noboo--map-put-and-return :fill "black")
                (noboo--map-put-and-return :fill-opacity "1"))))
(transient-define-infix noboo--inkscape-style-white () "Style: white"
  :class 'noboo--inkscape-style-switch
  :style-group "fill"
  :description "white"
  :style-value "white"
  :key "w"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :fill "white")
      (noboo--map-put-and-return :fill-opacity "1"))))
(transient-define-infix noboo--inkscape-style-arrow () "Style: arrow"
  :class 'noboo--inkscape-style-switch
  :style-group "arrow"
  :description "arrow"
  :style-value "arrow"
  :key "a"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :marker-end
        (format "url(#marker-arrow-%s)" (plist-get m :stroke-width))))))
(transient-define-infix noboo--inkscape-style-arrows () "Style: arrows"
  :class 'noboo--inkscape-style-switch
  :style-group "arrow"
  :description "arrows"
  :style-value "arrows"
  :key "x"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :marker-start
        (format "url(#marker-arrow-%s)" (plist-get m :stroke-width)))
      (noboo--map-put-and-return :marker-end
        (format "url(#marker-arrow-%s)" (plist-get m :stroke-width))))))
(transient-define-infix noboo--inkscape-style-solid () "Style: solid"
  :class 'noboo--inkscape-style-switch
  :style-group "stroke"
  :description "solid"
  :style-value "solid"
  :init-value (lambda (obj) (oset obj value t))
  :key "s"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :stroke-dasharray "none"))))
(transient-define-infix noboo--inkscape-style-dotted () "Style: dotted"
    :class 'noboo--inkscape-style-switch
    :style-group "stroke"
    :description "dotted"
    :style-value "dotted"
    :key "d"
    :argument
    (lambda (m)
      (thread-first m
        (noboo--map-put-and-return :stroke-dasharray
          (format "%s,%s"
            (plist-get m :stroke-width)
            (number-to-string (* 2 noboo--inkscape-style-pixels)))))))
(transient-define-infix noboo--inkscape-style-dashed () "Style: dashed"
  :class 'noboo--inkscape-style-switch
  :style-group "stroke"
  :description "dashed"
  :style-value "dashed"
  :key "e"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :stroke-dasharray
        (format "%s,%s"
          (number-to-string (* 3 noboo--inkscape-style-pixels))
          (number-to-string (* 3 noboo--inkscape-style-pixels)))))))
(transient-define-infix noboo--inkscape-style-normal () "Style: normal"
  :class 'noboo--inkscape-style-switch
  :style-group "weight"
  :description "normal"
  :init-value (lambda (obj) (oset obj value t))
  :style-value "normal"
  :key "m"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :stroke "black")
      (noboo--map-put-and-return :stroke-width (number-to-string noboo--inkscape-style-normal-width)))))
(transient-define-infix noboo--inkscape-style-thick () "Style: thick"
  :class 'noboo--inkscape-style-switch
  :style-group "weight"
  :description "thick"
  :style-value "thick"
  :key "g"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :stroke-width (number-to-string noboo--inkscape-style-thick-width)))))
(transient-define-infix noboo--inkscape-style-heavy () "Style: heavy"
  :class 'noboo--inkscape-style-switch
  :style-group "weight"
  :description "heavy"
  :style-value "heavy"
  :key "h"
  :argument
  (lambda (m)
    (thread-first m
      (noboo--map-put-and-return :stroke-width (number-to-string noboo--inkscape-style-heavy-width)))))

(defun noboo--inkscape-confirm-style ()
  (interactive)
  ;; filter args for styles...
  (noboo--inkscape-paste-style (transient-args 'noboo-inkscape-menu)))

(defun noboo--inkscape-paste-style (styles)
  (interactive)
  (let* ((svg (noboo--inkscape-build-style-svg styles))
          (tmp "/tmp/emacs.inkscape.style.svg"))
    (with-temp-file tmp (insert svg))
    (when (> (call-process "inkscape-clipboard" tmp "*Tectonic*" nil "image/x-inkscape-svg") 0)
      (error "clipboard error"))
    (noboo--inkscape-return nil t)))

(defun noboo--inkscape-build-style-svg (styles)
  "Build an inkscape clipboard SVG from STYLE-ALIST."
  (let*
    ((sorted-styles
       (sort styles
         :key (lambda (style) (car style))
         :lessp (lambda (a b)
                  (pcase a
                    ("weight" t)))))

      (style-map
        (seq-reduce
          (lambda (m style)
            (funcall (cdr style) m))
          ((lambda(x) (pp x) x) sorted-styles)
          (list
            :fill "none"
            :fill-opacity "1"
            :stroke-width (number-to-string noboo--inkscape-style-normal-width)
            :marker-start "none"
            :marker-end "none"
            :stroke-dasharray "none")))

      (style-string
        (cl-loop for (k v) on style-map by #'cddr
          collect (format "%s: %s" (substring (symbol-name k) 1) v)
          into parts finally return (mapconcat (lambda(i)i) parts ";")))

      (arrow-string
        (if (let ((start (plist-get style-map :marker-start))
                   (end (plist-get style-map :marker-end)))
              (or
                (and start (not (equal start "none")))
                (and end (not (equal end "none")))))
          (let
            ((w (plist-get style-map :stroke-width)))
            (format "
<defs id=\"marker-defs\">
<marker
id=\"marker-arrow-%s\"
orient=\"auto-start-reverse\"
refY=\"0\" refX=\"0\"
markerUnits=\"strokeWidth\" markerHeight=\"10.402542\" markerWidth=\"7.0301356\">
    <path
       d=\"M -1.55415,2.0722 C -1.42464,1.29512 0,0.1295 0.38852,0 0,-0.1295 -1.42464,-1.29512 -1.55415,-2.0722\"
       style=\"fill:none;stroke:#000000;stroke-width:0.6;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1\"
       inkscape:connector-curvature=\"0\" />
</marker>
</defs>
"
              w
              ))
          "")))
    (pp style-string)
    (pp arrow-string)
    (format "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg>%s<inkscape:clipboard style=\"%s\" /></svg>"
      arrow-string
      style-string)))

(defun noboo--inkscape-edit-latex ()
  (interactive)
  (switch-to-buffer (get-buffer-create "*inkscape-latex*"))
  (erase-buffer)
  (insert "\\(\\)")
  (goto-char 3)
  (add-hook 'kill-buffer-hook #'noboo--inkscape-return nil t)
  (latex-mode)
  (setq header-line-format
    (substitute-command-keys
      "Edit, then exit with ‘C-c C-c’ or abort with ‘C-c C-k’"))
  (local-set-key (kbd "C-c C-c") #'noboo--inkscape-compile-to-clipboard)
  (local-set-key (kbd "C-c C-k") #'noboo--inkscape-return)
  (keyboard-quit))

;; should it not live in noboo?
(defcustom noboo--inkscape-menu-latex "\\documentclass{article}
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

(defun noboo--inkscape-compile-to-clipboard ()
  (interactive)
  (let ((content (buffer-string))
         (name "/tmp/emacs.inkscape.tex"))
    (with-temp-file name
      (insert (format noboo--inkscape-menu-latex content)))
    (when (> (call-process "tectonic" nil "*Tectonic*" nil "-Z" "shell-escape-cwd=/tmp" "--outfmt" "pdf" "--outdir" "/tmp" name) 0)
      (error "tectonic compile error"))
    ;; "convert -density %D -trim -antialias %f -quality 300 %O"
    (let ((default-directory "/tmp"))
      (when (> (call-process "pdf2svg" nil "*Tectonic*" nil "emacs.inkscape.pdf" "emacs.inkscape.svg") 0)
        (error "pdf2svg runtime error"))
      ;; inkscape-clipboard "image/svg+xml" <sketch-20260517-000609.svg
      (let ((pt->mm (* (/ 25.4 72.0) 8.0))) ; 3x scale, tweak to taste
        (noboo--inkscape-scale-svg "/tmp/emacs.inkscape.svg"
          "/tmp/emacs.inkscape.scaled.svg"
          pt->mm))
      (when (> (call-process "inkscape-clipboard" "/tmp/emacs.inkscape.scaled.svg" "*Tectonic*" nil "image/svg+xml") 0)
        (error "pdf2svg runtime error"))
      (noboo--inkscape-return t))))

(defun noboo--inkscape-scale-svg (input output scale)
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

(defun noboo--inkscape-save-object ()
  (interactive)
  (when-let*
    ((cfg (noboo--read-config))
      (books-dir (plist-get cfg :books-dir))
      (inkscape-objects-dir (file-name-concat books-dir ".noboo" "inkscape" "objects"))
      (choice
        (completing-read "Object:"
          (mapcar
            (lambda (filename)
              (f-base filename))
            (f-entries inkscape-objects-dir))
          nil nil nil nil)))
    (f-mkdir-full-path inkscape-objects-dir)
    (noboo--focus-inkscape)
    (sleep-for 0.2)
    (noboo--keyboard-copy)
    (when-let* ((object (noboo--inkscape-clipboard-get)))
      (with-temp-file (file-name-concat inkscape-objects-dir (string-join (list choice ".svg")))
        (insert object))
      (noboo--focus-inkscape)
      (noboo--window-delete-popup-frame))))

(defun noboo--inkscape-paste-object ()
  (interactive)
  (when-let*
    ((cfg (noboo--read-config))
      (books-dir (plist-get cfg :books-dir))
      (inkscape-objects-dir (file-name-concat books-dir ".noboo" "inkscape" "objects"))
      (choice
        (completing-read "Object:"
          (mapcar
            (lambda (filename)
              (f-base filename))
            (f-entries inkscape-objects-dir))
          nil nil nil nil)))
    (when-let* ((object (file-name-concat inkscape-objects-dir (string-join (list choice ".svg")))))
      (noboo--inkscape-clipboard-set
        (with-temp-buffer
          (insert-file-contents object)
          (buffer-string)))
      (noboo--focus-inkscape)
      (sleep-for 0.2)
      (noboo--keyboard-paste)
      (noboo--window-delete-popup-frame))))

(defun noboo--inkscape-clipboard-get ()
  (with-temp-buffer
    (let ((status
            (apply #'call-process (list "inkscape-clipboard-get" nil (current-buffer) nil "image/x-inkscape-svg"))))
      (unless (eq status 0)
	(error "%s exited with status %s" "inkscape-clipboard-get" status))
      (buffer-string))))

(defun noboo--inkscape-clipboard-set (content)
  (interactive)
  (let ((infile "/tmp/emacs.inkscape.paste.svg"))
    (with-temp-file infile (insert content))
    (when (> (call-process "inkscape-clipboard" infile "*noboo*" nil "image/x-inkscape-svg") 0)
      (error "clipboard error"))))

(defun noboo--inkscape-return (&optional paste paste-style)
  (interactive)
  (noboo--window-delete-popup-frame)
  (noboo--focus-inkscape)
  (when paste (noboo--keyboard-paste))
  (when paste-style (noboo--keyboard-shift-paste))
  (keyboard-quit))

(defun noboo--keyboard-paste ()
  (ns-do-applescript "tell application \"System Events\" to keystroke \"v\" using command down"))
(defun noboo--keyboard-copy ()
  (ns-do-applescript "tell application \"System Events\" to keystroke \"c\" using command down"))
(defun noboo--keyboard-shift-paste ()
  (ns-do-applescript "tell application \"System Events\" to keystroke \"v\" using {command down, shift down}"))
(defun noboo--focus-inkscape ()
  (ns-do-applescript "tell application \"Inkscape\" to activate"))

;; popup windows
(defun noboo--window-delete-popup-frame (&rest _)
  "Kill selected selected frame if it has parameter `prot-window-popup-frame'.
Use this function via a hook."
  (when (frame-parameter nil 'noboo-window-popup-frame)
    (delete-frame)))

(defun noboo--ns-raise-emacs-with-frame (frame)
  "Raise Emacs and select the provided frame."
  (with-selected-frame frame
    (when (and (featurep 'ns) (eq system-type 'darwin))
      (x-focus-frame frame))))

(defun noboo--make-frame-bottom (arglist)
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

(defmacro noboo--define-with-popup-frame (command)
  "Define interactive function which calls COMMAND in a new frame.
Make the new frame have the `noboo-window-popup-frame' parameter."
  `(defun ,(intern (format "noboo-window-popup-%s" command)) ()
     ,(format "Run `%s' in a popup frame with `noboo--window-popup-frame' parameter.
Also see `noboo--window-delete-popup-frame'." command)
     (interactive)

     (let ((frame (noboo--make-frame-bottom '((noboo-window-popup-frame . t)))))
       (select-frame frame)
       (noboo--ns-raise-emacs-with-frame frame)
       (switch-to-buffer " noboo-window-hidden-buffer-for-popup-frame")
       (condition-case nil
           (call-interactively ',command)
         ((quit error user-error)
          (delete-frame frame))))))

(noboo--define-with-popup-frame noboo-inkscape-menu)
(add-hook 'transient-quit-hook #'noboo--inkscape-return)

(provide 'noboo)
