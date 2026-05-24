;; e -*- lexical-binding: t; -*-
;;;; Run commands in a popup frame
(require 'cl-lib)

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
    (ns-do-applescript "tell application \"System Events\" to keystroke \"v\" using {command down, shift down}"))
  (keyboard-quit))

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


(setq x:inkscape--style-pixels 1.327)
(setq x:inkscape--style-normal-width (* 0.4 x:inkscape--style-pixels))
(setq x:inkscape--style-thick-width (* 0.8 x:inkscape--style-pixels))
(setq x:inkscape--style-heavy-width (* 1.2 x:inkscape--style-pixels))

(defun x:inkscape--build-style-svg (styles)
  "Build an inkscape clipboard SVG from STYLE-ALIST."
  (let*
    ((style-map
       (seq-reduce
         (lambda (m style)
           (funcall (oref style argument) m))
         (sort styles
           :key (lambda (style) (oref style style-group))
           :lessp (lambda (a b)
                    (pcase a
                      ("weight" t))))
         (list
           :fill "none"
           :fill-opacity "1"
           :stroke-width (number-to-string x:inkscape--style-normal-width)
           :marker-start "none"
           :marker-end "none"
           :stroke-dasharray "none")))
      (style-string (cl-loop for (k v) on style-map by #'cddr
                      collect (format "%s: %s" (substring (symbol-name k) 1) v)
                      into parts finally return (mapconcat (lambda(i)i) parts ";")))
      (arrow-string (if (let ((start (plist-get style-map :marker-start))
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
markerHeight=\"1.690\" markerWidth=\"0.911\">
  <g transform=\"scale(%s)\">
    <path
       d=\"M -1.55415,2.0722 C -1.42464,1.29512 0,0.1295 0.38852,0 0,-0.1295 -1.42464,-1.29512 -1.55415,-2.0722\"
       style=\"fill:none;stroke:#000000;stroke-width:0.6;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1\"
       inkscape:connector-curvature=\"0\" />
   </g>
</marker>
</defs>
"
                          w
                          (/ (+ (* 2.40 (string-to-number w)) 3.87) (* 4.5 (string-to-number w)))
                          ))
                      "")))
    (pp style-string)
    (pp arrow-string)
    (format "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg>%s<inkscape:clipboard style=\"%s\" /></svg>"
      arrow-string
      style-string)))

(defun x:inkscape-paste-style (styles)
  (interactive)
  (let* ((svg (x:inkscape--build-style-svg styles))
          (tmp "/tmp/emacs.inkscape.style.svg"))
    (with-temp-file tmp (insert svg))
    (when (> (call-process "inkscape-clipboard" tmp "*Tectonic*" nil "image/x-inkscape-svg") 0)
      (error "clipboard error"))
    (x:inkscape-return nil t)))

(defclass x:inkscape--style-switch (transient-switch)
  ((style-value :initarg :style-value)
    (style-group :initarg :style-group))
  "hello")

(cl-defmethod transient-infix-read ((obj x:inkscape--style-switch))
  (oref obj style-value))

(cl-defmethod transient-infix-value ((obj x:inkscape--style-switch))
  (when (oref obj value)
    (cons (oref obj style-group) (oref obj value))))

