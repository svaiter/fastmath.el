;;; fastmath-test.el --- Unit tests for fastmath -*- lexical-binding: t -*-

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
;; Unit tests for the tokenizer, the LaTeX builders and the rule
;; handlers of fastmath.  These tests never touch a LaTeX buffer; see
;; fastmath-integration-test.el for end-to-end tests.
;;

;;; Code:

(require 'ert)
(require 'fastmath)

;;;; Tokenizer

(ert-deftest test-fastmath-tokenize-latin-and-digits ()
  (should (equal (fastmath--tokenize "x") '(("x" . latin))))
  (should (equal (fastmath--tokenize "xi1")
                 '(("x" . latin) ("i" . latin) ("1" . digit))))
  (should (equal (fastmath--tokenize "AB") '(("A" . latin) ("B" . latin)))))

(ert-deftest test-fastmath-tokenize-doubled-greek ()
  (should (equal (fastmath--tokenize "aa") '(("\\alpha" . greek))))
  (should (equal (fastmath--tokenize "WW") '(("\\Omega" . greek))))
  (should (equal (fastmath--tokenize "xaa")
                 '(("x" . latin) ("\\alpha" . greek))))
  (should (equal (fastmath--tokenize "aai")
                 '(("\\alpha" . greek) ("i" . latin))))
  ;; Greedy from left to right.
  (should (equal (fastmath--tokenize "xxi")
                 '(("\\xi" . greek) ("i" . latin))))
  (should (equal (fastmath--tokenize "aaa")
                 '(("\\alpha" . greek) ("a" . latin))))
  (should (equal (fastmath--tokenize "dd") '(("\\delta" . greek)))))

(ert-deftest test-fastmath-tokenize-doubled-without-greek-entry ()
  ;; c, o and A have no greek counterpart: two latin atoms.
  (should (equal (fastmath--tokenize "cc") '(("c" . latin) ("c" . latin))))
  (should (equal (fastmath--tokenize "oo") '(("o" . latin) ("o" . latin))))
  (should (equal (fastmath--tokenize "AA") '(("A" . latin) ("A" . latin)))))

(ert-deftest test-fastmath-tokenize-unicode-greek ()
  (should (equal (fastmath--tokenize "α") '(("\\alpha" . greek))))
  (should (equal (fastmath--tokenize "Ω") '(("\\Omega" . greek))))
  (should (equal (fastmath--tokenize "xα") '(("x" . latin) ("\\alpha" . greek))))
  (should (equal (fastmath--tokenize "αi") '(("\\alpha" . greek) ("i" . latin))))
  ;; Mapping by name, like the TeX input method.
  (should (equal (fastmath--tokenize "ε") '(("\\epsilon" . greek))))
  (should (equal (fastmath--tokenize "ϵ") '(("\\varepsilon" . greek))))
  (should (equal (fastmath--tokenize "φ") '(("\\phi" . greek))))
  (should (equal (fastmath--tokenize "ϕ") '(("\\varphi" . greek))))
  (should (equal (fastmath--tokenize "θ") '(("\\theta" . greek))))
  (should (equal (fastmath--tokenize "ϑ") '(("\\vartheta" . greek))))
  (should (equal (fastmath--tokenize "ς") '(("\\varsigma" . greek))))
  ;; Capitals rendered as latin letters.
  (should (equal (fastmath--tokenize "Α") '(("A" . latin))))
  (should (equal (fastmath--tokenize "Χ") '(("X" . latin)))))

(ert-deftest test-fastmath-tokenize-invalid ()
  (should (null (fastmath--tokenize "")))
  (should (null (fastmath--tokenize "x/")))
  (should (null (fastmath--tokenize "\\alpha")))
  (should (null (fastmath--tokenize "x y"))))

(ert-deftest test-fastmath-tokenize-custom-greek-alist ()
  (let ((fastmath-greek-alist '(("e" . "\\varepsilon"))))
    (should (equal (fastmath--tokenize "ee") '(("\\varepsilon" . greek))))
    ;; `a' no longer has an entry.
    (should (equal (fastmath--tokenize "aa") '(("a" . latin) ("a" . latin))))))

(ert-deftest test-fastmath-parse-modifiers ()
  (should (equal (fastmath--parse-modifiers "") '(nil nil)))
  (should (equal (fastmath--parse-modifiers "xi")
                 '((("x" . latin) ("i" . latin)) nil)))
  (should (equal (fastmath--parse-modifiers "xi63")
                 '((("x" . latin) ("i" . latin)) (("3" . digit)))))
  (should (equal (fastmath--parse-modifiers "x6ij")
                 '((("x" . latin)) (("i" . latin) ("j" . latin)))))
  ;; A trailing 6 is a plain subscript.
  (should (equal (fastmath--parse-modifiers "x6")
                 '((("x" . latin) ("6" . digit)) nil)))
  (should (equal (fastmath--parse-modifiers "63") '(nil (("3" . digit)))))
  (should (null (fastmath--parse-modifiers "x/")))
  (should (null (fastmath--parse-modifiers "x6/"))))

(ert-deftest test-fastmath-split-key ()
  (let ((keys '("ha" "wha" "ba" "wba")))
    (should (equal (fastmath--split-key "hax" keys) '("ha" . "x")))
    (should (equal (fastmath--split-key "whax" keys) '("wha" . "x")))
    (should (equal (fastmath--split-key "wbax" keys) '("wba" . "x")))
    (should (equal (fastmath--split-key "ba" keys) '("ba" . "")))
    (should (null (fastmath--split-key "xha" keys)))))

;;;; Builders

(ert-deftest test-fastmath-nil-or-empty-p ()
  (should (equal (fastmath--nil-or-empty-p nil) t))
  (should (equal (fastmath--nil-or-empty-p "") t))
  (should (equal (fastmath--nil-or-empty-p "4") nil))
  (should (equal (fastmath--nil-or-empty-p " ") nil)))

(ert-deftest test-fastmath-sub-and-sup-script ()
  (should (equal (fastmath--make-sub-and-sup-script "x" nil nil) "x"))
  (should (equal (fastmath--make-sub-and-sup-script "x" "" "") "x"))
  (should (equal (fastmath--make-sub-and-sup-script "x" "i" nil) "x_{i}"))
  (should (equal (fastmath--make-sub-and-sup-script "x" nil "2") "x^{2}"))
  (should (equal (fastmath--make-sub-and-sup-script "x" "i,j" "2") "x_{i,j}^{2}")))

(ert-deftest test-fastmath-fraction ()
  (should (equal (fastmath--make-fraction "2" "3") "\\frac{2}{3}"))
  (should (equal (fastmath--make-fraction "1" "a") "\\frac{1}{a}"))
  (should (equal (fastmath--make-fraction "a" "2") "\\frac{a}{2}"))
  (should (equal (fastmath--make-fraction "b" "a") "\\frac{b}{a}"))
  (should (equal (fastmath--make-fraction "\\alpha" "a") "\\frac{\\alpha}{a}"))
  (should (equal (fastmath--make-fraction "\\alpha" "\\beta")
                 "\\frac{\\alpha}{\\beta}")))

(ert-deftest test-fastmath-integral ()
  (should (equal (fastmath--make-integral nil) "\\int"))
  (should (equal (fastmath--make-integral "0") "\\int_{0}"))
  (should (equal (fastmath--make-integral "0" "a") "\\int_{0}^{a}")))

(ert-deftest test-fastmath-sumlike ()
  (should (equal (fastmath--make-sumlike "sum" nil) "\\sum"))
  (should (equal (fastmath--make-sumlike "sum" "i") "\\sum_{i}"))
  (should (equal (fastmath--make-sumlike "sum" "i" nil "n") "\\sum_{i=1}^{n}"))
  (should (equal (fastmath--make-sumlike "bigcup" "i" "3" "n")
                 "\\bigcup_{i=3}^{n}")))

(ert-deftest test-fastmath-operator ()
  (should (equal (fastmath--make-operator "hat" "x") "\\hat{x}"))
  (should (equal (fastmath--make-operator "overline" "\\alpha")
                 "\\overline{\\alpha}")))

(ert-deftest test-fastmath-mathfont ()
  (should (equal (fastmath--make-mathfont "b" "R") "\\mathbb{R}"))
  (should (equal (fastmath--make-mathfont "c" "A") "\\mathcal{A}"))
  ;; The author's format receives the letter twice.
  (let ((fastmath-mathfont-alist '(("b" . "\\%s%s"))))
    (should (equal (fastmath--make-mathfont "b" "R") "\\RR")))
  ;; A function is called with the letter.
  (let ((fastmath-mathfont-alist
         (list (cons "b" (lambda (letter) (concat "\\bb" letter))))))
    (should (equal (fastmath--make-mathfont "b" "R") "\\bbR")))
  (should-error (fastmath--make-mathfont "z" "R")))

(ert-deftest test-fastmath-differential-and-dot-product ()
  (should (equal (fastmath--make-differential "x") "\\mathrm{d}x"))
  (should (equal (fastmath--make-differential "\\alpha") "\\mathrm{d}\\alpha"))
  (should (equal (fastmath--make-dot-product "x" "y") "\\langle x, y \\rangle"))
  (should (equal (fastmath--make-partial "f" "x")
                 "\\frac{\\partial f}{\\partial x}"))
  (let ((fastmath-differential-format "\\d %s")
        (fastmath-dot-product-format "\\dotp{%s}{%s}"))
    (should (equal (fastmath--make-differential "x") "\\d x"))
    (should (equal (fastmath--make-dot-product "x" "y") "\\dotp{x}{y}"))))

;;;; Rule handlers

(ert-deftest test-fastmath-rule-symbol ()
  (should (equal (fastmath--rule-symbol "!=") "\\neq "))
  (should (equal (fastmath--rule-symbol ".<=") "\\impliedby "))
  (should (equal (fastmath--rule-symbol "∞") "\\infty "))
  (should (null (fastmath--rule-symbol "zz"))))

(ert-deftest test-fastmath-rule-fraction ()
  (should (equal (fastmath--rule-fraction "//")
                 (cons 'snippet fastmath-fraction-snippet)))
  (should (equal (fastmath--rule-fraction "m//")
                 (cons 'snippet fastmath-fraction-multiline-snippet)))
  (should (equal (fastmath--rule-fraction "//2") "\\frac{1}{2}"))
  (should (equal (fastmath--rule-fraction "//aabb") "\\frac{\\alpha}{\\beta}"))
  (should (null (fastmath--rule-fraction "//123")))
  (should (null (fastmath--rule-fraction "m//2"))))

(ert-deftest test-fastmath-rule-integral ()
  (should (equal (fastmath--rule-integral "int") "\\int"))
  (should (equal (fastmath--rule-integral "int0a") "\\int_{0}^{a}"))
  (should (equal (fastmath--rule-integral "intR") "\\int_{\\mathbb{R}}"))
  (should (equal (fastmath--rule-integral "intRn") "\\int_{\\mathbb{R}^{n}}"))
  (should (null (fastmath--rule-integral "int0ab")))
  ;; Without a blackboard font, R is an ordinary bound.
  (let ((fastmath-mathfont-alist '(("c" . "\\mathcal{%s}"))))
    (should (equal (fastmath--rule-integral "intR") "\\int_{R}"))
    (should (equal (fastmath--rule-integral "intRn") "\\int_{R}^{n}"))))

(ert-deftest test-fastmath-rule-sumlike ()
  (should (equal (fastmath--rule-sumlike "prod") "\\prod"))
  (should (equal (fastmath--rule-sumlike "capi") "\\bigcap_{i}"))
  (should (equal (fastmath--rule-sumlike "sumi0WW") "\\sum_{i=0}^{\\Omega}"))
  ;; The index must be a letter.
  (should (null (fastmath--rule-sumlike "sum1n")))
  (should (null (fastmath--rule-sumlike "sumi0nm"))))

(ert-deftest test-fastmath-rule-double-arg ()
  (should (equal (fastmath--rule-double-arg "pdfx")
                 "\\frac{\\partial f}{\\partial x}"))
  (should (equal (fastmath--rule-double-arg "dpxy") "\\langle x, y \\rangle"))
  (should (null (fastmath--rule-double-arg "pdf")))
  (should (null (fastmath--rule-double-arg "pdx1"))))

(ert-deftest test-fastmath-rule-prefixes ()
  (should (equal (fastmath--rule-mathfont "bR") "\\mathbb{R}"))
  (should (equal (fastmath--rule-mathfont "bR6n") "\\mathbb{R}^{n}"))
  (should (null (fastmath--rule-mathfont "br")))
  (should (equal (fastmath--rule-operator "hax") "\\hat{x}"))
  (should (equal (fastmath--rule-operator "whaxi6j") "\\widehat{x}_{i}^{j}"))
  (should (null (fastmath--rule-operator "ha")))
  (should (null (fastmath--rule-operator "ha1")))
  ;; A nil macro name declines instead of producing `\\{x}'.
  (let ((fastmath-operators-key '(("ha" . nil))))
    (should (null (fastmath--rule-operator "hax"))))
  (let ((fastmath-sumlike-key '(("sum" . nil))))
    (should (null (fastmath--rule-sumlike "sumi"))))
  (should (equal (fastmath--rule-differential "dx") "\\mathrm{d}x"))
  (should (null (fastmath--rule-differential "dd")))
  (should (null (fastmath--rule-differential "d1")))
  (should (null (fastmath--rule-differential "dxy"))))

(ert-deftest test-fastmath-rule-head ()
  (should (null (fastmath--rule-head "x")))
  (should (null (fastmath--rule-head "3")))
  (should (null (fastmath--rule-head "12")))
  (should (equal (fastmath--rule-head "aa") "\\alpha"))
  (should (equal (fastmath--rule-head "x6") "x_{6}"))
  (should (equal (fastmath--rule-head "xi63") "x_{i}^{3}"))
  (should (equal (fastmath--rule-head "cc") "c_{c}")))

;;;; Regexp cache

(ert-deftest test-fastmath-regexp-cache-follows-options ()
  (let ((default (fastmath--symbol-regexp)))
    (should (string-match-p (concat "\\`" default "\\'") "!="))
    (let ((fastmath-symbol-abbrevs '(("zz" . "\\zeta"))))
      (should (string-match-p (concat "\\`" (fastmath--symbol-regexp) "\\'") "zz"))
      (should-not (string-match-p (concat "\\`" (fastmath--symbol-regexp) "\\'")
                                  "!=")))
    (should (equal (fastmath--symbol-regexp) default)))
  (let ((fastmath-operators-key '(("no" . "norm"))))
    (should (equal (fastmath--rule-operator "nox") "\\norm{x}")))
  (let ((fastmath-unicode-greek-alist '(("ж" . "\\zhe"))))
    (should (string-match-p (fastmath--atom-regexp) "ж"))
    (should-not (string-match-p (fastmath--atom-regexp) "α"))))

;;;; Regexp construction

(ert-deftest test-fastmath-symbol-regexp-metacharacters ()
  (let* ((fastmath-symbol-abbrevs '(("a.b" . "\\ab") ("x*" . "\\xs") ("[" . "\\lb")))
         (regexp (concat "\\`" (fastmath--symbol-regexp) "\\'")))
    (should (string-match-p regexp "a.b"))
    (should (string-match-p regexp "x*"))
    (should (string-match-p regexp "["))
    (should-not (string-match-p regexp "aXb"))
    (should-not (string-match-p regexp "xx"))
    (should-not (string-match-p regexp "x"))))

(ert-deftest test-fastmath-atom-regexp-special-keys ()
  ;; Keys that are special inside a bracket expression must not break
  ;; the atom regexp.
  (let* ((fastmath-unicode-greek-alist
          '(("]" . "\\rb") ("-" . "\\dash") ("^" . "\\hat") ("α" . "\\alpha")))
         (regexp (concat "\\`" (fastmath--atom-regexp) "\\'")))
    (dolist (key '("α" "]" "-" "^" "a" "Z" "0"))
      (should (string-match-p regexp key)))
    (dolist (key '("/" "β" " " ""))
      (should-not (string-match-p regexp key)))
    (should (equal (fastmath--tokenize "x]") '(("x" . latin) ("\\rb" . greek)))))
  (let ((fastmath-unicode-greek-alist nil))
    (should (string-match-p (concat "\\`" (fastmath--atom-regexp) "\\'") "a"))
    (should-not (string-match-p (fastmath--atom-regexp) "α"))))

;;;; Plain snippets

(ert-deftest test-fastmath-plain-snippet ()
  (with-temp-buffer
    (fastmath--insert-plain-snippet "\\frac{$1}{$2}$0")
    (should (equal (buffer-string) "\\frac{}{}"))
    (should (= (point) 7)))
  (with-temp-buffer
    (fastmath--insert-plain-snippet fastmath-braces-snippet)
    (should (equal (buffer-string) "\\left\\{  \\right\\}"))
    (should (= (point) 9)))
  (with-temp-buffer
    (fastmath--insert-plain-snippet "a ${1:foo} b$0 c")
    (should (equal (buffer-string) "a foo b c"))
    (should (= (point) 3)))
  (with-temp-buffer
    (fastmath--insert-plain-snippet "ab$0cd")
    (should (equal (buffer-string) "abcd"))
    (should (= (point) 3))))

(provide 'fastmath-test)
;;; fastmath-test.el ends here
