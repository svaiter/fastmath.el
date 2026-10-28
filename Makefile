# Build, lint and test fastmath.el with nothing but Emacs and package.el.
#
# Every Emacs invocation loads test/bootstrap.el, which keeps the
# dependencies in a repo-local .elpa/ directory (override the location
# with ELPA_DIR) and installs them on first use.

EMACS ?= emacs
# ERT selector used by `make test', e.g. `make test SELECTOR='"integration"''.
SELECTOR ?= t

BATCH = $(EMACS) -Q --batch -l test/bootstrap.el

.PHONY: all deps test compile checkdoc package-lint lint clean distclean

all: lint test

# Install (or check) the dependencies, including the lint tooling, so a
# warm cache serves every other target.
deps:
	FASTMATH_LINT=1 $(BATCH) --eval '(message "deps: packages are up to date in %s" package-user-dir)'

# Run every test/*-test.el under ERT.  Exits non-zero on failure.
test:
	$(BATCH) -l ert -l test/test-helper.el \
	  $$(for f in test/*-test.el; do printf -- '-l %s ' "$$f"; done) \
	  --eval '(ert-run-tests-batch-and-exit (quote $(SELECTOR)))'

# Byte-compile with warnings turned into errors; never keep the .elc.
compile:
	$(BATCH) --eval '(setq byte-compile-error-on-warn t)' \
	  -f batch-byte-compile fastmath.el; \
	status=$$?; rm -f fastmath.elc; exit $$status

# checkdoc-file only prints its findings, so collect them in a buffer
# and fail when it contains any "file:line:" diagnostic.
CHECKDOC_EL = (progn \
  (require (quote checkdoc)) \
  (let ((checkdoc-diagnostic-buffer "*fastmath-checkdoc*")) \
    (with-current-buffer (find-file-noselect "fastmath.el") \
      (checkdoc-current-buffer t)) \
    (with-current-buffer checkdoc-diagnostic-buffer \
      (goto-char (point-min)) \
      (if (re-search-forward "^[^ \n]+\\.el:[0-9]+:" nil t) \
          (progn (princ (buffer-string)) (terpri) (kill-emacs 1)) \
        (message "checkdoc: fastmath.el is clean")))))

checkdoc:
	$(BATCH) --eval '$(CHECKDOC_EL)'

package-lint:
	FASTMATH_LINT=1 $(BATCH) -f package-lint-batch-and-exit fastmath.el

lint: compile checkdoc package-lint

clean:
	rm -f *.elc test/*.elc

distclean: clean
	rm -rf .elpa
