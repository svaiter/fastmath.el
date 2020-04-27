CASK = cask
export EMACS ?= emacs
SRCS = $(wildcard *.el)
OBJS = $(SRCS:.el=.elc)

.PHONY: compile test clean

all: compile

compile: elpa
	$(CASK) build

elpa-$(EMACS):
	$(CASK) install
	$(CASK) update
	touch $@

elpa: elpa-$(EMACS)

elpaclean:
	rm -f elpa*
	rm -rf .cask

clean:
	rm -f $(OBJS)

test: elpa
	$(CASK) exec ert-runner -L . -L test "$@"
