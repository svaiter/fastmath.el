;;; fastmath.el --- Lighting fast math mode for LaTeX. -*- lexical-binding: t -*-

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

(require 'texmathp)
(require 'yasnippet)

(defgroup fastmath nil
  "Lighting fast math mode for LaTeX.."
  :tag "Fast input for LaTeX Math Mode"
  :prefix "fastmath-"
  :group 'tex
  :link '(url-link :tag "GitHub" "https://github.com/svaiter/fastmath.el"))

(defcustom fastmath-keymap-prefix "C-c C-g"
  "Fastmath keymap prefix."
  :group 'fastmath
  :type 'string)

(defcustom fastmath--ascii-to-greek-alist
  '( ;; lower-case
    ("a" "alpha")
    ("b" "beta")
    ("g" "gamma")
    ("d" "delta")
    ("e" "epsilon")
    ("z" "zeta")
    ("h" "eta")
    ("j" "theta")
    ("i" "iota")
    ("k" "kappa")
    ("l" "lambda")
    ("m" "mu")
    ("n" "nu")
    ("x" "xi")
    ("p" "pi")
    ("r" "rho")
    ("s" "sigma")
    ("t" "tau")
    ("u" "upsilon")
    ("f" "phi")
    ("q" "chi")
    ("y" "psi")
    ("w" "omega")
    ;; upper-case
    ("G" "Gamma")
    ("D" "Delta")
    ("J" "Theta")
    ("L" "Lambda")
    ("X" "Xi")
    ("P" "Pi")
    ("S" "Sigma")
    ("U" "Upsilon")
    ("F" "Phi")
    ("Y" "Psi")
    ("W" "Omega"))
  "Alist which map latin alphabet to greek alphabet."
  :group 'fastmath
  :type 'alist)

;; see https://oeis.org/wiki/List_of_LaTeX_mathematical_symbols for more
(defcustom fastmath-symbol-abbrevs
  '(
    ;; negations
    ("!;!3" "\\\\not\\\\in")
    ("!;e" "\\\\not\\\\exists")
    ("!c=" "\\\\nsubseteq")
    ("!=c" "\\\\nsupseteq")
    ("!<=" "\\\\nleq")
    ("!>=" "\\\\ngeq")
    ("!<" "\\\\nless")
    ("!>" "\\\\ngtr")
    ("!=" "\\\\neq")
    ("!;" "\\\\not")

    ;; powers
    ("62" "^{2}")
    ("63" "^{3}")

    ;; equality-like
    ("~~" "\\\\sim")
    ("==" "\\\\equiv")
    ("~=" "\\\\approx")
    ("8=" "\\\\propto")

    ;; operators
    ("\\+-" "\\\\pm")
    ("-\\+" "\\\\mp")
    (";x" "\\\\times")
    (";u" "\\\\cup")
    (";U" "\\\\cap")
    (";\\." "\\\\cdot")
    ("--" "\\\\setminus")

    ;; others
    (";0" "\\\\emptyset")
    (";v" "\\\\forall")
    (";e" "\\\\exists")
    (";e!" "\\\\exists!")
    (";3" "\\\\in")
    (";t" "\\\\top")
    (";T" "\\\\bot")
    (";d" "\\\\partial")
    (";V" "\\\\nabla")
    (";8" "\\\\infty")
    ("lll" "\\\\ell")

    ;; comparaison
    ("<=" "\\\\leq")
    (">=" "\\\\geq")

    ;; set
    (";c" "\\\\subset")
    (";C" "\\\\supset")
    ("c=" "\\\\subseteq")
    ("=c" "\\\\supseteq")

    ;; arrows
    ("\\.<=>" "\\\\iff")
    ("\\.=>" "\\\\implies")
    ("\\.<=" "\\\\impliesby")
    ("->" "\\\\to")
    ("<-" "\\\\gets")
    ("|>" "\\\\mapsto")
    ;; complex constructions
    ("dint" "\\\\int_{-\\\\infty}^{+\\\\infty}")
    )

  "Simple abbreviations replaced by fastmath."
  :group 'fastmath
  :type 'alist)

(defcustom fastmath-operators-key
  '(
    ;; builtin
    ("bm" "bm")
    ("ha" "hat")
    ("wha" "widehat")
    ("ba" "bar")
    ("wba" "overline")
    ("ve" "vec")
    ("ti" "tilde")
    ;; user-defined
    ("no" "norm"))
  "Key for operators."
  :group 'fastmath
  :type 'alist)

;; Sum-like operators
(defcustom fastmath-sumlike-key
  '(
    ;;builtin
    ("sum" "sum")
    ("prod" "prod")
    ("cup" "bigcup")
    ("cap" "bigcap")
    )
  "Key for sumlike operators."
  :group 'fastmath
  :type 'alist)

;; Inline snippets
;;
;; Fraction snippets
(defvar fastmath--fraction-multiline-snippet
  "\\frac{\n  $1\n}{\n  $2\n}$0"
  "Snippet for multiline fraction.")

(defvar fastmath--fraction-snippet
  "\\frac{$1}{$2}$0"
  "Snippet for regular fraction.")

;; Parenthesis like snippets
(defvar fastmath--brackets-lr-snippet
  "\\left[ $1 \\right]$0"
  "Snipper for left-right brackets.")

(defvar fastmath--braces-lr-snippet
  "\\left\\\\{ $1 \\right\\\\}$0"
  "Snipper for left-right braces.")

(defvar fastmath--parenthesis-lr-snippet
  "\\left( $1 \\right)$0"
  "Snippet for left-right parenthesis.")

;; TODO: MOVE IT TO INITIALIZATION OF THE MODE
(defconst fastmath--operators-key-regexp
  (mapconcat 'car fastmath-operators-key "\\|")
  "Regexp to match operators.")

(defconst fastmath--sumlike-key-regexp
  (mapconcat 'car fastmath-sumlike-key "\\|")
  "Regexp to match sumlike operators.")

(defconst fastmath--initial-delimiters
  "\\([[:space:]]\\|^\\|\\$\\|{\\|(\\|}\\|)\\)"
  "Regexp to match delimiters to stop replacement.")

(defun fastmath--convert-latin-to-greek (char)
  "Convert a latin CHAR to its equivalent in greek."
  (concat "\\\\" (car (cdr (assoc char fastmath--ascii-to-greek-alist)))))

(defun fastmath-mathfont-latex-macro (char font)
  "Construct bold/calmath for CHAR using FONT familly."
  (cond
   ((equal font "b")
    ;; (concat "\\\\mathbb{" char "}")
    (concat "\\\\" char char))
   ((equal font "c")
    (concat "\\\\mathcal{" char "}"))))

(defun fastmath--nil-or-empty-p (s)
  "Return t if S is nil or \"\"."
  (or (null s)
      (zerop (length s))))

(defun fastmath--make-sub-and-sup-script (s sub sup)
  "Transform a string S into S_{SUB}^{SUP}."
  (if (fastmath--nil-or-empty-p sub)
      (if (fastmath--nil-or-empty-p sup)
          s
        (concat s "^{" sup "}"))
    (if (fastmath--nil-or-empty-p sup)
        (concat s "_{" sub "}")
      (concat s "_{" sub "}^{" sup "}"))))

(defun fastmath--make-sumlike (key index start end)
  "Make a sumlike with KEY using INDEX from START to END."
  (let* ((opname (car (cdr (assoc key fastmath-sumlike-key))))
         (optex (concat "\\\\" opname))
         (default-start "1"))
    (if (and (fastmath--nil-or-empty-p start)
             (fastmath--nil-or-empty-p end))
        (concat optex "_{" index "}")
      (if (and (fastmath--nil-or-empty-p start)
               (not (fastmath--nil-or-empty-p end)))
          (concat optex "_{" index "=" default-start "}^{" end "}")
        (concat optex "_{" index "=" start "}^{" end "}")))))

(defun fastmath--make-integral (type start start-al end end-al)
  "Make an integral of TYPE from START (using START-AL alphabet) to END (using END-AL alphabet)."
  (let ((fstart
         (cond
          ((equal start-al 'greek)
           (fastmath--convert-latin-to-greek start))
          (t
           start)))
        (fend
         (if (and (not (fastmath--nil-or-empty-p end))
                  (equal end-al 'greek))
             (fastmath--convert-latin-to-greek end)
           end)))
    (if (fastmath--nil-or-empty-p fend)
        (concat "\\\\int_{" fstart "}")
      (concat "\\\\int_{" fstart "}^{" fend "}"))))

(defun fastmath--make-operator (key letter alphabet)
  "Make operator with KEY using LETTER (with ALPHABET)."
  (let ((opname (car (cdr (assoc key fastmath-operators-key)))))
    (if (equal alphabet 'greek)
        (concat "\\\\" opname "{" (fastmath--convert-latin-to-greek letter) "}")
      (concat "\\\\" opname "{" letter "}"))))

(defun fastmath--make-fraction (num num-al denom denom-al)
  "Make the fraction NUM over DENOM using NUM-AL and DENOM-AL alphabets."
  (let ((fnum
         (if (equal num-al 'greek)
             (fastmath--convert-latin-to-greek num)
           num))
        (fdenom
         (if (equal denom-al 'greek)
             (fastmath--convert-latin-to-greek denom)
           denom)))
    (concat "\\\\frac{" fnum "}{" fdenom "}" )))


(defun fastmath--space-back-search (before limit)
  "Search backward the expression BEFORE with LIMIT."
  (interactive)
  (re-search-backward (concat fastmath--initial-delimiters before) limit t))

(defun fastmath--expand-symbol (last-space)
  "Expand a single symbol starting from LAST-SPACE."
  (dolist (as fastmath-symbol-abbrevs)
    (let ((before (car as))
          (after (car (cdr as))))
      (when (fastmath--space-back-search before (+ 1 (- (length before))))
        (replace-match (concat "\\1" after) 'fixedcase)
        ;; TODO: for the moment I want to inser a space after expansion
        ;; Only here !!
        (insert " ")
        (throw 'expanded t)))))

(defun fastmath--expand-parenthesis (last-space)
  "Expand a \\left(\\right) starting from LAST-SPACE."
  (cond
   ((fastmath--space-back-search "lpbr" last-space)
    (replace-match "\\1")
    (yas-expand-snippet fastmath--brackets-lr-snippet)
    (throw 'expanded t))
   ((fastmath--space-back-search "lpb" last-space)
    (replace-match "\\1")
    (yas-expand-snippet fastmath--braces-lr-snippet)
    (throw 'expanded t))
   ((fastmath--space-back-search "lp" last-space)
    (replace-match "\\1")
    (yas-expand-snippet fastmath--parenthesis-lr-snippet)
    (throw 'expanded t))))

(defun fastmath--expand-fraction (last-space)
  "Expand fraction-like expression starting from LAST-SPACE."
  (cond
   ((fastmath--space-back-search "//\\([[:alnum:]]\\)\\([[:alnum:]]?\\)\\([[:alnum:]]?\\)\\([[:alnum:]]?\\)" last-space)
    (let* ((first (match-string 2))
          (second (match-string 3))
          (third (match-string 4))
          (fourth (match-string 5))
          (frac
           (cond
            ((fastmath--nil-or-empty-p second)
             (fastmath--make-fraction "1" 'latin first 'latin))
            ((fastmath--nil-or-empty-p third)
             (fastmath--make-fraction first 'latin second 'latin))
            ((fastmath--nil-or-empty-p fourth)
             (cond
              ((equal first second)
               (fastmath--make-fraction first 'greek third 'latin))
              ((equal second third)
               (fastmath--make-fraction first 'latin second 'greek))))
            (t
             (fastmath--make-fraction first 'greek third 'greek)))))
          (replace-match (concat "\\1" frac) t)
          (throw 'expanded t)))

   ;; Replace m// by snippet \frac{\n|\n}{\n|\n}
   ((fastmath--space-back-search "m//" last-space)
    (replace-match "\\1")
    (yas-expand-snippet fastmath--fraction-multiline-snippet)
    (throw 'expanded t))

   ;; Replace // by snippet \frac{|}{}
   ((fastmath--space-back-search "//" last-space)
    (replace-match "\\1")
    (yas-expand-snippet fastmath--fraction-snippet)
    (throw 'expanded t))))

(defun fastmath--expand-integral (last-space)
  "Expand integral starting from LAST-SPACE."
  (when (fastmath--space-back-search "int\\([[:alnum:]]\\)\\([[:alnum:]]?\\)" last-space)
    (let*
        ((start (match-string 2))
         (end (match-string 3))
         (integral
          (cond
           ((equal start "R")
            (fastmath--make-integral
             "int"
             (concat (fastmath-mathfont-latex-macro "R" "b")
                     (if (fastmath--nil-or-empty-p end)
                         ""
                       (concat "^{" end "}")))
             'latin nil 'latin))
           ((equal start end)
            (fastmath--make-integral "int" start 'greek nil 'latin))
           (t
            (fastmath--make-integral "int" start 'latin end 'latin)))))
      (replace-match (concat "\\1" integral) t)
      (throw 'expanded t))))

(defun fastmath--expand-sumlike (last-space)
  "Expand sum-like double operators starting from LAST-SPACE."
  (when
   (fastmath--space-back-search (concat "\\(" fastmath--sumlike-key-regexp "\\)\\([[:alpha:]]\\)\\([[:alnum:]]?\\)\\([[:alnum:]]?\\)") last-space)
   (let ((key (match-string 2))
         (index (match-string 3))
         (start-maybe (match-string 4))
         (end-maybe (match-string 5)))
     (if (and (equal end-maybe "") (not (equal start-maybe "")))
         (replace-match (concat "\\1" (fastmath--make-sumlike key index nil start-maybe)) t)
        (replace-match (concat "\\1" (fastmath--make-sumlike key index start-maybe end-maybe)) t))
      (throw 'expanded t))))

(defun fastmath--expand-double-arg-op (last-space)
  "Expand double operators starting from LAST-SPACE."
  (cond
   ;; Replace pdfx by \frac{\partial f}{\partial x}
   ((fastmath--space-back-search "pd\\([[:alpha:]]\\)\\([[:alpha:]]\\)" last-space)
    (replace-match "\\1\\\\frac{\\\\partial \\2}{\\\\partial \\3}" t)
    (throw 'expanded t))

   ;; Replace dpxy by \dotp{x}{y}
   ((fastmath--space-back-search "dp\\([[:alpha:]]\\)\\([[:alpha:]]\\)" last-space)
    (replace-match "\\1\\\\dotp{\\2}{\\3}" t)
    (throw 'expanded t))))

(defun fastmath--expand-single-arg-op (last-space)
  "Expand single operators starting from LAST-SPACE."
  (cond
   ((fastmath--space-back-search (concat "\\(" fastmath--operators-key-regexp "\\)\\([[:alpha:]]\\)\\([[:alpha:]]?\\)") last-space)
    (let* ((opname (match-string 2))
           (first (match-string 3))
           (second (match-string 4)))
      (if (not (equal second ""))
          (when (equal first second)
            (replace-match (concat "\\1" (fastmath--make-operator opname first 'greek)) t)
            (throw 'expanded t))
        (progn
          (replace-match (concat "\\1" (fastmath--make-operator opname first 'latin)) t)
          (throw 'expanded t)))))
   ))

(defun fastmath--expand-mathfont (last-space)
  "Expand fontification of symbol starting from LAST-SPACE."
  (cond
   ((fastmath--space-back-search "\\(b\\|c\\)\\([[:upper:]]\\)\\(6?\\)\\([[:alnum:]]?\\)" last-space)
    (let
        ((font (match-string 2))
         (char (match-string 3))
         (has-six (equal (match-string 4) "6"))
         (modifier (match-string 5)))
      (if has-six
          (replace-match (concat "\\1" (fastmath--make-sub-and-sup-script (fastmath-mathfont-latex-macro char font) nil modifier)) t)
        (replace-match (concat "\\1" (fastmath--make-sub-and-sup-script (fastmath-mathfont-latex-macro char font) modifier nil)) t)
        )
      )
    (throw 'expanded t))))

(defun fastmath--expand-five-chars (last-space)
  "Expand 5-chars keys starting from LAST-SPACE."
  (when (fastmath--space-back-search "\\([[:alpha:]]\\)\\([[:alpha:]]\\)\\([[:alnum:]]\\)6\\([[:alnum:]]\\)" last-space)
    (let* ((first (match-string-no-properties 2))
           (second (match-string-no-properties 3))
           (third (match-string-no-properties 4))
           (greek (fastmath--convert-latin-to-greek first)))
      (when (equal first second)
        (replace-match (concat "\\1" greek "_{\\4}^{\\5}") t)
        (throw 'expanded t)))))

(defun fastmath--expand-four-chars (last-space)
  "Expand 4-chars keys starting from LAST-SPACE."
  (when (fastmath--space-back-search "\\([[:alpha:]]\\)\\([[:alnum:]]\\)\\([[:alnum:]]\\)\\([[:alnum:]]\\)" last-space)
    (let* ((first (match-string-no-properties 2))
           (second (match-string-no-properties 3))
           (third (match-string-no-properties 4))
           (greek (fastmath--convert-latin-to-greek first)))
      (cond
       ((equal first second)
        (cond
         ((equal third "6")
          (replace-match (concat "\\1" greek "^{\\5}") t)
          (throw 'expanded t))
         (t
          (replace-match (concat "\\1" greek "_{\\4,\\5}") t)
          (throw 'expanded t))))
       ((equal third "6")
        ;; replace x6i by x^{i}
        (replace-match (concat "\\1\\2_{\\3}^{\\5}") t)
        (throw 'expanded t))
       (t
        ;; otherwise, replace x1i by x_{1,i}
        (replace-match "\\1\\2_{\\3,\\4,\\5}" t)
        (throw 'expanded t))))))

(defun fastmath--expand-three-chars (last-space)
  "Expand 3-chars keys starting from LAST-SPACE."
  (when (fastmath--space-back-search "\\([[:alpha:]]\\)\\([[:alnum:]]\\)\\([[:alnum:]]\\)" last-space)
    (let* ((first (match-string-no-properties 2))
           (second (match-string-no-properties 3))
           (greek (fastmath--convert-latin-to-greek first)))
      (cond
       ((equal first second)
        ;; Replace aa4 by \alpha_{5}
        (replace-match (concat "\\1" greek "_{\\4}") t)
        (throw 'expanded t))
       ((equal second "6")
        ;; Replace x6i by x^{i}
        (replace-match (concat "\\1\\2^{\\4}") t)
        (throw 'expanded t))
       (t
        ;; Otherwise, replace x1i by x_{1,i}
        (replace-match "\\1\\2_{\\3,\\4}" t)
        (throw 'expanded t))))))

(defun fastmath--expand-two-chars (last-space)
  "Expand 2-chars keys starting from LAST-SPACE."
  (when (fastmath--space-back-search "\\([[:alpha:]]\\)\\([[:alnum:]]\\)" last-space)
    (let* ((first (match-string-no-properties 2))
           (second (match-string-no-properties 3))
           (greek (fastmath--convert-latin-to-greek first)))
      (if (equal first second)
          ;; Replace aa by \alpha
          (progn
            (replace-match (concat "\\1" greek) t)
            (throw 'expanded t))
        ;; Otherwise, replace xi by x_{i}
        (progn
        (replace-match "\\1\\2_{\\3}" t)
        (throw 'expanded t))))))

(defun fastmath--expand-special-two-chars (last-space)
  "Expand (special) 2-chars keys starting from LAST-SPACE."
  (when (fastmath--space-back-search "fx" last-space)
    (replace-match "\\1")
    (yas-expand-snippet "$1 : $2 \\\\to $0"))
  (when (fastmath--space-back-search "d\\([[:alpha:]]\\)" last-space)
    (replace-match "\\1\\\\d \\2" t)
    (throw 'expanded t)))

(defun fastmath--expand-current-word ()
  "Expand the current word."
  (let ((case-fold-search nil)
        (data (match-data))
         (last-space
          (save-excursion
            (re-search-backward fastmath--initial-delimiters (line-beginning-position) t))))

    (unwind-protect
        (progn
          (setq yas-inhibit-overlay-modification-protection t)
            (catch 'expanded
              (fastmath--expand-symbol last-space)
              (fastmath--expand-parenthesis last-space)
              (fastmath--expand-fraction last-space)
              (fastmath--expand-integral last-space)
              (fastmath--expand-sumlike last-space)
              (fastmath--expand-double-arg-op last-space)
              (fastmath--expand-single-arg-op last-space)
              (fastmath--expand-mathfont last-space)
              (fastmath--expand-five-chars last-space)
              (fastmath--expand-four-chars last-space)
              (fastmath--expand-three-chars last-space)
              (fastmath--expand-special-two-chars last-space)
              (fastmath--expand-two-chars last-space)
              (insert " ")
              )
            (setq yas-inhibit-overlay-modification-protection nil)
            (set-match-data data)
          )
      )))

;;; Commands

;;;###autoload
(defun fastmath-space ()
  "Insert space or expand current word."
  ;; If we are not in math mode, do nothing
  (when (and (texmathp) (memq (char-before) '(?\  ?\t)))
    (delete-backward-char 1)
    (fastmath--expand-current-word)))

;;;###autoload
(defun fastmath-toggle-inline ()
  "Swap between inline math and environment."
  (interactive)
  (save-excursion
    (when (texmathp)
      (let ((begin-close '(("$" "$")
                           ("\\(" "\\)")
                           ("\\[" "\\]")
                           ("$$" "$$")))
            (spacing '(("$" 1)
                       ("\\(" 2)))
            (why (car texmathp-why))
            (where (cdr texmathp-why)))
        (cond
         ((or (equal why "$")
              (equal why "\\("))
          (goto-char where)
          (delete-char (length why))
          (push-mark)
          (search-forward (car (cdr (assoc why begin-close))))
          (delete-char (- (length why)))
          (exchange-point-and-mark)
          (LaTeX-environment nil)
          )
         ((or (equal why "\\[")
              (equal why "$$"))
          (goto-char where)
          (delete-char 2)
          (TeX-insert-dollar)
          (delete-region (point) (progn (skip-chars-forward " \t") (point)))
          (push-mark)
          (search-forward (car (cdr (assoc why begin-close))))
          (delete-char -2)
          (delete-region (point) (progn (skip-chars-backward " \t") (point)))
          (TeX-insert-dollar)
          (exchange-point-and-mark)
          )
         ((> (length (member why texmathp-environments)) 0)
          (let ((env
                 (car (member why texmathp-environments))))
            (LaTeX-find-matching-begin)
            (re-search-forward (concat "\\\\begin{" (regexp-quote env) "}[ \t\n\r]*"))
            (replace-match "$")
            (LaTeX-find-matching-end)
            (re-search-backward (concat "[ \t\n\r]*\n\\\\end{" (regexp-quote env) "}"))
            (replace-match "$"))))))))


(defvar fastmath-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-g t") 'fastmath-toggle-inline)
    map)
  "Keymap for fastmath mode after `fastmath-keymap-prefix'.")
(fset 'fastmath-command-map fastmath-command-map)

(defvar fastmath-mode-map
  (let ((map (make-sparse-keymap)))
    (when fastmath-keymap-prefix
      (define-key map fastmath-keymap-prefix 'fastmath-command-map))
    (easy-menu-define projectile-mode-menu map
      "Menu for Fastmath"
      '("Fastmath"
        ["Toggle inline" fastmath-toggle-inline]))
    map)
  "Keymap for fastmath mode.")

;;;###autoload
(define-minor-mode fastmath-mode
  "Lightning fast math mode for LaTeX.

\\{fastmath-mode-map}"
  :group 'fastmath
  :require 'fastmath
  :lighter " fm"
  :keymap fastmath-mode-map
  (make-variable-buffer-local 'post-self-insert-hook)
  (if fastmath-mode
      (add-hook 'post-self-insert-hook
                #'fastmath-space nil t)
    (remove-hook 'post-self-insert-hook
                 #'fastmath-space t)))

(provide 'fastmath)
;;; fastmath.el ends here
