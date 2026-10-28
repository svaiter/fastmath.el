;;; bootstrap.el --- Dependency bootstrap for the fastmath test suite -*- lexical-binding: t -*-

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
;; Load this file first in a batch Emacs (`emacs -Q --batch -l
;; test/bootstrap.el ...') to get a self-contained environment for
;; compiling, linting and testing fastmath.el with nothing but
;; package.el:
;;
;; - `package-user-dir' is a repo-local `.elpa/' directory (override
;;   with the ELPA_DIR environment variable);
;; - GNU ELPA and MELPA are the package archives;
;; - the runtime dependencies (AUCTeX, yasnippet) are installed when
;;   missing, and `package-lint' as well when FASTMATH_LINT is set;
;; - the repository root and `test/' are added to `load-path'.
;;
;; The file is idempotent: once the packages are installed it only
;; initializes package.el, so it is cheap to load from every Makefile
;; target.  It works on Emacs 27.1 and later.

;;; Code:

(defconst fastmath-bootstrap-root
  (expand-file-name
   ".."
   (file-name-directory (or load-file-name buffer-file-name)))
  "Root directory of the fastmath.el repository.")

(defconst fastmath-bootstrap-packages
  (append '(auctex yasnippet)
          (and (getenv "FASTMATH_LINT") '(package-lint)))
  "Packages that must be installed before running the test suite.")

(require 'package)
(require 'seq)

;; `package-user-dir' is already bound when Emacs starts, so it must be
;; set (not merely declared) here, and `package-gnupghome-dir' is
;; derived from it at load time, so it is set explicitly as well.
(setq package-user-dir
      (let ((dir (getenv "ELPA_DIR")))
        (expand-file-name (if (and dir (not (equal dir ""))) dir ".elpa")
                          fastmath-bootstrap-root)))
(setq package-gnupghome-dir (expand-file-name "gnupg" package-user-dir))
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))

(defun fastmath-bootstrap--missing-packages ()
  "Return the packages of `fastmath-bootstrap-packages' not yet installed."
  (seq-remove #'package-installed-p fastmath-bootstrap-packages))

(defun fastmath-bootstrap--install (packages)
  "Refresh the archive contents and install PACKAGES."
  (package-refresh-contents)
  (dolist (pkg packages)
    (message "bootstrap: installing %s" pkg)
    ;; DONT-SELECT: do not touch `package-selected-packages', which
    ;; would try to save customizations from a `-Q' session.
    (package-install pkg t)))

(unless (bound-and-true-p package--initialized)
  (package-initialize))

(let ((missing (fastmath-bootstrap--missing-packages)))
  (when missing
    (message "bootstrap: package-user-dir is %s" package-user-dir)
    (condition-case err
        (fastmath-bootstrap--install missing)
      (error
       ;; Older Emacs releases ship an expired GNU ELPA signing key,
       ;; which makes signature verification fail.  Retry once without
       ;; it rather than leave the build broken.
       (message "bootstrap: install failed (%s); retrying without signature checks"
                (error-message-string err))
       (let ((package-check-signature nil))
         (fastmath-bootstrap--install (fastmath-bootstrap--missing-packages)))))
    (let ((still-missing (fastmath-bootstrap--missing-packages)))
      (when still-missing
        (error "bootstrap: could not install %s" still-missing)))))

(add-to-list 'load-path fastmath-bootstrap-root)
(add-to-list 'load-path (expand-file-name "test" fastmath-bootstrap-root))

(provide 'bootstrap)
;;; bootstrap.el ends here
