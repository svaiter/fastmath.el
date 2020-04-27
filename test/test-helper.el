;;; fastmath-integration-test.el --- Test helpers for fastmath -*- lexical-binding: t -*-

;; Copyright © 2020 Samuel Vaiter <samuel.vaiter@gmail.com>

;; Author: Samuel Vaiter <samuel.vaiter@gmail.com>
;; URL: https//github.com/svaiter/fastmath.el
;; Keywords: tex; math
;; Version: 1.0-snapshot

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Lighting fast math mode for LaTeX.
;;

;;; Code:

(require 'ert)
(require 'fastmath)

;; Imported from smartparens
;; TODO: Simplify, we need less here
(defmacro fm-test-with-temp-buffer (initial initform &rest forms)
  "Setup a new buffer, then run FORMS.
First, INITFORM are run in the newly created buffer.
Then `smartparens-mode' is turned on.  Then INITIAL is
inserted (it is expected to evaluate to string).  If INITIAL
contains | put point there as the initial position (the character
is then removed).  If it contains §, put mark there (the
character is then removed).
Finally, FORMS are run."
  (declare (indent 2)
           (debug (form form body)))
  `(save-window-excursion
     (let ((case-fold-search nil))
       (with-temp-buffer
         (set-input-method nil)
         ,initform
         (LaTeX-mode)
         (fastmath-mode 1)
         (pop-to-buffer (current-buffer))
         (insert ,initial)
         (goto-char (point-min))
         (when (search-forward "§" nil t)
           (delete-char -1)
           (set-mark (point))
           (activate-mark))
         (goto-char (point-min))
         (when (search-forward "|" nil t)
           (delete-char -1))
         ,@forms))))

(defun fm-buffer-equals (result)
  "Compare buffer to RESULT.
RESULT is a string which should equal the result of
`buffer-string' called in the current buffer.
If RESULT contains |, this represents the position of `point' and
should match.
If RESULT contains §, this represents the position of `mark' and
should match."
  (should (equal (buffer-string) (replace-regexp-in-string "[|§]" "" result)))
  (when (string-match-p "|" result)
    (should (= (1+ (string-match-p
                    "|" (replace-regexp-in-string "[§]" "" result)))
               (point))))
  (when (string-match-p "§" result)
    (should (= (1+ (string-match-p
                    "§" (replace-regexp-in-string "[|]" "" result)))
               (mark)))))

(defun fm-test-insertion (initial result)
  (fm-test-with-temp-buffer initial
      nil
    (execute-kbd-macro (kbd "SPC"))
    (fm-buffer-equals result)))

;;; test-helper.el ends here
