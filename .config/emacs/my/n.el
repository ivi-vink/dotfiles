;; -*- lexical-binding: t; -*-
(require 'transient)
(require 'cl-lib)

(defun noboo--read-config ()
  (flatten-list
    (mapcar
      (lambda (line)
        (let ((parts (string-split line "=")))
          (list (intern (string-join (list ":" (car parts)))) (cdr parts))))
      (seq-filter (lambda (l) (> (length l) 0))  (process-lines "noboo" "config" "list")))))

(defun noboo--parse-note-row (line)
  (flatten-list (seq-mapn (lambda (key value) (list key value))
    (list :book :chapter :name :title :file)
    (string-split line "[[:space:]]+"))))

(defun noboo--pick-line-from-command (program &rest args)
  "Run COMMAND, prompt user to pick one output line, return the chosen line."
  (let* ((lines (seq-filter (lambda (l) (> (length l) 0))
                  (apply #'process-lines (append (list program) args)))))
    (completing-read "Pick: " (cdr lines) nil nil)))

(defun noboo-edit ()
  (interactive)
  (when (> (start-process "noboo" "*Noboo*" "noboo" "edit") 0)
      (error "tectonic compile error")))

(defun noboo-get (book chapter name)
  (interactive)
  (let ((bookflag (if book (list "-book" book) '()))
         (chapterflag (if chapter (list "-chapter" chapter) '()))
         (nameflag (if name (list "-name" name) '())))
    (noboo--parse-note-row
      (apply #'noboo--pick-line-from-command
        (append '("noboo" "get") bookflag chapterflag nameflag)))))

(defun noboo-roam-capture-log ()
  (interactive)
  (let
    ((org-capture-templates
       (list (list "l" "WorkLog"
               'entry
               (list 'file
                 (let ((note (noboo-get nil "log" nil)))
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

    (org-capture)))

(transient-define-prefix noboo-menu ()
  "Interact with notes db"
  ["Notes"
    ("l" "Log" noboo-roam-capture-log)
    ("e" "Edit" noboo-edit)])



(provide 'n)
