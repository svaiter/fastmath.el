;;; fastmath-test.el --- Test for fastmath -*- lexical-binding: t -*-

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

(ert-deftest test-fastmath-nil-or-empty-p ()
  (should (equal (fastmath--nil-or-empty-p nil) t))
  (should (equal (fastmath--nil-or-empty-p "") t))
  (should (equal (fastmath--nil-or-empty-p "4") nil))
  (should (equal (fastmath--nil-or-empty-p " ") nil)))

(ert-deftest test-fastmath-fraction ()
  (should (equal (fastmath--make-fraction "2" 'latin "3" 'latin) "\\\\frac{2}{3}"))
  (should (equal (fastmath--make-fraction "1" 'latin "a" 'latin) "\\\\frac{1}{a}"))
  (should (equal (fastmath--make-fraction "a" 'latin "2" 'latin) "\\\\frac{a}{2}"))
  (should (equal (fastmath--make-fraction "b" 'latin "a" 'latin) "\\\\frac{b}{a}"))
  (should (equal (fastmath--make-fraction "a" 'greek "a" 'latin) "\\\\frac{\\\\alpha}{a}"))
  (should (equal (fastmath--make-fraction "a" 'greek "b" 'greek) "\\\\frac{\\\\alpha}{\\\\beta}")))

(provide 'fastmath-test)
;;; fastmath-test.el ends here