(cl-defmethod transient-format-value ((obj x:inkscape--style-switch))
  (propertize (oref obj description)
              'face (if (oref obj value)
                        (if (oref obj inapt)
                            'transient-inapt-argument
                          'transient-argument)
                      'transient-inactive-argument)))

(cl-defmethod transient-infix-set ((obj x:inkscape--style-switch) value)
  ;; Deactivate all other infixes in the same style-group
  (dolist (other transient--suffixes)
    (when (and (cl-typep other 'x:inkscape--style-switch)
            (equal (oref other style-group) (oref obj style-group))
            (not (eq other obj)))
      (oset other value nil)))
  (oset obj value (not (oref obj value)))
  (let* ((styles
           (seq-filter
             (lambda (suffix)
               (and (cl-typep suffix 'x:inkscape--style-switch) (oref suffix value)))
             transient--suffixes))
          (groups
            (mapcar
              (lambda (style) (oref style style-group))
              styles)))
    (when
      (and
        (member "fill" groups)
        (member "stroke" groups)
        (member "weight" groups))
      (x:inkscape-paste-style styles))))

(defun map-put-and-return (m k v) (plist-put m k v))
(transient-define-infix x:inkscape--style-nofill () "Style: nofill"
  :class 'x:inkscape--style-switch
  :style-group "fill"
  :description "nofill"
  :style-value "nofill"
  :init-value (lambda (obj) (oset obj value t))
  :key "w"
  :argument (lambda (m)
              (thread-first m
                (map-put-and-return :fill "none")
                (map-put-and-return :fill-opacity "1"))))
(transient-define-infix x:inkscape--style-grey () "Style: grey"
  :class 'x:inkscape--style-switch
  :style-group "fill"
  :description "grey"
  :style-value "grey"
  :key "f"
  :argument (lambda (m)
              (thread-first m
                (map-put-and-return :fill "black")
                (map-put-and-return :fill-opacity "0.12"))))
(transient-define-infix x:inkscape--style-black () "Style: black"
  :class 'x:inkscape--style-switch
  :style-group "fill"
  :description "black"
  :style-value "black"
  :key "b"
  :argument (lambda (m)
              (thread-first m
                (map-put-and-return :fill "black")
                (map-put-and-return :fill-opacity "1"))))
(transient-define-infix x:inkscape--style-white () "Style: white"
  :class 'x:inkscape--style-switch
  :style-group "fill"
  :description "white"
  :style-value "white"
  :key "w"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :fill "white")
      (map-put-and-return :fill-opacity "1"))))
(transient-define-infix x:inkscape--style-arrow () "Style: arrow"
  :class 'x:inkscape--style-switch
  :style-group "arrow"
  :description "arrow"
  :style-value "arrow"
  :key "a"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :marker-end
        (format "url(#marker-arrow-%s)" (plist-get m :stroke-width))))))
(transient-define-infix x:inkscape--style-arrows () "Style: arrows"
  :class 'x:inkscape--style-switch
  :style-group "arrow"
  :description "arrows"
  :style-value "arrows"
  :key "x"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :marker-start
        (format "url(#marker-arrow-%s)" (plist-get m :stroke-width)))
      (map-put-and-return :marker-end
        (format "url(#marker-arrow-%s)" (plist-get m :stroke-width))))))
(transient-define-infix x:inkscape--style-solid () "Style: solid"
  :class 'x:inkscape--style-switch
  :style-group "stroke"
  :description "solid"
  :style-value "solid"
  :key "s"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :stroke-dasharray "none"))))
(transient-define-infix x:inkscape--style-dotted () "Style: dotted"
    :class 'x:inkscape--style-switch
    :style-group "stroke"
    :description "dotted"
    :style-value "dotted"
    :key "d"
    :argument
    (lambda (m)
      (thread-first m
        (map-put-and-return :stroke-dasharray
          (format "%s,%s"
            (plist-get m :stroke-width)
            (number-to-string (* 2 x:inkscape--style-pixels)))))))
(transient-define-infix x:inkscape--style-dashed () "Style: dashed"
  :class 'x:inkscape--style-switch
  :style-group "stroke"
  :description "dashed"
  :style-value "dashed"
  :key "e"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :stroke-dasharray
        (format "%s,%s"
          (number-to-string (* 3 x:inkscape--style-pixels))
          (number-to-string (* 3 x:inkscape--style-pixels)))))))
(transient-define-infix x:inkscape--style-normal () "Style: normal"
  :class 'x:inkscape--style-switch
  :style-group "weight"
  :description "normal"
  :init-value (lambda (obj) (oset obj value t))
  :style-value "normal"
  :key "n"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :stroke "black")
      (map-put-and-return :stroke-width (number-to-string x:inkscape--style-normal-width)))))
(transient-define-infix x:inkscape--style-thick () "Style: thick"
  :class 'x:inkscape--style-switch
  :style-group "weight"
  :description "thick"
  :style-value "thick"
  :key "g"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :stroke-width (number-to-string x:inkscape--style-thick-width)))))
(transient-define-infix x:inkscape--style-heavy () "Style: heavy"
  :class 'x:inkscape--style-switch
  :style-group "weight"
  :description "heavy"
  :style-value "heavy"
  :key "h"
  :argument
  (lambda (m)
    (thread-first m
      (map-put-and-return :stroke-width (number-to-string x:inkscape--style-heavy-width)))))

(transient-define-prefix x:inkscape ()
  "Mode interacting with inkscape by clipboard."
  ;; :display-action '(x:inkscape-menu-popup)
  ["Style"
    ["arrow"
      (x:inkscape--style-arrow)
      (x:inkscape--style-arrows)]
    ["Fill"
      (x:inkscape--style-nofill)
      (x:inkscape--style-grey)
      (x:inkscape--style-black)
      (x:inkscape--style-white)]
    ["Stroke"
      (x:inkscape--style-solid)
      (x:inkscape--style-dotted)
      (x:inkscape--style-dashed)]
    ["Weight"
      (x:inkscape--style-normal)
      (x:inkscape--style-thick)
      (x:inkscape--style-heavy)]]
  ["Paste"
    ("t" "Edit latex"   x:inkscape-menu-edit-latex :transient t)
    ]
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
