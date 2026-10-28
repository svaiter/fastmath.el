;;; fastmath-integration-test.el --- Integration tests for fastmath -*- lexical-binding: t -*-

;; Copyright © 2020 Samuel Vaiter <samuel.vaiter@gmail.com>

;; Author: Samuel Vaiter <samuel.vaiter@gmail.com>
;; URL: https://github.com/svaiter/fastmath.el
;; Keywords: tex, wp

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
;; End-to-end tests: words are typed with `execute-kbd-macro' in a
;; LaTeX buffer with `fastmath-mode' enabled.  See test-helper.el.
;;

;;; Code:

(require 'ert)
(require 'fastmath)

;;;; Greek letters

(ert-deftest fm-test-greek-alphabet ()
  (fm-test-simple-insertion "aa" "\\alpha")
  (fm-test-simple-insertion "WW" "\\Omega")
  (fm-test-simple-insertion "dd" "\\delta")
  (fm-test-simple-insertion "xx" "\\xi")
  (fm-test-simple-insertion "xxi" "\\xi_{i}"))

(ert-deftest fm-test-greek-unicode ()
  (fm-test-simple-insertion "α" "\\alpha")
  (fm-test-simple-insertion "Ω" "\\Omega")
  (fm-test-simple-insertion "xα" "x_{\\alpha}")
  (fm-test-simple-insertion "αi" "\\alpha_{i}")
  (fm-test-simple-insertion "ϵ6j" "\\varepsilon^{j}")
  (fm-test-simple-insertion "Αi" "A_{i}")
  (fm-test-simple-insertion "haα" "\\hat{\\alpha}")
  (fm-test-simple-insertion "dα" "\\mathrm{d}\\alpha")
  (fm-test-simple-insertion "intα" "\\int_{\\alpha}")
  (fm-test-simple-insertion "//αβ" "\\frac{\\alpha}{\\beta}"))

(ert-deftest fm-test-doubled-letter-without-greek ()
  (fm-test-simple-insertion "cc" "c_{c}")
  (fm-test-simple-insertion "oo" "o_{o}")
  (fm-test-simple-insertion "AA" "A_{A}"))

;;;; Symbols

(ert-deftest fm-test-symbol-abbrevs ()
  ;; A space is inserted after a symbol...
  (fm-test-simple-insertion "!=" "\\neq ")
  (fm-test-simple-insertion "<=" "\\leq ")
  (fm-test-simple-insertion "->" "\\to ")
  (fm-test-simple-insertion "c=" "\\subseteq ")
  (fm-test-simple-insertion "=c" "\\supseteq ")
  (fm-test-simple-insertion "--" "\\setminus ")
  (fm-test-simple-insertion "+-" "\\pm ")
  ;; `|' is the point marker of the helper, so type it.
  (fm-test-with-temp-buffer "$ | $" nil
    (execute-kbd-macro (kbd "| > SPC"))
    (fm-buffer-equals "$ \\mapsto | $"))
  (fm-test-simple-insertion "!;!3" "\\not\\in ")
  (fm-test-simple-insertion ".<=" "\\impliedby ")
  (fm-test-simple-insertion ".<=>" "\\iff ")
  (fm-test-simple-insertion "62" "^{2} ")
  (fm-test-simple-insertion "lll" "\\ell ")
  (fm-test-simple-insertion "dint" "\\int_{-\\infty}^{+\\infty} ")
  ;; ...but not after a word.
  (fm-test-simple-insertion "aa" "\\alpha")
  (fm-test-simple-insertion "xi" "x_{i}"))

(ert-deftest fm-test-symbol-unicode ()
  (fm-test-simple-insertion "∞" "\\infty ")
  (fm-test-simple-insertion "∂" "\\partial ")
  (fm-test-simple-insertion "∈" "\\in ")
  (fm-test-simple-insertion "≤" "\\leq ")
  (fm-test-simple-insertion "→" "\\to ")
  (fm-test-simple-insertion "±" "\\pm "))

;;;; Delimiters and anchoring

(ert-deftest fm-test-extended-delimiters ()
  (fm-test-simple-insertion "x=aa" "x=\\alpha")
  (fm-test-simple-insertion "x_aa" "x_\\alpha")
  (fm-test-simple-insertion "x^aa" "x^\\alpha")
  (fm-test-simple-insertion "x+aa" "x+\\alpha")
  (fm-test-simple-insertion "x-xi" "x-x_{i}")
  (fm-test-simple-insertion "[aa" "[\\alpha")
  (fm-test-simple-insertion "f(xi" "f(x_{i}")
  (fm-test-simple-insertion "{bR" "{\\mathbb{R}")
  (fm-test-simple-insertion "x,aa" "x,\\alpha")
  (fm-test-simple-insertion "a&bb" "a&\\beta")
  (fm-test-with-temp-buffer "$ | $" nil
    (execute-kbd-macro (kbd "| a a SPC"))
    ;; `|' cannot appear in `fm-buffer-equals' expectations.
    (should (equal (buffer-string) "$ |\\alpha $")))
  (fm-test-insertion "$aa| $" "$\\alpha| $"))

(ert-deftest fm-test-anchoring ()
  ;; `lp' must not be found in the middle of a word (the original code
  ;; expanded it and left `foo' dangling).
  (fm-test-simple-insertion "lpfoo" "l_{p,f,o,o}")
  (fm-test-no-expansion "x+-")
  (fm-test-no-expansion "\\alpha")
  (fm-test-no-expansion "x->")
  ;; The match must end at point.
  (fm-test-insertion "$ aa b| $" "$ aa b | $"))

(ert-deftest fm-test-no-expansion ()
  (fm-test-no-expansion "x")
  (fm-test-no-expansion "3")
  (fm-test-no-expansion "12")
  (fm-test-no-expansion "//123")
  ;; A second space after an expansion is a plain space.
  (fm-test-insertion-with-kbd "$ aa| $" (kbd "SPC SPC") "$ \\alpha | $")
  ;; Outside math, nothing happens.
  (fm-test-insertion "aa| $x$" "aa | $x$"))

;;;; Fractions, integrals, sums

(ert-deftest fm-test-fraction ()
  ;; Simple fractions
  (fm-test-simple-insertion "//2" "\\frac{1}{2}")
  (fm-test-simple-insertion "//a" "\\frac{1}{a}")
  (fm-test-simple-insertion "//12" "\\frac{1}{2}")
  (fm-test-simple-insertion "//3a" "\\frac{3}{a}")
  (fm-test-simple-insertion "//ba" "\\frac{b}{a}")
  (fm-test-simple-insertion "//aab" "\\frac{\\alpha}{b}")
  (fm-test-simple-insertion "//baa" "\\frac{b}{\\alpha}")
  (fm-test-simple-insertion "//aabb" "\\frac{\\alpha}{\\beta}")
  ;; Three atoms: not a fraction, and nothing is lost.
  (fm-test-simple-insertion "//123" "//123 ")
  ;; Snippet
  (fm-test-insertion-with-kbd "$ //| $" (kbd "SPC a TAB b") "$ \\frac{a}{b|} $" )
  (fm-test-insertion-with-kbd "$ //| $" (kbd "SPC a TAB b TAB") "$ \\frac{a}{b}| $" )
  (fm-test-insertion-with-kbd
   "$ m//| $" (kbd "SPC a TAB b TAB") "$ \\frac{
  a
}{
  b
}| $")
  ;; Expanding inside a snippet field.
  (fm-test-insertion-with-kbd "$ //| $" (kbd "SPC a a SPC TAB b TAB")
                              "$ \\frac{\\alpha}{b}| $"))

(ert-deftest fm-test-integral ()
  (fm-test-simple-insertion "int" "\\int")
  (fm-test-simple-insertion "int0a" "\\int_{0}^{a}")
  (fm-test-simple-insertion "intWW" "\\int_{\\Omega}")
  (fm-test-simple-insertion "int0WW" "\\int_{0}^{\\Omega}")
  (fm-test-simple-insertion "intaab" "\\int_{\\alpha}^{b}")
  (fm-test-simple-insertion "intR" "\\int_{\\mathbb{R}}")
  (fm-test-simple-insertion "intR3" "\\int_{\\mathbb{R}^{3}}")
  (fm-test-simple-insertion "intRn" "\\int_{\\mathbb{R}^{n}}"))

(ert-deftest fm-test-sumlike ()
  (fm-test-simple-insertion "sum" "\\sum")
  (fm-test-simple-insertion "sumi" "\\sum_{i}")
  (fm-test-simple-insertion "sumin" "\\sum_{i=1}^{n}")
  (fm-test-simple-insertion "sumi3n" "\\sum_{i=3}^{n}")
  (fm-test-simple-insertion "sumaa" "\\sum_{\\alpha}")
  (fm-test-simple-insertion "sumi0WW" "\\sum_{i=0}^{\\Omega}")
  (fm-test-simple-insertion "prodk" "\\prod_{k}")
  (fm-test-simple-insertion "cupi" "\\bigcup_{i}")
  (fm-test-simple-insertion "capin" "\\bigcap_{i=1}^{n}"))

;;;; Operators

(ert-deftest fm-test-double-arg-op ()
  (fm-test-simple-insertion "pdgy" "\\frac{\\partial g}{\\partial y}")
  (fm-test-simple-insertion "pdfaa" "\\frac{\\partial f}{\\partial \\alpha}")
  (fm-test-simple-insertion "dpxy" "\\langle x, y \\rangle")
  (fm-test-simple-insertion "dpaab" "\\langle \\alpha, b \\rangle"))

(ert-deftest fm-test-single-arg-op ()
  (fm-test-simple-insertion "hax" "\\hat{x}")
  (fm-test-simple-insertion "bay" "\\bar{y}")
  (fm-test-simple-insertion "haaa" "\\hat{\\alpha}")
  (fm-test-simple-insertion "haxi" "\\hat{x}_{i}")
  (fm-test-simple-insertion "haxi6j" "\\hat{x}_{i}^{j}")
  (fm-test-simple-insertion "whax" "\\widehat{x}")
  (fm-test-simple-insertion "wbax" "\\overline{x}")
  (fm-test-simple-insertion "vex" "\\vec{x}")
  (fm-test-simple-insertion "tiy" "\\tilde{y}")
  (fm-test-simple-insertion "bmv" "\\bm{v}"))

(ert-deftest fm-test-custom-operator-key ()
  (let ((fastmath-operators-key (cons '("no" . "norm") fastmath-operators-key)))
    (fm-test-simple-insertion "nox" "\\norm{x}"))
  ;; Removed from the defaults: falls back to a plain subscript.
  (fm-test-simple-insertion "nox" "n_{o,x}"))

(ert-deftest fm-test-mathfont ()
  (fm-test-simple-insertion "bR" "\\mathbb{R}")
  (fm-test-simple-insertion "bRn" "\\mathbb{R}_{n}")
  (fm-test-simple-insertion "bR63" "\\mathbb{R}^{3}")
  (fm-test-simple-insertion "bR6n" "\\mathbb{R}^{n}")
  (fm-test-simple-insertion "cA" "\\mathcal{A}")
  (fm-test-simple-insertion "cAi" "\\mathcal{A}_{i}"))

(ert-deftest fm-test-differential ()
  (fm-test-simple-insertion "dx" "\\mathrm{d}x")
  (fm-test-simple-insertion "dt" "\\mathrm{d}t")
  (fm-test-simple-insertion "daa" "\\mathrm{d}\\alpha")
  ;; `dd' is delta, not the differential of d.
  (fm-test-simple-insertion "dd" "\\delta")
  (fm-test-simple-insertion "d1" "d_{1}"))

;;;; Head and modifiers

(ert-deftest fm-test-five-chars ()
  (fm-test-simple-insertion "aai6j" "\\alpha_{i}^{j}"))

(ert-deftest fm-test-four-chars ()
  (fm-test-simple-insertion "xi63" "x_{i}^{3}")
  (fm-test-simple-insertion "x6ij" "x^{i,j}")
  (fm-test-simple-insertion "xijk" "x_{i,j,k}"))

(ert-deftest fm-test-three-chars ()
  (fm-test-simple-insertion "aa4" "\\alpha_{4}")
  (fm-test-simple-insertion "x6i" "x^{i}")
  (fm-test-simple-insertion "xij" "x_{i,j}")
  (fm-test-simple-insertion "x1i" "x_{1,i}")
  (fm-test-simple-insertion "xaa" "x_{\\alpha}")
  (fm-test-simple-insertion "aai" "\\alpha_{i}")
  (fm-test-simple-insertion "x62" "x^{2}"))

(ert-deftest fm-test-two-chars ()
  (fm-test-simple-insertion "aa" "\\alpha") ; redundant with greek test
  (fm-test-simple-insertion "xi" "x_{i}")
  (fm-test-simple-insertion "x6" "x_{6}")
  (fm-test-simple-insertion "cc" "c_{c}"))

;;;; Snippets

(ert-deftest fm-test-parenthesis-snippets ()
  (fm-test-insertion-with-kbd "$ lp| $" (kbd "SPC x") "$ \\left( x| \\right) $")
  (fm-test-insertion-with-kbd "$ lpb| $" (kbd "SPC x TAB") "$ \\left\\{ x \\right\\}| $")
  (fm-test-insertion-with-kbd "$ lpbr| $" (kbd "SPC x") "$ \\left[ x| \\right] $"))

(ert-deftest fm-test-function-snippet ()
  ;; The original code fell through to other rules after `fx'.
  (fm-test-insertion "$ fx| $" "$ | :  \\to  $")
  (fm-test-insertion-with-kbd "$ fx| $" (kbd "SPC f TAB X TAB Y")
                              "$ f : X \\to Y| $"))

(ert-deftest fm-test-snippets-without-yasnippet ()
  (let ((fm-test-yas nil))
    (fm-test-insertion "$ //| $" "$ \\frac{|}{} $")
    (fm-test-insertion "$ m//| $" "$ \\frac{\n  |\n}{\n  \n} $")
    (fm-test-insertion "$ lp| $" "$ \\left( | \\right) $")
    (fm-test-insertion "$ lpb| $" "$ \\left\\{ | \\right\\} $")
    (fm-test-insertion "$ lpbr| $" "$ \\left[ | \\right] $")
    (fm-test-insertion "$ fx| $" "$ | :  \\to  $")
    ;; Plain expansions are unaffected.
    (fm-test-simple-insertion "aa" "\\alpha")))

;;;; Commands and options

(ert-deftest fm-test-expand-command ()
  (fm-test-with-temp-buffer "$ aa| $" nil
    (fastmath-expand)
    (fm-buffer-equals "$ \\alpha| $"))
  (fm-test-with-temp-buffer "$ int0a| $" nil
    (fastmath-expand)
    (fm-buffer-equals "$ \\int_{0}^{a}| $"))
  ;; Works outside math and without expand-on-space.
  (let ((fastmath-expand-on-space nil))
    (fm-test-with-temp-buffer "text xi|" nil
      (fastmath-expand)
      (fm-buffer-equals "text x_{i}|")))
  (fm-test-with-temp-buffer "$ x| $" nil
    (should-error (fastmath-expand) :type 'user-error)
    (fm-buffer-equals "$ x| $")))

(ert-deftest fm-test-interrupt ()
  (fm-test-with-temp-buffer "$ aa| $" nil
    (fastmath-interrupt)
    (should fastmath--interrupted)
    (execute-kbd-macro (kbd "SPC"))
    (fm-buffer-equals "$ aa | $")
    ;; One shot only.
    (should-not fastmath--interrupted)
    (execute-kbd-macro (kbd "b b SPC"))
    (fm-buffer-equals "$ aa \\beta| $"))
  ;; The next space consumes the flag even outside math, so that it
  ;; cannot linger and surprise later.
  (fm-test-with-temp-buffer "text| $aa$" nil
    (fastmath-interrupt)
    (execute-kbd-macro (kbd "SPC"))
    (fm-buffer-equals "text | $aa$")
    (should-not fastmath--interrupted))
  (let ((fastmath-expand-on-space nil))
    (fm-test-with-temp-buffer "$ aa| $" nil
      (fastmath-interrupt)
      (execute-kbd-macro (kbd "SPC"))
      (should-not fastmath--interrupted))))

(ert-deftest fm-test-expand-on-space-nil ()
  (let ((fastmath-expand-on-space nil))
    (fm-test-simple-insertion "aa" "aa ")
    (fm-test-simple-insertion "!=" "!= ")))

(ert-deftest fm-test-custom-predicate ()
  (let ((fastmath-math-predicate (lambda () t)))
    (fm-test-insertion "aa|" "\\alpha|"))
  (let ((fastmath-math-predicate #'ignore))
    (fm-test-simple-insertion "aa" "aa "))
  ;; A predicate that signals leaves the typed text alone.
  (let ((fastmath-math-predicate (lambda () (error "Boom"))))
    (fm-test-simple-insertion "aa" "aa ")))

(ert-deftest fm-test-author-formats ()
  (let ((fastmath-mathfont-alist '(("b" . "\\%s%s") ("c" . "\\mathcal{%s}")))
        (fastmath-dot-product-format "\\dotp{%s}{%s}")
        (fastmath-differential-format "\\d %s"))
    (fm-test-simple-insertion "bR" "\\RR")
    (fm-test-simple-insertion "bRn" "\\RR_{n}")
    (fm-test-simple-insertion "bR63" "\\RR^{3}")
    (fm-test-simple-insertion "cA" "\\mathcal{A}")
    (fm-test-simple-insertion "intR" "\\int_{\\RR}")
    (fm-test-simple-insertion "intR3" "\\int_{\\RR^{3}}")
    (fm-test-simple-insertion "dpxy" "\\dotp{x}{y}")
    (fm-test-simple-insertion "dx" "\\d x")
    (fm-test-simple-insertion "daa" "\\d \\alpha")
    ;; The README example.
    (fm-test-insertion-with-kbd
     "$ | $" (kbd "i n t 0 a SPC SPC f ( x ) SPC d x SPC")
     "$ \\int_{0}^{a} f(x) \\d x| $")))

(ert-deftest fm-test-readme-example ()
  (fm-test-insertion-with-kbd
   "$ | $" (kbd "i n t 0 a SPC SPC f ( x ) SPC d x SPC")
   "$ \\int_{0}^{a} f(x) \\mathrm{d}x| $"))

(ert-deftest fm-test-error-in-rule-keeps-text ()
  ;; A handler that signals: the word and the space stay.
  (let ((fastmath-rules (cons (cons "aa" (lambda (_word) (error "Boom")))
                              fastmath-rules)))
    (fm-test-simple-insertion "aa" "aa ")
    (fm-test-with-temp-buffer "$ aa| $" nil
      (should-error (fastmath-expand))
      (fm-buffer-equals "$ aa| $")))
  ;; A handler whose result cannot be inserted (fails after the word
  ;; was deleted): the change is undone.
  (let ((fastmath-rules (cons (cons "aa" (lambda (_word) '(snippet . 42)))
                              fastmath-rules)))
    (fm-test-simple-insertion "aa" "aa ")))

(ert-deftest fm-test-mode-toggling ()
  (fm-test-with-temp-buffer "$ aa| $" nil
    (should (memq #'fastmath-space post-self-insert-hook))
    (fastmath-mode -1)
    (should-not (memq #'fastmath-space post-self-insert-hook))
    (execute-kbd-macro (kbd "SPC"))
    (fm-buffer-equals "$ aa | $")
    ;; The hook is buffer-local.
    (with-temp-buffer
      (should-not (memq #'fastmath-space post-self-insert-hook)))))

;;;; Real-world typing scenarios

(ert-deftest fm-test-undo-restores-word ()
  ;; One undo after an expansion gives the typed word back, nothing else.
  (fm-test-with-temp-buffer "$ | $" nil
    (buffer-enable-undo)
    (execute-kbd-macro (kbd "a a SPC"))
    (fm-buffer-equals "$ \\alpha| $")
    (undo-boundary)
    (let ((last-command 'ignore)) (undo))
    (fm-buffer-equals "$ aa| $"))
  ;; A space that expands nothing is undone like any other space.
  (fm-test-with-temp-buffer "$ x| $" nil
    (buffer-enable-undo)
    (undo-boundary)
    (execute-kbd-macro (kbd "SPC"))
    (fm-buffer-equals "$ x | $")
    (undo-boundary)
    (let ((last-command 'ignore)) (undo))
    (fm-buffer-equals "$ x| $")))

(ert-deftest fm-test-text-in-math ()
  ;; `\text{}' switches math off: no expansion inside it.
  (fm-test-insertion "$ \\text{a xi|} $" "$ \\text{a xi |} $")
  (fm-test-insertion "$ \\text{a|} + xi $" "$ \\text{a |} + xi $"))

(ert-deftest fm-test-non-latex-buffer ()
  ;; The mode may be enabled anywhere; `texmathp' still decides.
  (save-window-excursion
    (with-temp-buffer
      (set-input-method nil)
      (fundamental-mode)
      (fastmath-mode 1)
      (pop-to-buffer (current-buffer))
      (insert "aa")
      (execute-kbd-macro (kbd "SPC"))
      (should (equal (buffer-string) "aa "))
      (insert "$ aa")
      (execute-kbd-macro (kbd "SPC"))
      (should (equal (buffer-string) "aa $ \\alpha")))))

(ert-deftest fm-test-case-fold-search ()
  ;; A global `case-fold-search' of t must not blur the case of keys.
  (fm-test-with-temp-buffer "$ bR| $" nil
    (let ((case-fold-search t))
      (execute-kbd-macro (kbd "SPC")))
    (fm-buffer-equals "$ \\mathbb{R}| $"))
  (fm-test-with-temp-buffer "$ Xi| $" nil
    (let ((case-fold-search t))
      (execute-kbd-macro (kbd "SPC")))
    (fm-buffer-equals "$ X_{i}| $"))
  (fm-test-with-temp-buffer "$ WW| $" nil
    (let ((case-fold-search t))
      (execute-kbd-macro (kbd "SPC")))
    (fm-buffer-equals "$ \\Omega| $")))

(ert-deftest fm-test-custom-keys-with-metacharacters ()
  (let ((fastmath-symbol-abbrevs '(("a.b" . "\\ab") ("x*" . "\\xs"))))
    (fm-test-simple-insertion "a.b" "\\ab ")
    (fm-test-simple-insertion "x*" "\\xs ")
    (fm-test-simple-insertion "aXb" "a_{X,b}")
    (fm-test-simple-insertion "xx" "\\xi"))
  (let ((fastmath-unicode-greek-alist
         '(("]" . "\\rb") ("-" . "\\dash") ("α" . "\\alpha"))))
    (fm-test-simple-insertion "xα" "x_{\\alpha}")
    (fm-test-simple-insertion "α" "\\alpha")))

(ert-deftest fm-test-edge-words ()
  ;; Greedy tokenization, digits and the `6' marker in odd places.
  (fm-test-simple-insertion "ddd" "\\delta_{d}")
  (fm-test-simple-insertion "dddd" "\\delta_{\\delta}")
  (fm-test-simple-insertion "xxx" "\\xi_{x}")
  (fm-test-simple-insertion "aaa" "\\alpha_{a}")
  (fm-test-simple-insertion "AA" "A_{A}")
  (fm-test-simple-insertion "a1" "a_{1}")
  (fm-test-simple-insertion "x66" "x^{6}")
  (fm-test-simple-insertion "x66i" "x^{6,i}")
  (fm-test-simple-insertion "x16" "x_{1,6}")
  (fm-test-simple-insertion "αα" "\\alpha_{\\alpha}")
  (fm-test-simple-insertion "Ωi" "\\Omega_{i}")
  (fm-test-no-expansion "1a")
  (fm-test-no-expansion "66")
  (fm-test-no-expansion "6x")
  ;; A capital that maps to a latin letter is a single letter.
  (fm-test-no-expansion "Α"))

(ert-deftest fm-test-rule-precedence ()
  ;; Math fonts (upper-case letter) beat the operator `bm' / `ba'.
  (fm-test-simple-insertion "bM" "\\mathbb{M}")
  (fm-test-simple-insertion "bmx" "\\bm{x}")
  (fm-test-simple-insertion "bA" "\\mathbb{A}")
  (fm-test-simple-insertion "baA" "\\bar{A}")
  ;; Sum-like keys beat the math font `c'.
  (fm-test-simple-insertion "capA" "\\bigcap_{A}")
  (fm-test-simple-insertion "cAp" "\\mathcal{A}_{p}")
  (fm-test-simple-insertion "cup" "\\bigcup")
  ;; `dint' is a symbol; `dp'/`pd' need two atoms; `d' + one atom is a
  ;; differential; otherwise the head rule applies.
  (fm-test-simple-insertion "dint" "\\int_{-\\infty}^{+\\infty} ")
  (fm-test-simple-insertion "dp" "\\mathrm{d}p")
  (fm-test-simple-insertion "pd" "p_{d}")
  (fm-test-simple-insertion "dpx" "d_{p,x}")
  (fm-test-simple-insertion "ddx" "\\delta_{x}")
  (fm-test-simple-insertion "dxi" "d_{x,i}")
  ;; Operators take any atom, keys alone fall back to the head rule.
  (fm-test-simple-insertion "hat" "\\hat{t}")
  (fm-test-simple-insertion "ha" "h_{a}")
  (fm-test-simple-insertion "bm" "b_{m}")
  (fm-test-simple-insertion "ba" "b_{a}")
  ;; Symbols are whole words only.
  (fm-test-simple-insertion "lll" "\\ell ")
  (fm-test-simple-insertion "ll" "\\lambda")
  (fm-test-simple-insertion "x62" "x^{2}")
  (fm-test-simple-insertion "fxi" "f_{x,i}")
  (fm-test-simple-insertion "lpx" "l_{p,x}"))

;;;; Toggle inline/display

(ert-deftest fm-test-toggle-inline-to-display ()
  (fm-test-with-temp-buffer "text $x|y$ more" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "text \\[ x|y \\] more"))
  (fm-test-with-temp-buffer "text $ x|y $ more" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "text \\[ x|y \\] more"))
  (fm-test-with-temp-buffer "text \\(x|y\\) more" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "text \\[ x|y \\] more"))
  (let ((fastmath-display-math-style "equation"))
    (fm-test-with-temp-buffer "text $x|y$ more" nil
      (fastmath-toggle-inline)
      (fm-buffer-equals "text \\begin{equation}\nx|y\n\\end{equation} more"))))

(ert-deftest fm-test-toggle-display-to-inline ()
  (fm-test-with-temp-buffer "text \\[ x|y \\] more" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "text $x|y$ more"))
  (fm-test-with-temp-buffer "text $$ x|y $$ more" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "text $x|y$ more"))
  (fm-test-with-temp-buffer "text\n\\begin{equation}\n  x|y\n\\end{equation}\nmore" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "text\n$x|y$\nmore"))
  (fm-test-with-temp-buffer "\\begin{align*}\n  a &= b|\n\\end{align*}" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "$a &= b|$"))
  ;; The column argument of alignat is not part of the content.
  (fm-test-with-temp-buffer "\\begin{alignat}{2}\n  a &= b|\n\\end{alignat}" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "$a &= b|$"))
  (fm-test-with-temp-buffer "\\begin{alignat*}{2}\n  a|\n\\end{alignat*}" nil
    (fastmath-toggle-inline)
    (fm-buffer-equals "$a|$"))
  (let ((fastmath-inline-math-style 'parens))
    (fm-test-with-temp-buffer "text \\[ x|y \\] more" nil
      (fastmath-toggle-inline)
      (fm-buffer-equals "text \\(x|y\\) more"))))

(ert-deftest fm-test-toggle-round-trip ()
  (fm-test-with-temp-buffer "text $x|y$ more" nil
    (fastmath-toggle-inline)
    (fastmath-toggle-inline)
    (fm-buffer-equals "text $x|y$ more"))
  (fm-test-with-temp-buffer "text \\[ x|y \\] more" nil
    (fastmath-toggle-inline)
    (fastmath-toggle-inline)
    (fm-buffer-equals "text \\[ x|y \\] more")))

(ert-deftest fm-test-toggle-outside-math ()
  (fm-test-with-temp-buffer "text| $xy$ more" nil
    (should-error (fastmath-toggle-inline) :type 'user-error)
    (fm-buffer-equals "text| $xy$ more")))

(provide 'fastmath-integration-test)
;;; fastmath-integration-test.el ends here
