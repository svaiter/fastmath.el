# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.2.0 - 2026-10-28

A rewrite of the expansion engine of the 2020 proof of concept. The input
language is the same, but the defaults now produce standard LaTeX, every table
is a user option, and several bugs are gone. The sections marked **Breaking**
change what some words expand to.

### Added

- Unicode greek letters (`α`, `Ω`, `ϵ`, ...) are accepted wherever a latin
  letter is, through the new option `fastmath-unicode-greek-alist`. Capitals
  that LaTeX renders in latin (`Α`, `Β`, ...) map to the latin capital.
- Unicode symbols typed with an input method (`∞`, `∂`, `∈`, `≤`, `→`, ...) are
  symbol abbreviations.
- Doubled-letter greek atoms (`aa`, `WW`) are accepted in every letter slot:
  fraction operands, integral bounds, sum indices and bounds, derivative
  variables, operator arguments, math font subscripts, differentials and
  subscripts/superscripts (`haaa`, `intaab`, `sumaa`, `pdfaa`, `daa`, `//aabb`).
- Subscripts and superscripts of any length, joined by commas: `xijk` gives
  `x_{i,j,k}`, `x6ij` gives `x^{i,j}`, `xi6jk` gives `x_{i}^{j,k}`. The old
  two/three/four/five-character rules are subsumed.
- Command `fastmath-expand`: expand the word before point without typing a
  space, in or out of math.
- Command `fastmath-interrupt`: the next space typed is inserted literally
  (one shot). `C-q SPC` also bypasses the expansion.
- Options `fastmath-expand-on-space`, `fastmath-math-predicate`,
  `fastmath-mathfont-alist`, `fastmath-differential-format`,
  `fastmath-dot-product-format`, `fastmath-display-math-style`,
  `fastmath-inline-math-style`, and one option per snippet
  (`fastmath-fraction-snippet`, `fastmath-fraction-multiline-snippet`,
  `fastmath-parenthesis-snippet`, `fastmath-braces-snippet`,
  `fastmath-brackets-snippet`, `fastmath-function-snippet`).
- `fastmath-rules`, the ordered list of `(REGEXP . HANDLER)` pairs the
  expansion is driven by, for people who want to add their own rules.
- A `Fastmath` menu in `fastmath-mode-map`.
- Words may follow `[ ] = + - , ^ _ & |` as well as whitespace, `$ { } ( )`
  and the beginning of the line: `x=aa` gives `x=\alpha`, `x_aa` gives
  `x_\alpha`.
- Every option takes effect immediately when changed with `setq`, `let` or
  Customize; regexps are rebuilt lazily instead of being computed at load time.
- A `;;; Commentary:` section, a README with the complete reference and this
  changelog.

### Changed

- **Breaking:** `bR` gives `\mathbb{R}` instead of the author's `\RR` macro
  (and `intR` gives `\int_{\mathbb{R}}`). Set `fastmath-mathfont-alist` to
  `(("b" . "\\%s%s") ("c" . "\\mathcal{%s}"))` to get `\RR` back.
- **Breaking:** `dx` gives `\mathrm{d}x` instead of `\d x`. Set
  `fastmath-differential-format` to `"\\d %s"` to get `\d x` back.
- **Breaking:** `dpxy` gives `\langle x, y \rangle` instead of `\dotp{x}{y}`.
  Set `fastmath-dot-product-format` to `"\\dotp{%s}{%s}"` to get `\dotp` back.
- **Breaking:** `.<=` gives amsmath's `\impliedby` instead of the non-standard
  `\impliesby`.
- **Breaking:** the author-specific `no` -> `norm` operator is no longer in
  `fastmath-operators-key`; `nox` is now the plain subscript `n_{o,x}`. Add
  `("no" . "norm")` to the option to restore it.
- **Breaking:** `fastmath--ascii-to-greek-alist` is renamed
  `fastmath-greek-alist` and is now a proper alist of conses whose values are
  the full LaTeX code: `("a" . "\\alpha")` instead of `("a" "alpha")`.
- **Breaking:** the values of `fastmath-symbol-abbrevs`, `fastmath-operators-key`
  and `fastmath-sumlike-key` are now conses of literal strings,
  `("!=" . "\\neq")`, instead of two-element lists of regexps and replacement
  strings, `("!=" "\\\\neq")`. Customizations of these options must be updated.
- **Breaking:** a doubled letter without a greek counterpart (`cc`, `oo`,
  `AA`) is two latin letters (`c_{c}`) instead of producing a bare `\`.
- **Breaking:** `dd` is `\delta`, not the differential `\d d`.
- **Breaking:** a word whose head is a digit (`12`, `3x`) is not expanded.
- `fastmath-toggle-inline` no longer prompts for an environment: inline math
  becomes `\[ ... \]` (or the environment named by
  `fastmath-display-math-style`), display math and environments become `$...$`
  (or `\( ... \)` with `fastmath-inline-math-style`). Surrounding whitespace is
  trimmed and point stays inside the math.
- yasnippet is optional at run time: snippets use `yas-expand-snippet` when
  `yas-minor-mode` is on, otherwise their text is inserted with empty fields
  and point at the first one. yasnippet is no longer `require`d at load time.
- The rule set is data-driven (`fastmath-rules`) instead of a chain of
  `catch`/`throw`; handlers return LaTeX and never touch the buffer, which
  makes them testable on their own.
- The `post-self-insert-hook` function is added buffer-locally and only reacts
  to a space (no longer to a tab).
- An error in a rule is reported as a message and leaves the typed text as it
  was, instead of signalling from the hook.
- Package header: `Package-Requires` is `((emacs "27.1") (auctex "12.2")
  (yasnippet "0.14"))`, `Keywords: tex, wp`, version `0.2.0`, and the URL typo
  (`https//`) is fixed.
- Build system: Cask and ert-runner are replaced by a plain `Makefile` and
  `test/bootstrap.el`, which install the dependencies with `package.el` in a
  repo-local `.elpa/` directory (`make deps`, `make test`, `make lint`). CI
  runs on Emacs 27.2, 28.2, 29.4, 30.1 and a snapshot build.

### Removed

- The TODO list in the README; use the GitHub issue tracker.
- The `Cask` file.
- The `no` -> `norm` default operator (see Changed).

### Fixed

- Keys were searched without anchoring at point, so a key in the middle of a
  word was expanded and the rest left dangling: `lpfoo` expanded `lp` and left
  `foo`. Words are now matched from a delimiter to point; `lpfoo` gives
  `l_{p,f,o,o}` and `aa b` followed by a space is left alone.
- `//` followed by three or more atoms deleted the text; it is now left alone.
- `fx` fell through to the following rules after inserting its snippet.
- Doubled letters without a greek entry (`cc`) produced a bare `\`.
- `dd` produced `\d d` instead of `\delta`.
- The regexps built from `fastmath-operators-key` and `fastmath-sumlike-key`
  were `defconst`s computed at load time, so customizing those options had no
  effect.
- The mode menu was named `projectile-mode-menu`.
- `fastmath-mode` made `post-self-insert-hook` buffer-local for every buffer
  instead of adding its function locally.

## 0.1.0 - 2020-04-30

The proof of concept, never tagged (its package header said `1.0-snapshot`):
`fastmath-mode`, `fastmath-toggle-inline`, symbol abbreviations, fractions, integrals, sum-like operators, partial derivatives,
dot products, math fonts, single-argument operators, differentials, doubled
letters for greek and subscripts/superscripts of up to five characters.
