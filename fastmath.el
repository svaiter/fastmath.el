;;; fastmath.el --- Lightning fast math input for LaTeX -*- lexical-binding: t -*-

;; Copyright © 2020 Samuel Vaiter <samuel.vaiter@gmail.com>

;; Author: Samuel Vaiter <samuel.vaiter@gmail.com>
;; URL: https://github.com/svaiter/fastmath.el
;; Keywords: tex, wp
;; Version: 0.2.0
;; Package-Requires: ((emacs "27.1") (auctex "12.2") (yasnippet "0.14"))

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
;; Fastmath is a minor mode for (La)TeX buffers that turns short ASCII
;; "words" typed inside math mode into LaTeX.  When `fastmath-mode' is
;; enabled and you type a space inside math (as decided by
;; `fastmath-math-predicate', by default `texmathp' from AUCTeX), the
;; word before point is examined.  If it matches one of the expansion
;; rules it is replaced by LaTeX and the space is consumed; otherwise
;; the space is inserted as usual.  Typing a second space inserts a
;; normal space.  For instance
;;
;;     int0a SPC SPC f(x) SPC dx SPC
;;
;; produces `\int_{0}^{a} f(x) \mathrm{d}x'.
;;
;; Usage:
;;
;;     (add-hook 'LaTeX-mode-hook #'fastmath-mode)
;;
;; Commands:
;;
;; - `fastmath-expand' expands the word before point right away,
;;   without typing a space.
;; - `fastmath-interrupt' makes the next space typed in math a literal
;;   space.  Inserting a space with `quoted-insert' also bypasses the
;;   expansion.
;; - `fastmath-toggle-inline' toggles the math construct around point
;;   between inline and display math.
;;
;; None of these commands is bound by default; bind them in
;; `fastmath-mode-map' as you see fit.
;;
;; Rule summary (every letter slot accepts an "atom": a latin letter, a
;; digit, a doubled latin letter standing for a greek one such as `aa'
;; for `\alpha' (see `fastmath-greek-alist') or a Unicode greek letter
;; such as `α' (see `fastmath-unicode-greek-alist')):
;;
;; - Symbol abbreviations such as `!=' -> `\neq', `->' -> `\to', `;8'
;;   -> `\infty' (see `fastmath-symbol-abbrevs').  A space is inserted
;;   after such an expansion.
;; - `lp', `lpb', `lpbr' -> `\left( \right)' and friends (snippets).
;; - `//' -> fraction snippet, `//2' -> `\frac{1}{2}', `//ab' ->
;;   `\frac{a}{b}', `m//' -> multi-line fraction snippet.
;; - `int' -> `\int', `int0a' -> `\int_{0}^{a}', `intR' ->
;;   `\int_{\mathbb{R}}'.
;; - `sumi' -> `\sum_{i}', `sumin' -> `\sum_{i=1}^{n}', `sumi3n' ->
;;   `\sum_{i=3}^{n}', and likewise for `prod', `cup', `cap' (see
;;   `fastmath-sumlike-key').
;; - `pdfx' -> `\frac{\partial f}{\partial x}', `dpxy' -> `\langle x,
;;   y \rangle' (see `fastmath-dot-product-format').
;; - `fx' -> function snippet `$1 : $2 \to $0'.
;; - `bR' -> `\mathbb{R}', `cA' -> `\mathcal{A}' (see
;;   `fastmath-mathfont-alist').
;; - `hax' -> `\hat{x}', `bay' -> `\bar{y}', `vex' -> `\vec{x}' (see
;;   `fastmath-operators-key').
;; - `dx' -> `\mathrm{d}x' (see `fastmath-differential-format').
;; - Otherwise `xi' -> `x_{i}', `xij' -> `x_{i,j}', `x6i' -> `x^{i}',
;;   `xi63' -> `x_{i}^{3}', `aa' -> `\alpha', `aai' -> `\alpha_{i}'.
;;
;; Rules are tried in this order; the first one that applies wins.  The
;; list of rules lives in `fastmath-rules'.
;;
;; Snippets are expanded with yasnippet when `yas-minor-mode' is on;
;; otherwise their text is inserted and point is left at the first
;; field.
;;
;; See the README for the complete reference and `M-x customize-group
;; RET fastmath RET' for all options.
;;

;;; Code:

(require 'easymenu)
(require 'texmathp nil t)

(declare-function texmathp "texmathp" ())
(defvar texmathp-why)
(defvar texmathp-environments)
(declare-function yas-expand-snippet "yasnippet"
                  (snippet &optional start end expand-env))
(defvar yas-minor-mode)

(defgroup fastmath nil
  "Lightning fast math input for LaTeX."
  :tag "Fast input for LaTeX Math Mode"
  :prefix "fastmath-"
  :group 'tex
  :link '(url-link :tag "GitHub" "https://github.com/svaiter/fastmath.el"))

;;;; User options

(defcustom fastmath-expand-on-space t
  "Non-nil means that typing a space inside math expands the word before it.
When nil, expansion is only available through the command
`fastmath-expand'."
  :type 'boolean
  :safe #'booleanp)

(defcustom fastmath-math-predicate #'texmathp
  "Function called with no argument to decide whether point is in math mode.
It should return non-nil when the word before point should be
expanded.  The default, `texmathp', comes with AUCTeX."
  :type 'function)

(defcustom fastmath-greek-alist
  '(;; lower-case
    ("a" . "\\alpha")
    ("b" . "\\beta")
    ("g" . "\\gamma")
    ("d" . "\\delta")
    ("e" . "\\epsilon")
    ("z" . "\\zeta")
    ("h" . "\\eta")
    ("j" . "\\theta")
    ("i" . "\\iota")
    ("k" . "\\kappa")
    ("l" . "\\lambda")
    ("m" . "\\mu")
    ("n" . "\\nu")
    ("x" . "\\xi")
    ("p" . "\\pi")
    ("r" . "\\rho")
    ("s" . "\\sigma")
    ("t" . "\\tau")
    ("u" . "\\upsilon")
    ("f" . "\\phi")
    ("q" . "\\chi")
    ("y" . "\\psi")
    ("w" . "\\omega")
    ;; upper-case
    ("G" . "\\Gamma")
    ("D" . "\\Delta")
    ("J" . "\\Theta")
    ("L" . "\\Lambda")
    ("X" . "\\Xi")
    ("P" . "\\Pi")
    ("S" . "\\Sigma")
    ("U" . "\\Upsilon")
    ("F" . "\\Phi")
    ("Y" . "\\Psi")
    ("W" . "\\Omega"))
  "Alist mapping a latin letter to the LaTeX code of a greek letter.
A doubled latin letter in a word stands for the greek letter: `aa'
is `\\alpha', `WW' is `\\Omega'.  A doubled letter without an entry
here, such as `cc', is just two latin letters."
  :type '(alist :key-type (string :tag "Latin letter")
                :value-type (string :tag "LaTeX")))

(defcustom fastmath-unicode-greek-alist
  '(;; lower-case
    ("α" . "\\alpha")
    ("β" . "\\beta")
    ("γ" . "\\gamma")
    ("δ" . "\\delta")
    ("ε" . "\\epsilon")
    ("ζ" . "\\zeta")
    ("η" . "\\eta")
    ("θ" . "\\theta")
    ("ι" . "\\iota")
    ("κ" . "\\kappa")
    ("λ" . "\\lambda")
    ("μ" . "\\mu")
    ("ν" . "\\nu")
    ("ξ" . "\\xi")
    ("ο" . "o")
    ("π" . "\\pi")
    ("ρ" . "\\rho")
    ("σ" . "\\sigma")
    ("ς" . "\\varsigma")
    ("τ" . "\\tau")
    ("υ" . "\\upsilon")
    ("φ" . "\\phi")
    ("χ" . "\\chi")
    ("ψ" . "\\psi")
    ("ω" . "\\omega")
    ;; variants
    ("ϵ" . "\\varepsilon")
    ("ϕ" . "\\varphi")
    ("ϑ" . "\\vartheta")
    ("ϱ" . "\\varrho")
    ("ϖ" . "\\varpi")
    ("ϰ" . "\\varkappa")
    ;; upper-case
    ("Α" . "A")
    ("Β" . "B")
    ("Γ" . "\\Gamma")
    ("Δ" . "\\Delta")
    ("Ε" . "E")
    ("Ζ" . "Z")
    ("Η" . "H")
    ("Θ" . "\\Theta")
    ("Ι" . "I")
    ("Κ" . "K")
    ("Λ" . "\\Lambda")
    ("Μ" . "M")
    ("Ν" . "N")
    ("Ξ" . "\\Xi")
    ("Ο" . "O")
    ("Π" . "\\Pi")
    ("Ρ" . "P")
    ("Σ" . "\\Sigma")
    ("Τ" . "T")
    ("Υ" . "\\Upsilon")
    ("Φ" . "\\Phi")
    ("Χ" . "X")
    ("Ψ" . "\\Psi")
    ("Ω" . "\\Omega"))
  "Alist mapping a Unicode greek letter to its LaTeX code.
Such a letter (typed for instance with the TeX input method) is
accepted wherever a latin letter is.  Letters that LaTeX renders
with a latin capital map to that capital."
  :type '(alist :key-type (string :tag "Greek letter")
                :value-type (string :tag "LaTeX")))

;; See https://oeis.org/wiki/List_of_LaTeX_mathematical_symbols for more.
(defcustom fastmath-symbol-abbrevs
  '(;; negations
    ("!;!3" . "\\not\\in")
    ("!;e" . "\\not\\exists")
    ("!c=" . "\\nsubseteq")
    ("!=c" . "\\nsupseteq")
    ("!<=" . "\\nleq")
    ("!>=" . "\\ngeq")
    ("!<" . "\\nless")
    ("!>" . "\\ngtr")
    ("!=" . "\\neq")
    ("!;" . "\\not")
    ;; powers
    ("62" . "^{2}")
    ("63" . "^{3}")
    ;; equality-like
    ("~~" . "\\sim")
    ("==" . "\\equiv")
    ("~=" . "\\approx")
    ("8=" . "\\propto")
    ;; operators
    ("+-" . "\\pm")
    ("-+" . "\\mp")
    (";x" . "\\times")
    (";u" . "\\cup")
    (";U" . "\\cap")
    (";." . "\\cdot")
    ("--" . "\\setminus")
    ;; others
    (";0" . "\\emptyset")
    (";v" . "\\forall")
    (";e" . "\\exists")
    (";e!" . "\\exists!")
    (";3" . "\\in")
    (";t" . "\\top")
    (";T" . "\\bot")
    (";d" . "\\partial")
    (";V" . "\\nabla")
    (";8" . "\\infty")
    ("lll" . "\\ell")
    ;; comparison
    ("<=" . "\\leq")
    (">=" . "\\geq")
    ;; sets
    (";c" . "\\subset")
    (";C" . "\\supset")
    ("c=" . "\\subseteq")
    ("=c" . "\\supseteq")
    ;; arrows
    (".<=>" . "\\iff")
    (".=>" . "\\implies")
    (".<=" . "\\impliedby")
    ("->" . "\\to")
    ("<-" . "\\gets")
    ("|>" . "\\mapsto")
    ;; complex constructions
    ("dint" . "\\int_{-\\infty}^{+\\infty}")
    ;; Unicode symbols, typed with an input method
    ("∞" . "\\infty")
    ("∂" . "\\partial")
    ("∇" . "\\nabla")
    ("∈" . "\\in")
    ("∉" . "\\notin")
    ("≤" . "\\leq")
    ("≥" . "\\geq")
    ("≠" . "\\neq")
    ("→" . "\\to")
    ("∀" . "\\forall")
    ("∃" . "\\exists")
    ("∅" . "\\emptyset")
    ("⊂" . "\\subset")
    ("⊆" . "\\subseteq")
    ("∪" . "\\cup")
    ("∩" . "\\cap")
    ("×" . "\\times")
    ("±" . "\\pm"))
  "Alist of symbol abbreviations.
Each element is (KEY . LATEX): typing the literal text KEY followed
by a space inserts LATEX followed by a space.  Both strings are
literal text, not regexps."
  :type '(alist :key-type (string :tag "Key")
                :value-type (string :tag "LaTeX")))

