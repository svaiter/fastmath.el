[![License GPL 3][badge-license]](http://www.gnu.org/licenses/gpl-3.0.txt)
[![Build Status](https://travis-ci.org/svaiter/fastmath.el.svg?branch=master)](https://travis-ci.org/svaiter/fastmath.el)

# Fastmath

Fastmath is an Emacs minor mode to quickly input math when using (La)TeX syntax
beyond the use of abbrev-mode and LaTeX-math-mode.

Major features include:
- Fast insertion of complex operators
- Handle latin and greek alphabet
- Quickly toggle inline/display math (C-c C-g t)
- Integrates with yasnippet

For instance, typing

    i n t 0 a SPC SPC f(x) SPC dx SPC
    
in a math environment will result into

    \int_{0}^{a} f(x) \d x
    
In action:

![Fastmath Screenshot](gifs/demo-fastmath.gif)

*Warning:* At the moment (early dev), everything is a bit fragile. I do not
recommend using it except to contribute. It is also strongly opinionated. It is
based on several hack on my config, LaTeX-math-mode from auctex, CDLaTeX and
some ideas borrowed from [this](https://castel.dev/post/lecture-notes-1/) blog
post.

## Getting start

Fastmath should work fine with any GNU Emacs >= 25.1. At the moment, it is not
yet uploaded to MELPA (I'm waiting for more tests), so you should clone it and
use `load-path` or `use-package`.

To temporarily enable fastmath, call `fastmath-mode`. To permanently enable it,
you should add a hook:

    (add-hook 'LaTeX-mode-hook #'fastmath-mode)
    
## Contributing

Please include tests for your pull requests. Fastmath uses ert for testing. To
run all the tests, run:

    make test
    
Spec tests are located in `test/fastmath-test.el` and integration tests in
`test/fastmath-integration-test.el`.

## TODO
- [ ] Documentation!
- [ ] Clean code (and optimization of the regexp)
- [ ] Handle UTF8 input of greek alphabet
- [ ] Harmonize greek input (double char everywhere)
- [ ] Do not hard-rely on my custom macro (customization)
- [ ] Interrupt for next <SPC>
- [ ] Remove this todo list and rely on GitHub issues
