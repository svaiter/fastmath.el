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

(require 'fastmath)
(require 'buttercup)


(describe "nil-or-empty-p"
  (it "returns t when nil or empty"
    (expect (fastmath--nil-or-empty-p nil) :to-equal t)
    (expect (fastmath--nil-or-empty-p "") :to-equal t))
  (it "returns nil otherwise"
    (expect (fastmath--nil-or-empty-p "4") :to-equal nil)
    (expect (fastmath--nil-or-empty-p " ") :to-equal nil)))

(describe "make-fraction"
  (it "returns a fraction"
    (expect (fastmath--make-fraction "2" 'latin "3" 'latin) :to-equal "\\\\frac{2}{3}")
    (expect (fastmath--make-fraction "2" 'latin "3" 'latin) :to-equal "\\\\frac{2}{3}")
    (expect (fastmath--make-fraction "a" 'latin "2" 'latin) :to-equal "\\\\frac{a}{2}")
    (expect (fastmath--make-fraction "b" 'latin "a" 'latin) :to-equal "\\\\frac{b}{a}")
    (expect (fastmath--make-fraction "a" 'greek "a" 'latin) :to-equal "\\\\frac{\\\\alpha}{a}")
    (expect (fastmath--make-fraction "a" 'greek "b" 'greek) :to-equal "\\\\frac{\\\\alpha}{\\\\beta}")))

(provide 'fastmath-test)
;;; fastmath-test.el ends here