(defcustom fastmath-operators-key
  '(("bm" . "bm")
    ("ha" . "hat")
    ("wha" . "widehat")
    ("ba" . "bar")
    ("wba" . "overline")
    ("ve" . "vec")
    ("ti" . "tilde"))
  "Alist mapping a key to the name of a single-argument LaTeX macro.
Typing KEY followed by an atom gives `\\MACRO{atom}': `hax' gives
`\\hat{x}'.  Subscripts and superscripts may follow the atom:
`haxi' gives `\\hat{x}_{i}'.  When several keys could match, the
longest one wins."
  :type '(alist :key-type (string :tag "Key")
                :value-type (string :tag "Macro name")))

(defcustom fastmath-sumlike-key
  '(("sum" . "sum")
    ("prod" . "prod")
    ("cup" . "bigcup")
    ("cap" . "bigcap"))
  "Alist mapping a key to the name of a sum-like LaTeX macro.
Typing KEY alone gives `\\MACRO'; KEY followed by an index gives
`\\MACRO_{index}'; KEY, index and end give `\\MACRO_{index=1}^{end}';
KEY, index, start and end give `\\MACRO_{index=start}^{end}'."
  :type '(alist :key-type (string :tag "Key")
                :value-type (string :tag "Macro name")))

(defcustom fastmath-mathfont-alist
  '(("b" . "\\mathbb{%s}")
    ("c" . "\\mathcal{%s}"))
  "Alist mapping a prefix to a math font.
Typing PREFIX followed by an upper-case letter gives the letter in
that font: `bR' gives `\\mathbb{R}'.  The value is either a format
string, given the letter twice as arguments of `format' (so that
\"\\\\%s%s\" turns `bR' into `\\RR'), or a function called with the
letter as a string and returning the LaTeX code."
  :type '(alist :key-type (string :tag "Prefix")
                :value-type (choice (string :tag "Format string")
                                    (function :tag "Function"))))

