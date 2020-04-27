;;; fastmath-integration-test.el --- Integration tests for fastmath -*- lexical-binding: t -*-

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

(ert-deftest fm-test-greek-alphabet ()
  (fm-test-simple-insertion "aa" "\\alpha")
  (fm-test-simple-insertion "WW" "\\Omega"))

(ert-deftest fm-test-fraction ()
  ;; Simple fractions
  (fm-test-simple-insertion "//2" "\\frac{1}{2}")
  (fm-test-simple-insertion "//a" "\\frac{1}{a}")
  (fm-test-simple-insertion "//12" "\\frac{1}{2}")
  (fm-test-simple-insertion "//3a" "\\frac{3}{a}")
  (fm-test-simple-insertion "//ba" "\\frac{b}{a}")
  ;; Snippet
  (fm-test-insertion-with-kbd "$ //| $" (kbd "SPC a TAB b") "$ \\frac{a}{b|} $" )
  (fm-test-insertion-with-kbd "$ //| $" (kbd "SPC a TAB b TAB") "$ \\frac{a}{b}| $" )
  (fm-test-insertion-with-kbd
   "$ m//| $" (kbd "SPC a TAB b TAB") "$ \\frac{
  a
}{
  b
}| $"))

(ert-deftest fm-test-integral ()
  (fm-test-simple-insertion "int0a" "\\int_{0}^{a}")
  (fm-test-simple-insertion "intWW" "\\int_{\\Omega}")
  (fm-test-simple-insertion "intR" "\\int_{\\RR}")
  (fm-test-simple-insertion "intR3" "\\int_{\\RR^{3}}"))

(ert-deftest fm-test-sumlike ()
  (fm-test-simple-insertion "sumi" "\\sum_{i}")
  (fm-test-simple-insertion "sumin" "\\sum_{i=1}^{n}")
  (fm-test-simple-insertion "sumi3n" "\\sum_{i=3}^{n}"))

(ert-deftest fm-test-double-arg-op ()
  (fm-test-simple-insertion "pdgy" "\\frac{\\partial g}{\\partial y}")
  (fm-test-simple-insertion "dpxy" "\\dotp{x}{y}"))

(ert-deftest fm-test-single-arg-op ()
  (fm-test-simple-insertion "hax" "\\hat{x}")
  (fm-test-simple-insertion "bay" "\\bar{y}")
  (fm-test-simple-insertion "haaa" "\\hat{\\alpha}"))

(ert-deftest fm-test-mathfont ()
  (fm-test-simple-insertion "bR" "\\RR")
  (fm-test-simple-insertion "bRn" "\\RR_{n}")
  (fm-test-simple-insertion "bR63" "\\RR^{3}"))

(ert-deftest fm-test-five-chars ()
  (fm-test-simple-insertion "aai6j" "\\alpha_{i}^{j}"))

(ert-deftest fm-test-four-chars ()
  (fm-test-simple-insertion "xi63" "x_{i}^{3}"))

(ert-deftest fm-test-three-chars ()
  (fm-test-simple-insertion "aa4" "\\alpha_{4}")
  (fm-test-simple-insertion "x6i" "x^{i}")
  (fm-test-simple-insertion "xij" "x_{i,j}"))

(ert-deftest fm-test-two-chars ()
  (fm-test-simple-insertion "aa" "\\alpha") ; redundant with greek test
  (fm-test-simple-insertion "xi" "x_{i}"))
