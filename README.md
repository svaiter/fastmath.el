[![License GPL 3](https://img.shields.io/badge/license-GPL_3-green.svg)](http://www.gnu.org/licenses/gpl-3.0.txt)
[![Build Status](https://github.com/svaiter/fastmath.el/workflows/CI/badge.svg)](https://github.com/svaiter/fastmath.el/actions)

# Fastmath

Fastmath is an Emacs minor mode to quickly input math when using (La)TeX syntax,
beyond what abbrev-mode and LaTeX-math-mode offer.

Major features include:
- Fast insertion of complex operators (fractions, integrals, sums, derivatives)
- Latin and greek alphabets everywhere, typed as doubled letters or Unicode
- Quickly toggle inline/display math
- Integrates with yasnippet (optional)

For instance, typing

    i n t 0 a SPC SPC f(x) SPC dx SPC

in a math environment results in

    \int_{0}^{a} f(x) \mathrm{d}x

If you prefer `\d x` (a custom macro), see [Customization](#customization).

In action:

![Fastmath Screenshot](gifs/demo-fastmath.gif)

Fastmath is opinionated: it grew out of the author's configuration, AUCTeX's
LaTeX-math-mode, CDLaTeX and ideas borrowed from
[this](https://castel.dev/post/lecture-notes-1/) blog post.

## How it works

With `fastmath-mode` enabled, type a short *word* inside math mode and press
`SPC`. If the word matches one of the [expansion rules](#expansions), it is
replaced by LaTeX and the space is consumed; otherwise the space is inserted as
usual. A second `SPC` inserts a normal space.

| You type              | You get                     |
|-----------------------|-----------------------------|
| `xi SPC`              | `x_{i}`                     |
| `xi SPC SPC`          | `x_{i} `                    |
| `hello SPC`           | `h_{e,\lambda,o}` (`ll` is greek, see [Atoms](#atoms)) |
| `C-q SPC`             | a literal space, always     |
| `M-x fastmath-interrupt`, then `SPC` | a literal space |
| `M-x fastmath-expand` | expands the word before point without typing a space |

Math mode is detected with `texmathp` from AUCTeX (see
`fastmath-math-predicate`). Outside math, `SPC` is just a space.

## Installation

Fastmath is not on MELPA yet. Clone the repository and load it from there:

```elisp
(use-package fastmath
  :load-path "~/src/fastmath.el"
  :hook (LaTeX-mode . fastmath-mode))
```

With Emacs 30 (or the `vc-use-package` package) you can let `use-package`
clone it for you:

```elisp
(use-package fastmath
  :vc (:url "https://github.com/svaiter/fastmath.el" :rev :newest)
  :hook (LaTeX-mode . fastmath-mode))
```

Without `use-package`, add the directory to `load-path` and enable the mode in
LaTeX buffers:

```elisp
(add-to-list 'load-path "~/src/fastmath.el")
(autoload 'fastmath-mode "fastmath" nil t)
(add-hook 'LaTeX-mode-hook #'fastmath-mode)
```

`M-x fastmath-mode` toggles it in the current buffer.

### Requirements

- GNU Emacs 27.1 or later.
- [AUCTeX](https://www.gnu.org/software/auctex/) 12.2 or later, for `texmathp`
  (math mode detection) and `fastmath-toggle-inline`.
- [yasnippet](https://github.com/joaotavora/yasnippet) 0.14 or later,
  **optional**. The few snippet-like expansions (`lp`, `//`, `fx`, ...) use
  yasnippet fields when `yas-minor-mode` is on in the buffer. Otherwise the
  snippet text is inserted as is, with empty fields, and point is left at the
  first field: `lp SPC` gives `\left(  \right)` with point between the
  delimiters.

## Expansions

Every rule below is tried in order on the word before point; the first one that
applies wins. The list lives in `fastmath-rules`.

A word starts after whitespace, at the beginning of the line, or after one of
`$ { } ( ) [ ] = + - , ^ _ & |`, so `x=aa SPC` gives `x=\alpha` and `x_aa SPC`
gives `x_\alpha`.

### Atoms

Wherever a rule takes a letter, it accepts an *atom*:

| Atom                                   | Example | LaTeX     |
|----------------------------------------|---------|-----------|
| a latin letter                         | `x`     | `x`       |
| a digit                                | `3`     | `3`       |
| a doubled latin letter (greek)         | `aa`    | `\alpha`  |
| a Unicode greek letter                 | `α`     | `\alpha`  |

Words are read greedily from left to right: `xxi` is `\xi_{i}`, not
`x_{x,i}`. A doubled letter with no greek counterpart is two latin letters:
`cc` gives `c_{c}`.

Doubled letters map to greek through `fastmath-greek-alist`:

| Type | LaTeX       | Type | LaTeX       | Type | LaTeX       |
|------|-------------|------|-------------|------|-------------|
| `aa` | `\alpha`    | `ii` | `\iota`     | `ss` | `\sigma`    |
| `bb` | `\beta`     | `kk` | `\kappa`    | `tt` | `\tau`      |
| `gg` | `\gamma`    | `ll` | `\lambda`   | `uu` | `\upsilon`  |
| `dd` | `\delta`    | `mm` | `\mu`       | `ff` | `\phi`      |
| `ee` | `\epsilon`  | `nn` | `\nu`       | `qq` | `\chi`      |
| `zz` | `\zeta`     | `xx` | `\xi`       | `yy` | `\psi`      |
| `hh` | `\eta`      | `pp` | `\pi`       | `ww` | `\omega`    |
| `jj` | `\theta`    | `rr` | `\rho`      |      |             |

| Type | LaTeX       | Type | LaTeX       | Type | LaTeX       |
|------|-------------|------|-------------|------|-------------|
| `GG` | `\Gamma`    | `XX` | `\Xi`       | `FF` | `\Phi`      |
| `DD` | `\Delta`    | `PP` | `\Pi`       | `YY` | `\Psi`      |
| `JJ` | `\Theta`    | `SS` | `\Sigma`    | `WW` | `\Omega`    |
| `LL` | `\Lambda`   | `UU` | `\Upsilon`  |      |             |

Unicode greek letters (typed for instance with the `TeX` input method, `C-\`)
map by name through `fastmath-unicode-greek-alist`: `α` ... `ω` and `Γ` ...
`Ω` give `\alpha` ... `\omega` and `\Gamma` ... `\Omega`, with these
special cases:

| Type                                                    | LaTeX                |
|---------------------------------------------------------|----------------------|
| `ϵ`, `ϕ`, `ϑ`, `ϱ`, `ϖ`, `ϰ`, `ς`                       | `\varepsilon`, `\varphi`, `\vartheta`, `\varrho`, `\varpi`, `\varkappa`, `\varsigma` |
| `Α Β Ε Ζ Η Ι Κ Μ Ν Ο Ρ Τ Χ` (capitals LaTeX renders in latin) | `A B E Z H I K M N O P T X` |
| `ο` (omicron)                                           | `o`                  |

So `α SPC` gives `\alpha`, `xα` gives `x_{\alpha}`, `ϵ6j` gives
`\varepsilon^{j}` and `Αi` gives `A_{i}`.

### Subscripts and superscripts

This is the last rule, the one that applies when nothing else does. A word is a
head atom, followed by subscript atoms, followed optionally by `6` (`^` on a
US keyboard) and superscript atoms. Atoms are joined by commas. The head must
be a letter; a single latin letter is left alone.

| Type    | LaTeX            |
|---------|------------------|
| `xi`    | `x_{i}`          |
| `xij`   | `x_{i,j}`        |
| `x1i`   | `x_{1,i}`        |
| `xaa`   | `x_{\alpha}`     |
| `x6i`   | `x^{i}`          |
| `x6ij`  | `x^{i,j}`        |
| `x62`   | `x^{2}`          |
| `xi63`  | `x_{i}^{3}`      |
| `xi6jk` | `x_{i}^{j,k}`    |
| `x6`    | `x_{6}`          |
| `aa`    | `\alpha`         |
| `aai`   | `\alpha_{i}`     |
| `aai6j` | `\alpha_{i}^{j}` |
| `x`     | not expanded     |
| `12`    | not expanded     |

### Symbol abbreviations

Rule 1. The keys of `fastmath-symbol-abbrevs` are matched literally and
**a space is inserted after the expansion** (`!= SPC` gives `\neq `), since a
symbol is almost always followed by something else.

| Type   | LaTeX        | Type   | LaTeX         | Type   | LaTeX           |
|--------|--------------|--------|---------------|--------|-----------------|
| `!=`   | `\neq`       | `+-`   | `\pm`         | `;c`   | `\subset`       |
| `!<`   | `\nless`     | `-+`   | `\mp`         | `;C`   | `\supset`       |
| `!>`   | `\ngtr`      | `;x`   | `\times`      | `c=`   | `\subseteq`     |
| `!<=`  | `\nleq`      | `;.`   | `\cdot`       | `=c`   | `\supseteq`     |
| `!>=`  | `\ngeq`      | `;u`   | `\cup`        | `!c=`  | `\nsubseteq`    |
| `!;`   | `\not`       | `;U`   | `\cap`        | `!=c`  | `\nsupseteq`    |
| `!;!3` | `\not\in`    | `--`   | `\setminus`   | `->`   | `\to`           |
| `!;e`  | `\not\exists`| `;0`   | `\emptyset`   | `<-`   | `\gets`         |
| `<=`   | `\leq`       | `;v`   | `\forall`     | `\|>`  | `\mapsto`       |
| `>=`   | `\geq`       | `;e`   | `\exists`     | `.=>`  | `\implies`      |
| `==`   | `\equiv`     | `;e!`  | `\exists!`    | `.<=`  | `\impliedby`    |
| `~~`   | `\sim`       | `;3`   | `\in`         | `.<=>` | `\iff`          |
| `~=`   | `\approx`    | `;t`   | `\top`        | `62`   | `^{2}`          |
| `8=`   | `\propto`    | `;T`   | `\bot`        | `63`   | `^{3}`          |
| `;8`   | `\infty`     | `;d`   | `\partial`    | `lll`  | `\ell`          |
| `dint` | `\int_{-\infty}^{+\infty}` | `;V` | `\nabla` | |                  |

Unicode symbols typed with an input method are accepted too:

| Type | LaTeX        | Type | LaTeX       | Type | LaTeX        |
|------|--------------|------|-------------|------|--------------|
| `∞`  | `\infty`     | `≤`  | `\leq`      | `∅`  | `\emptyset`  |
| `∂`  | `\partial`   | `≥`  | `\geq`      | `⊂`  | `\subset`    |
| `∇`  | `\nabla`     | `≠`  | `\neq`      | `⊆`  | `\subseteq`  |
| `∈`  | `\in`        | `→`  | `\to`       | `∪`  | `\cup`       |
| `∉`  | `\notin`     | `∀`  | `\forall`   | `∩`  | `\cap`       |
| `×`  | `\times`     | `∃`  | `\exists`   | `±`  | `\pm`        |

### Parentheses

Rule 2. Snippets: with yasnippet, `TAB` jumps out of the delimiters.

| Type   | Snippet                 | Option                       |
|--------|-------------------------|------------------------------|
| `lp`   | `\left( $1 \right)$0`   | `fastmath-parenthesis-snippet` |
| `lpb`  | `\left\{ $1 \right\}$0` | `fastmath-braces-snippet`    |
| `lpbr` | `\left[ $1 \right]$0`   | `fastmath-brackets-snippet`  |

### Fractions

Rule 3. `//` followed by nothing is a snippet, by one atom the inverse of that
atom, by two atoms their quotient. Three or more atoms are left alone.

| Type     | LaTeX                        |
|----------|------------------------------|
| `//`     | `\frac{$1}{$2}$0` (snippet, `fastmath-fraction-snippet`) |
| `m//`    | multi-line `\frac` snippet (`fastmath-fraction-multiline-snippet`) |
| `//2`    | `\frac{1}{2}`                |
| `//a`    | `\frac{1}{a}`                |
| `//ab`   | `\frac{a}{b}`                |
| `//3a`   | `\frac{3}{a}`                |
| `//aab`  | `\frac{\alpha}{b}`           |
| `//aabb` | `\frac{\alpha}{\beta}`       |
| `//αβ`   | `\frac{\alpha}{\beta}`       |
| `//123`  | not expanded                 |

Expansion works inside snippet fields: `// SPC aa SPC TAB b TAB` gives
`\frac{\alpha}{b}`.

### Integrals

Rule 4. `int`, then an optional lower bound and an optional upper bound. A
lower bound `R` is the blackboard bold `R` and the atom after it is its
exponent.

| Type     | LaTeX                    |
|----------|--------------------------|
| `int`    | `\int`                   |
| `int0`   | `\int_{0}`               |
| `int0a`  | `\int_{0}^{a}`           |
| `intab`  | `\int_{a}^{b}`           |
| `intWW`  | `\int_{\Omega}`          |
| `int0WW` | `\int_{0}^{\Omega}`      |
| `intaab` | `\int_{\alpha}^{b}`      |
| `intR`   | `\int_{\mathbb{R}}`      |
| `intR3`  | `\int_{\mathbb{R}^{3}}`  |
| `intRn`  | `\int_{\mathbb{R}^{n}}`  |
| `dint`   | `\int_{-\infty}^{+\infty}` (symbol abbreviation) |

### Sum-like operators

Rule 5. A key of `fastmath-sumlike-key` (`sum`, `prod`, `cup` for `\bigcup`,
`cap` for `\bigcap`), then an index (a letter), then either an end bound or a
start and an end bound.

| Type      | LaTeX                   |
|-----------|-------------------------|
| `sum`     | `\sum`                  |
| `sumi`    | `\sum_{i}`              |
| `sumin`   | `\sum_{i=1}^{n}`        |
| `sumi3n`  | `\sum_{i=3}^{n}`        |
| `sumk0n`  | `\sum_{k=0}^{n}`        |
| `sumaa`   | `\sum_{\alpha}`         |
| `sumi0WW` | `\sum_{i=0}^{\Omega}`   |
| `prod`    | `\prod`                 |
| `prodk`   | `\prod_{k}`             |
| `prodin`  | `\prod_{i=1}^{n}`       |
| `cupi`    | `\bigcup_{i}`           |
| `capin`   | `\bigcap_{i=1}^{n}`     |

### Partial derivatives and dot products

Rule 6. `pd` or `dp` followed by two letter atoms.

| Type    | LaTeX                                  |
|---------|----------------------------------------|
| `pdfx`  | `\frac{\partial f}{\partial x}`        |
| `pdfaa` | `\frac{\partial f}{\partial \alpha}`   |
| `dpxy`  | `\langle x, y \rangle`                 |
| `dpaab` | `\langle \alpha, b \rangle`            |

The dot product format is `fastmath-dot-product-format`.

### Functions

Rule 7. `fx` inserts the snippet `$1 : $2 \to $0` (`fastmath-function-snippet`):
`fx SPC f TAB X TAB Y` gives `f : X \to Y`.

### Math fonts

Rule 8. A prefix of `fastmath-mathfont-alist` followed by an upper-case letter,
then optional subscripts and superscripts as above.

| Type   | LaTeX             |
|--------|-------------------|
| `bR`   | `\mathbb{R}`      |
| `bN`   | `\mathbb{N}`      |
| `bRn`  | `\mathbb{R}_{n}`  |
| `bR6n` | `\mathbb{R}^{n}`  |
| `bR63` | `\mathbb{R}^{3}`  |
| `cA`   | `\mathcal{A}`     |
| `cAi`  | `\mathcal{A}_{i}` |
| `bx`   | `b_{x}` (lower-case letter: plain subscript) |

### Single-argument operators

Rule 9. A key of `fastmath-operators-key` followed by a letter atom, then
optional subscripts and superscripts. The longest key wins (`wha` before `ha`).

| Key   | Macro       | Example  | LaTeX              |
|-------|-------------|----------|--------------------|
| `ha`  | `\hat`      | `hax`    | `\hat{x}`          |
| `wha` | `\widehat`  | `whax`   | `\widehat{x}`      |
| `ba`  | `\bar`      | `bay`    | `\bar{y}`          |
| `wba` | `\overline` | `wbax`   | `\overline{x}`     |
| `ve`  | `\vec`      | `vev`    | `\vec{v}`          |
| `ti`  | `\tilde`    | `tiy`    | `\tilde{y}`        |
| `bm`  | `\bm`       | `bmv`    | `\bm{v}`           |
|       |             | `haaa`   | `\hat{\alpha}`     |
|       |             | `haxi`   | `\hat{x}_{i}`      |
|       |             | `haxi6j` | `\hat{x}_{i}^{j}`  |

### Differentials

Rule 10. `d` followed by one letter atom (`fastmath-differential-format`).

| Type  | LaTeX                |
|-------|----------------------|
| `dx`  | `\mathrm{d}x`        |
| `dt`  | `\mathrm{d}t`        |
| `daa` | `\mathrm{d}\alpha`   |
| `dα`  | `\mathrm{d}\alpha`   |
| `dd`  | `\delta` (greek wins) |
| `d1`  | `d_{1}`              |
| `dxi` | `d_{x,i}`            |

## Commands

| Command                  | Description |
|--------------------------|-------------|
| `fastmath-mode`          | Toggle the minor mode (lighter ` fm`). |
| `fastmath-expand`        | Expand the word before point now, without typing a space. Works outside math and when `fastmath-expand-on-space` is nil. |
| `fastmath-interrupt`     | Insert the next space typed in math literally. One shot. (`C-q SPC` always inserts a literal space.) |
| `fastmath-toggle-inline` | Toggle the math around point between inline and display math, without prompting. |

`fastmath-toggle-inline` turns `$x$` or `\(x\)` into display math as set by
`fastmath-display-math-style`: `\[ x \]` by default, or an environment on
its own lines (`\begin{equation}`, `x`, `\end{equation}`) when the option
is a string such as `"equation"`. It turns
`\[ x \]`, `$$ x $$` or any math environment known to `texmathp` back into
inline math as set by `fastmath-inline-math-style`: `$x$` by default, or
`\(x\)` with `parens`. Point stays inside the math.

No key is bound by default. The mode map `fastmath-mode-map` also provides a
`Fastmath` menu. A suggested setup:

```elisp
(with-eval-after-load 'fastmath
  (define-key fastmath-mode-map (kbd "C-c C-g t") #'fastmath-toggle-inline)
  (define-key fastmath-mode-map (kbd "C-c C-g e") #'fastmath-expand)
  (define-key fastmath-mode-map (kbd "C-c C-g SPC") #'fastmath-interrupt))
```

## Customization

`M-x customize-group RET fastmath RET` lists every option. Changes made with
`setq` take effect immediately.

| Option                                | Default                               | Description |
|---------------------------------------|---------------------------------------|-------------|
| `fastmath-expand-on-space`            | `t`                                   | Expand when a space is typed in math. When nil, only `fastmath-expand` expands. |
| `fastmath-math-predicate`             | `#'texmathp`                          | Function deciding whether point is in math. |
| `fastmath-greek-alist`                | see [Atoms](#atoms)                   | Latin letter to greek LaTeX, for doubled letters. |
| `fastmath-unicode-greek-alist`        | see [Atoms](#atoms)                   | Unicode greek letter to LaTeX. |
| `fastmath-symbol-abbrevs`             | see [Symbol abbreviations](#symbol-abbreviations) | Literal key to literal LaTeX. |
| `fastmath-operators-key`              | `ha`, `wha`, `ba`, `wba`, `ve`, `ti`, `bm` | Key to single-argument macro name. |
| `fastmath-sumlike-key`                | `sum`, `prod`, `cup`, `cap`           | Key to sum-like macro name. |
| `fastmath-mathfont-alist`             | `(("b" . "\\mathbb{%s}") ("c" . "\\mathcal{%s}"))` | Prefix to a `format` string (the letter is passed twice) or a function of the letter. |
| `fastmath-differential-format`        | `"\\mathrm{d}%s"`                     | `format` string for `dx`. |
| `fastmath-dot-product-format`         | `"\\langle %s, %s \\rangle"`          | `format` string for `dpxy`. |
| `fastmath-display-math-style`         | `brackets`                            | `\[ ... \]`, or a string naming an environment. |
| `fastmath-inline-math-style`          | `dollars`                             | `$...$`, or `parens` for `\( ... \)`. |
| `fastmath-fraction-snippet`           | `"\\frac{$1}{$2}$0"`                  | Snippet for `//`. |
| `fastmath-fraction-multiline-snippet` | `"\\frac{\n  $1\n}{\n  $2\n}$0"`      | Snippet for `m//`. |
| `fastmath-parenthesis-snippet`        | `"\\left( $1 \\right)$0"`             | Snippet for `lp`. |
| `fastmath-braces-snippet`             | `"\\left\\\\{ $1 \\right\\\\}$0"`     | Snippet for `lpb` (backslashes are doubled, as in any yasnippet snippet). |
| `fastmath-brackets-snippet`           | `"\\left[ $1 \\right]$0"`             | Snippet for `lpbr`. |
| `fastmath-function-snippet`           | `"$1 : $2 \\to $0"`                   | Snippet for `fx`. |

The rule list itself, `fastmath-rules`, is an ordered list of `(REGEXP .
HANDLER)` pairs; a handler receives the matched word and returns LaTeX, a
`(snippet . TEXT)` cons, or nil to decline. Adding your own rule is a matter of
pushing a pair onto it.

### The author's setup

The defaults produce standard LaTeX. The author uses a few custom macros
(`\RR`, `\d`, `\dotp`, `\norm`) and restores them with:

```elisp
(setq fastmath-mathfont-alist '(("b" . "\\%s%s")        ; bR -> \RR
                                ("c" . "\\mathcal{%s}"))
      fastmath-differential-format "\\d %s"             ; dx -> \d x
      fastmath-dot-product-format "\\dotp{%s}{%s}")     ; dpxy -> \dotp{x}{y}
(add-to-list 'fastmath-operators-key '("no" . "norm"))  ; nox -> \norm{x}
```

With this, `intR3` gives `\int_{\RR^{3}}`, `bRn` gives `\RR_{n}` and the
example at the top gives `\int_{0}^{a} f(x) \d x`.

## Contributing

Bug reports and feature requests go to the
[GitHub issue tracker](https://github.com/svaiter/fastmath.el/issues).

Please include tests with your pull requests. Fastmath uses ERT: unit tests of
the tokenizer, builders and rule handlers are in `test/fastmath-test.el`,
end-to-end tests typing in a LaTeX buffer are in
`test/fastmath-integration-test.el`. The build needs nothing but Emacs and
`package.el`; dependencies are installed in a repo-local `.elpa/` directory.

    make deps    # install AUCTeX, yasnippet and package-lint
    make test    # run the ERT suite (SELECTOR='"integration"' to filter)
    make lint    # byte-compile with warnings as errors, checkdoc, package-lint

CI runs the tests on Emacs 27.2, 28.2, 29.4 and 30.1 (plus a snapshot build
that may fail), and the linters on 29.4 and 30.1.

## License

Fastmath is distributed under the GNU General Public License, version 3 or
later. See [LICENSE](LICENSE).