(defcustom fastmath-differential-format "\\mathrm{d}%s"
  "Format string producing the differential of a variable.
It receives the variable as the only argument of `format'.  Users
of a custom macro may prefer \"\\\\d %s\"."
  :type 'string
  :safe #'stringp)

(defcustom fastmath-dot-product-format "\\langle %s, %s \\rangle"
  "Format string producing the dot product of two variables.
It receives the two variables as arguments of `format'.  Users of
a custom macro may prefer \"\\\\dotp{%s}{%s}\"."
  :type 'string
  :safe #'stringp)

(defcustom fastmath-display-math-style 'brackets
  "How `fastmath-toggle-inline' writes display math.
The symbol `brackets' means `\\[ ... \\]'; a string names an
environment, for instance \"equation\"."
  :type '(choice (const :tag "\\[ ... \\]" brackets)
                 (string :tag "Environment name")))

(defcustom fastmath-inline-math-style 'dollars
  "How `fastmath-toggle-inline' writes inline math.
The symbol `dollars' means `$...$', the symbol `parens' means
`\\( ... \\)'."
  :type '(choice (const :tag "$ ... $" dollars)
                 (const :tag "\\( ... \\)" parens)))

(defcustom fastmath-fraction-snippet "\\frac{$1}{$2}$0"
  "Snippet inserted by `//'."
  :type 'string)

(defcustom fastmath-fraction-multiline-snippet
  "\\frac{\n  $1\n}{\n  $2\n}$0"
  "Snippet inserted by `m//'."
  :type 'string)

(defcustom fastmath-parenthesis-snippet "\\left( $1 \\right)$0"
  "Snippet inserted by `lp'."
  :type 'string)

(defcustom fastmath-braces-snippet "\\left\\\\{ $1 \\right\\\\}$0"
  "Snippet inserted by `lpb'.
Note that a backslash must be doubled, as in any yasnippet snippet."
  :type 'string)

(defcustom fastmath-brackets-snippet "\\left[ $1 \\right]$0"
  "Snippet inserted by `lpbr'."
  :type 'string)

(defcustom fastmath-function-snippet "$1 : $2 \\to $0"
  "Snippet inserted by `fx'."
  :type 'string)

;;;; Cached regexps

(defvar fastmath--regexp-cache nil
  "Alist caching the regexps built from user options.
Each element is (KEY SOURCE . REGEXP), where SOURCE is the value
the regexp was built from.  The regexp is rebuilt whenever SOURCE
is no longer `equal' to the current value, so that changing an
option (with `setq', `let' or Customize) takes effect at once.")

(defun fastmath--cached-regexp (key source builder)
  "Return the regexp cached under KEY, rebuilding it if SOURCE changed.
SOURCE is the Lisp value the regexp depends on; BUILDER is a
function called with SOURCE that returns the regexp."
  (let ((entry (assq key fastmath--regexp-cache)))
    (if (and entry (equal (cadr entry) source))
        (cddr entry)
      (let ((regexp (funcall builder source)))
        (setq fastmath--regexp-cache
              (cons (cons key (cons source regexp))
                    (assq-delete-all key fastmath--regexp-cache)))
        regexp))))

(defconst fastmath--delimiter-regexp
  "\\(?:^\\|[][[:space:]$(){}=+,^_&|-]\\)"
  "Regexp matching what may precede a word to expand.
A word starts after whitespace, at the beginning of the line or
after one of the characters `$ { } ( ) [ ] = + - , ^ _ & |'.")

(defun fastmath--atom-regexp ()
  "Return a regexp matching one character that can be part of an atom."
  (fastmath--cached-regexp
   'atom fastmath-unicode-greek-alist
   (lambda (alist)
     ;; Greek letters need no escaping inside a bracket expression.
     (concat "[a-zA-Z0-9" (mapconcat #'car alist "") "]"))))

(defun fastmath--word-regexp ()
  "Return a regexp matching a word made of atoms."
  (concat (fastmath--atom-regexp) "+"))

(defun fastmath--keys-regexp (key alist)
  "Return a regexp matching any key of ALIST, cached under KEY."
  (fastmath--cached-regexp
   key alist
   (lambda (table) (regexp-opt (mapcar #'car table)))))

(defun fastmath--symbol-regexp ()
  "Return a regexp matching a key of `fastmath-symbol-abbrevs'."
  (fastmath--keys-regexp 'symbol fastmath-symbol-abbrevs))

(defun fastmath--fraction-regexp ()
  "Return a regexp matching a fraction word."
  (concat "m?//" (fastmath--atom-regexp) "*"))

(defun fastmath--integral-regexp ()
  "Return a regexp matching an integral word."
  (concat "int" (fastmath--atom-regexp) "*"))

(defun fastmath--sumlike-regexp ()
  "Return a regexp matching a sum-like word."
  (concat (fastmath--keys-regexp 'sumlike fastmath-sumlike-key)
          (fastmath--atom-regexp) "*"))

(defun fastmath--double-arg-regexp ()
  "Return a regexp matching a partial derivative or dot product word."
  (concat "\\(?:pd\\|dp\\)" (fastmath--atom-regexp) "*"))

(defun fastmath--mathfont-regexp ()
  "Return a regexp matching a math font word."
  (concat (fastmath--keys-regexp 'mathfont fastmath-mathfont-alist)
          "[A-Z]" (fastmath--atom-regexp) "*"))

(defun fastmath--operator-regexp ()
  "Return a regexp matching a single-argument operator word."
  (concat (fastmath--keys-regexp 'operator fastmath-operators-key)
          (fastmath--atom-regexp) "+"))

(defun fastmath--differential-regexp ()
  "Return a regexp matching a differential word."
  (concat "d" (fastmath--atom-regexp) "+"))

;;;; Atoms

(defun fastmath--latin-char-p (char)
  "Return non-nil if CHAR is an ASCII letter."
  (or (<= ?a char ?z) (<= ?A char ?Z)))

(defun fastmath--tokenize (word)
  "Split WORD into a list of atoms.
Each atom is a cons (LATEX . KIND) where KIND is `latin', `digit'
or `greek'.  Tokenization is greedy from left to right: a latin
letter immediately repeated is a greek atom when the letter has an
entry in `fastmath-greek-alist', otherwise each letter is a latin
atom.  A Unicode letter from `fastmath-unicode-greek-alist' is a
greek atom, or a latin one when it maps to a latin capital.  Return
nil if WORD is empty or contains anything else."
  (let ((i 0)
        (n (length word))
        (atoms nil)
        (valid t))
    (while (and valid (< i n))
      (let* ((char (aref word i))
             (string (string char))
             (greek (and (fastmath--latin-char-p char)
                         (cdr (assoc string fastmath-greek-alist))))
             (unicode (cdr (assoc string fastmath-unicode-greek-alist))))
        (cond
         ((and greek (< (1+ i) n) (eq (aref word (1+ i)) char))
          (push (cons greek 'greek) atoms)
          (setq i (+ i 2)))
         ((fastmath--latin-char-p char)
          (push (cons string 'latin) atoms)
          (setq i (1+ i)))
         ((<= ?0 char ?9)
          (push (cons string 'digit) atoms)
          (setq i (1+ i)))
         (unicode
          (push (cons unicode (if (string-prefix-p "\\" unicode) 'greek 'latin))
                atoms)
          (setq i (1+ i)))
         (t (setq valid nil)))))
    (and valid atoms (nreverse atoms))))

(defun fastmath--letter-atom-p (atom)
  "Return non-nil if ATOM is a latin or greek letter."
  (memq (cdr atom) '(latin greek)))

(defun fastmath--join-atoms (atoms)
  "Return the LaTeX code of ATOMS separated by commas."
  (mapconcat #'car atoms ","))

(defun fastmath--parse-modifiers (string)
  "Parse STRING as subscript atoms, optionally followed by `6' and superscripts.
Return a list (SUBS SUPS) of two lists of atoms, or nil when
STRING is not well formed.  A trailing `6' with nothing after it
is an ordinary subscript."
  (when (string-match "\\`\\(.*?\\)\\(?:6\\(.+\\)\\)?\\'" string)
    (let* ((base (match-string 1 string))
           (sup (match-string 2 string))
           (subs (and (not (equal base "")) (fastmath--tokenize base)))
           (sups (and sup (fastmath--tokenize sup))))
      (unless (or (and (not (equal base "")) (null subs))
                  (and sup (null sups)))
        (list subs sups)))))

(defun fastmath--split-key (word keys)
  "Split WORD into (KEY . REST) where KEY is the longest prefix found in KEYS.
Return nil if no key of KEYS is a prefix of WORD."
  (let ((best nil))
    (dolist (key keys)
      (when (and (string-prefix-p key word)
                 (> (length key) (length best)))
        (setq best key)))
    (and best (cons best (substring word (length best))))))

;;;; LaTeX builders

(defun fastmath--nil-or-empty-p (s)
  "Return t if S is nil or \"\"."
  (or (null s) (zerop (length s))))

(defun fastmath--make-sub-and-sup-script (s sub sup)
  "Return the LaTeX code S_{SUB}^{SUP}, omitting empty or nil parts."
  (concat s
          (if (fastmath--nil-or-empty-p sub) "" (concat "_{" sub "}"))
          (if (fastmath--nil-or-empty-p sup) "" (concat "^{" sup "}"))))

(defun fastmath--make-fraction (num denom)
  "Return the LaTeX code of the fraction NUM over DENOM."
  (concat "\\frac{" num "}{" denom "}"))

(defun fastmath--make-integral (lower &optional upper)
  "Return the LaTeX code of an integral from LOWER to UPPER."
  (fastmath--make-sub-and-sup-script "\\int" lower upper))

(defun fastmath--make-sumlike (name index &optional start end)
  "Return the LaTeX code of the sum-like macro NAME over INDEX.
With END, the index runs from START (1 if nil) to END."
  (let ((macro (concat "\\" name)))
    (cond
     ((fastmath--nil-or-empty-p end)
      (fastmath--make-sub-and-sup-script macro index nil))
     (t
      (fastmath--make-sub-and-sup-script
       macro (concat index "=" (if (fastmath--nil-or-empty-p start) "1" start))
       end)))))

(defun fastmath--make-operator (name arg)
  "Return the LaTeX code of the single-argument macro NAME applied to ARG."
  (concat "\\" name "{" arg "}"))

(defun fastmath--make-mathfont (key letter)
  "Return the LaTeX code of LETTER in the math font of KEY.
KEY is looked up in `fastmath-mathfont-alist'."
  (let ((spec (cdr (assoc key fastmath-mathfont-alist))))
    (cond
     ((functionp spec) (funcall spec letter))
     ((stringp spec) (format spec letter letter))
     (t (error "No math font for prefix %S" key)))))

(defun fastmath--make-differential (var)
  "Return the LaTeX code of the differential of VAR."
  (format fastmath-differential-format var))

(defun fastmath--make-partial (fun var)
  "Return the LaTeX code of the partial derivative of FUN with respect to VAR."
  (format "\\frac{\\partial %s}{\\partial %s}" fun var))

(defun fastmath--make-dot-product (a b)
  "Return the LaTeX code of the dot product of A and B."
  (format fastmath-dot-product-format a b))

;;;; Rules
;;
;; A rule handler receives the matched word and returns a string of
;; LaTeX code, a cons (snippet . SNIPPET) to be expanded as a yasnippet
;; snippet, or nil to decline.  Handlers never touch the buffer, so
;; they can be tested on their own.

(defun fastmath--rule-symbol (word)
  "Expand the symbol abbreviation WORD, followed by a space."
  (let ((latex (cdr (assoc word fastmath-symbol-abbrevs))))
    (and latex (concat latex " "))))

(defun fastmath--rule-parenthesis (word)
  "Expand the parenthesis-like snippet WORD."
  (pcase word
    ("lp" (cons 'snippet fastmath-parenthesis-snippet))
    ("lpb" (cons 'snippet fastmath-braces-snippet))
    ("lpbr" (cons 'snippet fastmath-brackets-snippet))))

(defun fastmath--rule-fraction (word)
  "Expand the fraction WORD.
`//' and `m//' give snippets, `//' followed by one atom gives its
inverse and `//' followed by two atoms gives their quotient."
  (if (string-prefix-p "m" word)
      (and (equal word "m//")
           (cons 'snippet fastmath-fraction-multiline-snippet))
    (let ((rest (substring word 2)))
      (if (equal rest "")
          (cons 'snippet fastmath-fraction-snippet)
        (pcase (fastmath--tokenize rest)
          (`(,denom) (fastmath--make-fraction "1" (car denom)))
          (`(,num ,denom) (fastmath--make-fraction (car num) (car denom))))))))

(defun fastmath--rule-integral (word)
  "Expand the integral WORD.
`int' alone gives `\\int'; one atom gives the lower bound and a
second one the upper bound.  A lower bound `R' is the blackboard
bold R, and the following atom is its exponent."
  (let ((rest (substring word 3)))
    (if (equal rest "")
        (fastmath--make-integral nil)
      (pcase (fastmath--tokenize rest)
        (`(("R" . latin)) (fastmath--make-integral (fastmath--make-mathfont "b" "R")))
        (`(("R" . latin) ,exp)
         (fastmath--make-integral
          (fastmath--make-sub-and-sup-script (fastmath--make-mathfont "b" "R")
                                             nil (car exp))))
        (`(,lower) (fastmath--make-integral (car lower)))
        (`(,lower ,upper) (fastmath--make-integral (car lower) (car upper)))))))

(defun fastmath--rule-sumlike (word)
  "Expand the sum-like WORD, see `fastmath-sumlike-key'."
  (pcase (fastmath--split-key word (mapcar #'car fastmath-sumlike-key))
    (`(,key . ,rest)
     (let ((name (cdr (assoc key fastmath-sumlike-key))))
       (if (equal rest "")
           (fastmath--make-sumlike name nil)
         (pcase (fastmath--tokenize rest)
           ((and `(,index . ,bounds) (guard (fastmath--letter-atom-p index)))
            (pcase bounds
              ('nil (fastmath--make-sumlike name (car index)))
              (`(,end) (fastmath--make-sumlike name (car index) nil (car end)))
              (`(,start ,end)
               (fastmath--make-sumlike name (car index) (car start) (car end)))))))))))

(defun fastmath--rule-double-arg (word)
  "Expand the partial derivative (`pd') or dot product (`dp') WORD."
  (pcase (fastmath--tokenize (substring word 2))
    ((and `(,a ,b)
          (guard (and (fastmath--letter-atom-p a) (fastmath--letter-atom-p b))))
     (if (string-prefix-p "pd" word)
         (fastmath--make-partial (car a) (car b))
       (fastmath--make-dot-product (car a) (car b))))))

(defun fastmath--rule-function (word)
  "Expand the function snippet WORD."
  (and (equal word "fx") (cons 'snippet fastmath-function-snippet)))

(defun fastmath--rule-mathfont (word)
  "Expand the math font WORD, see `fastmath-mathfont-alist'."
  (pcase (fastmath--split-key word (mapcar #'car fastmath-mathfont-alist))
    ((and `(,key . ,rest) (guard (and (> (length rest) 0)
                                      (<= ?A (aref rest 0) ?Z))))
     (pcase (fastmath--parse-modifiers (substring rest 1))
       (`(,subs ,sups)
        (fastmath--make-sub-and-sup-script
         (fastmath--make-mathfont key (substring rest 0 1))
         (fastmath--join-atoms subs)
         (fastmath--join-atoms sups)))))))

(defun fastmath--rule-operator (word)
  "Expand the single-argument operator WORD, see `fastmath-operators-key'."
  (pcase (fastmath--split-key word (mapcar #'car fastmath-operators-key))
    (`(,key . ,rest)
     (pcase (fastmath--parse-modifiers rest)
       ((and `((,arg . ,subs) ,sups) (guard (fastmath--letter-atom-p arg)))
        (fastmath--make-sub-and-sup-script
         (fastmath--make-operator (cdr (assoc key fastmath-operators-key))
                                  (car arg))
         (fastmath--join-atoms subs)
         (fastmath--join-atoms sups)))))))

(defun fastmath--rule-differential (word)
  "Expand the differential WORD, `d' followed by one letter atom.
The whole word is tokenized first, so that `dd' is the greek
letter delta rather than a differential."
  (pcase (fastmath--tokenize word)
    ((and `(("d" . latin) ,var) (guard (fastmath--letter-atom-p var)))
     (fastmath--make-differential (car var)))))

(defun fastmath--rule-head (word)
  "Expand WORD as a head atom with subscripts and superscripts.
The head must be a letter; a single latin letter is left alone."
  (pcase (fastmath--parse-modifiers word)
    ((and `((,head . ,subs) ,sups)
          (guard (and (fastmath--letter-atom-p head)
                      (or subs sups (eq (cdr head) 'greek)))))
     (fastmath--make-sub-and-sup-script (car head)
                                        (fastmath--join-atoms subs)
                                        (fastmath--join-atoms sups)))))

(defvar fastmath-rules
  '((fastmath--symbol-regexp . fastmath--rule-symbol)
    ("lpbr\\|lpb\\|lp" . fastmath--rule-parenthesis)
    (fastmath--fraction-regexp . fastmath--rule-fraction)
    (fastmath--integral-regexp . fastmath--rule-integral)
    (fastmath--sumlike-regexp . fastmath--rule-sumlike)
    (fastmath--double-arg-regexp . fastmath--rule-double-arg)
    ("fx" . fastmath--rule-function)
    (fastmath--mathfont-regexp . fastmath--rule-mathfont)
    (fastmath--operator-regexp . fastmath--rule-operator)
    (fastmath--differential-regexp . fastmath--rule-differential)
    (fastmath--word-regexp . fastmath--rule-head))
  "Ordered list of expansion rules, each of the form (REGEXP . HANDLER).
REGEXP is a regexp, or a function of no argument returning one,
matching a candidate word.  It is anchored at both ends by the
dispatcher: the word must follow a delimiter (see
`fastmath--delimiter-regexp') and end at point.  HANDLER is called
with the matched word and returns the LaTeX code replacing it as a
string, a cons (snippet . SNIPPET) to expand a yasnippet snippet,
or nil to let the following rules try.")

;;;; Expansion

(defun fastmath--rule-regexp (regexp)
  "Return the anchored buffer regexp for the rule regexp REGEXP.
REGEXP is a string or a function returning one.  The word is the
first group of the result."
  (concat fastmath--delimiter-regexp
          "\\(" (if (functionp regexp) (funcall regexp) regexp) "\\)"))

(defun fastmath--insert-plain-snippet (snippet)
  "Insert SNIPPET without yasnippet.
Fields are replaced by their default text, if any, and point is
left at the first field (or at `$0' when there is none).  Escaped
characters are unescaped as yasnippet would."
  (let ((start (point))
        (i 0)
        (text "")
        (first nil)
        (exit nil))
    (while (string-match
            "\\\\\\(.\\)\\|\\$\\(?:\\([0-9]+\\)\\|{\\([0-9]+\\)\\(?::\\([^}]*\\)\\)?}\\)"
            snippet i)
      (setq text (concat text (substring snippet i (match-beginning 0))))
      (let ((escaped (match-string 1 snippet))
            (field (or (match-string 2 snippet) (match-string 3 snippet)))
            (default (or (match-string 4 snippet) "")))
        (cond
         (escaped
          (setq text (concat text
                             (if (string-match-p "[]\\\\`\"'$}{()[]" escaped) "" "\\")
                             escaped)))
         ((equal field "0") (unless exit (setq exit (length text))))
         ((equal field "1") (unless first (setq first (length text)))))
        (unless escaped (setq text (concat text default))))
      (setq i (match-end 0)))
    (insert text (substring snippet i))
    (goto-char (+ start (or first exit (- (point) start))))))

(defun fastmath--insert-snippet (snippet)
  "Insert SNIPPET at point.
Use yasnippet when `yas-minor-mode' is enabled, otherwise insert
the plain text and leave point at the first field."
  (if (and (bound-and-true-p yas-minor-mode) (fboundp 'yas-expand-snippet))
      (yas-expand-snippet snippet)
    (fastmath--insert-plain-snippet snippet)))

(defun fastmath--insert-result (result)
  "Insert the RESULT of a rule handler at point."
  (pcase result
    ((pred stringp) (insert result))
    (`(snippet . ,(and snippet (pred stringp))) (fastmath--insert-snippet snippet))
    (_ (error "Invalid fastmath rule result %S" result))))

(defun fastmath--expand-before-point ()
  "Expand the word before point using `fastmath-rules'.
Return non-nil if the word was expanded."
  (let ((case-fold-search nil)
        (limit (line-beginning-position))
        (rules fastmath-rules)
        (result nil)
        (start nil))
    (save-match-data
      (while (and rules (not result))
        (let ((rule (pop rules)))
          (when (looking-back (fastmath--rule-regexp (car rule)) limit)
            ;; Handlers may run `string-match', so read the match data first.
            (let ((word (match-string-no-properties 1))
                  (beg (match-beginning 1)))
              (setq result (funcall (cdr rule) word))
              (when result
                (setq start beg)))))))
    (when result
      (delete-region start (point))
      (fastmath--insert-result result)
      t)))

;;;; Commands

(defvar-local fastmath--interrupted nil
  "Non-nil means that the next space typed in math is inserted literally.
Set by `fastmath-interrupt' and cleared by that space.")

(defun fastmath-space ()
  "Expand the word before point after a space has been typed in math mode.
This function is meant for `post-self-insert-hook'.  It does
nothing unless the character just typed is a space, and point is
in math according to `fastmath-math-predicate'.  When a rule
applies, the word is replaced and the space is consumed.  Errors
are reported as messages and leave the typed text as it was."
  (when (and fastmath-expand-on-space
             (eq last-command-event ?\s)
             (eq (char-before) ?\s))
    (condition-case err
        (when (funcall fastmath-math-predicate)
          (if fastmath--interrupted
              (setq fastmath--interrupted nil)
            (atomic-change-group
              (delete-char -1)
              (unless (fastmath--expand-before-point)
                (insert " ")))))
      (error (message "fastmath: %s" (error-message-string err))))))

;;;###autoload
(defun fastmath-expand ()
  "Expand the word before point according to `fastmath-rules'.
Unlike typing a space, this command does not check
`fastmath-math-predicate' nor `fastmath-expand-on-space'."
  (interactive "*")
  (unless (atomic-change-group (fastmath--expand-before-point))
    (user-error "Nothing to expand before point")))

;;;###autoload
(defun fastmath-interrupt ()
  "Insert the next space typed in math literally instead of expanding.
The effect lasts for one space only.  Inserting the space with
`quoted-insert' (\\[quoted-insert]) is another way to bypass the
expansion."
  (interactive)
  (setq fastmath--interrupted t)
  (message "fastmath: the next space is inserted literally"))

(defun fastmath--escaped-p (pos)
  "Return non-nil if the character at POS is preceded by an odd number of \\."
  (save-excursion
    (goto-char pos)
    (let ((count (skip-chars-backward "\\\\")))
      (= (mod count 2) 1))))

(defun fastmath--find-closing (close start)
  "Return the position of the first unescaped CLOSE after START, or nil."
  (save-excursion
    (goto-char start)
    (let ((found nil))
      (while (and (not found) (search-forward close nil t))
        (unless (fastmath--escaped-p (match-beginning 0))
          (setq found (match-beginning 0))))
      found)))

(defun fastmath--rewrap-math (open-beg open close new-open new-close)
  "Replace the delimiters OPEN (at OPEN-BEG) and CLOSE by NEW-OPEN and NEW-CLOSE.
The surrounding whitespace of the content is trimmed and point is
kept at the same place inside the content."
  (let* ((content-beg (+ open-beg (length open)))
         (close-beg (or (fastmath--find-closing close content-beg)
                        (user-error "Cannot find the end of this math")))
         (content (buffer-substring content-beg close-beg))
         (leading (or (string-match-p "[^ \t\n]" content) (length content)))
         (trimmed (replace-regexp-in-string "\\`[ \t\n]+\\|[ \t\n]+\\'" "" content))
         (offset (max 0 (min (length trimmed) (- (point) content-beg leading)))))
    (delete-region open-beg (+ close-beg (length close)))
    (goto-char open-beg)
    (insert new-open trimmed new-close)
    (goto-char (+ open-beg (length new-open) offset))))

;;;###autoload
(defun fastmath-toggle-inline ()
  "Toggle the math around point between inline and display math.
Inline math (`$...$' or `\\(...\\)') becomes display math as set
by `fastmath-display-math-style'.  Display math (`\\[...\\]',
`$$...$$' or a math environment) becomes inline math as set by
`fastmath-inline-math-style'."
  (interactive "*")
  (unless (and (fboundp 'texmathp) (texmathp))
    (user-error "Not inside math"))
  (let* ((why (car texmathp-why))
         (pos (cdr texmathp-why))
         (display-open (if (stringp fastmath-display-math-style)
                           (format "\\begin{%s}\n" fastmath-display-math-style)
                         "\\[ "))
         (display-close (if (stringp fastmath-display-math-style)
                            (format "\n\\end{%s}" fastmath-display-math-style)
                          " \\]"))
         (inline-open (if (eq fastmath-inline-math-style 'parens) "\\(" "$"))
         (inline-close (if (eq fastmath-inline-math-style 'parens) "\\)" "$")))
    (cond
     ((equal why "$")
      (fastmath--rewrap-math pos "$" "$" display-open display-close))
     ((equal why "\\(")
      (fastmath--rewrap-math pos "\\(" "\\)" display-open display-close))
     ((equal why "$$")
      (fastmath--rewrap-math pos "$$" "$$" inline-open inline-close))
     ((equal why "\\[")
      (fastmath--rewrap-math pos "\\[" "\\]" inline-open inline-close))
     ((and (stringp why) (member why texmathp-environments))
      (fastmath--rewrap-math pos (format "\\begin{%s}" why) (format "\\end{%s}" why)
                             inline-open inline-close))
     (t (user-error "Cannot toggle math introduced by %s" why)))))

;;;; Minor mode

(defvar fastmath-mode-map
  (let ((map (make-sparse-keymap)))
    (easy-menu-define fastmath-mode-menu map
      "Menu for Fastmath mode."
      '("Fastmath"
        ["Expand word before point" fastmath-expand]
        ["Insert next space literally" fastmath-interrupt]
        ["Toggle inline/display math" fastmath-toggle-inline]
        "--"
        ["Expand on space"
         (setq fastmath-expand-on-space (not fastmath-expand-on-space))
         :style toggle :selected fastmath-expand-on-space]))
    map)
  "Keymap for `fastmath-mode'.
No key is bound by default.")

;;;###autoload
(define-minor-mode fastmath-mode
  "Toggle Fastmath mode, lightning fast math input for LaTeX.
When enabled, typing a space inside math expands the word before
point according to `fastmath-rules'; see the Commentary of
fastmath.el for a summary.

\\{fastmath-mode-map}"
  :lighter " fm"
  :keymap fastmath-mode-map
  (if fastmath-mode
      (progn
        (unless (functionp fastmath-math-predicate)
          (display-warning
           'fastmath
           (format-message "`fastmath-math-predicate' (%S) is not a function"
                           fastmath-math-predicate)))
        (add-hook 'post-self-insert-hook #'fastmath-space nil t))
    (remove-hook 'post-self-insert-hook #'fastmath-space t)
    (setq fastmath--interrupted nil)))

(provide 'fastmath)
;;; fastmath.el ends here
