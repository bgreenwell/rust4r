# Contributing

Corrections and suggestions are welcome. The book is a draft and still changing, so for anything larger than a small fix, open an issue before writing a pull request.

## Reporting a problem

Open an issue with one of the templates: an error in the book, a typo or layout problem, or a suggestion. The "Report an issue" link on every page of the book leads to them.

- Quote the passage exactly, so it can be found in the source.
- For code, include what you ran, the output you got, and your versions (`rustc --version` and `R.version.string`).

## Small fixes

The "Edit this page" link on every page opens the chapter's `.qmd` file in GitHub's editor, which is the quickest way to fix a typo.

Editing a chapter that has code changes its saved results (see below), which GitHub's editor can't update. That's fine for a pull request: I'll render the chapter and commit its `_freeze/` results when I merge it.

## Building the book

The [README](README.md#building-the-book) lists what a build needs. From the repository's folder:

```sh
quarto render 21-closures.qmd   # one chapter, running its examples again
quarto render                   # the whole book, HTML and PDF
```

Every R and Rust example runs during the build, and an R error or a failing Rust example stops it, so a clean render is the test. The Rust examples run through a knitr engine in `_common.R`, whose chunk options are described at the top of that file.

The publish workflow doesn't run any code. It builds the book from the results saved in `_freeze/`, and it fails if a chapter has changed since its results were saved. If you change a chapter with code, run a full `quarto render`, which saves results for both formats, and commit `_freeze/` along with the source.

## Conventions

- **Pairs.** Each idea comes as an R chunk followed by the Rust chunk that does the same thing. Label chunks `r-<topic>` and `rust-<topic>`.
- **Base R.** R code uses base R only, except S7 in chapter 15 and rextendr, usethis, and devtools in chapter 30.
- **Syntax order.** A Rust example uses only syntax that its chapter or an earlier one teaches. When a later chapter's syntax is unavoidable, add a "Syntax ahead" note, like the one for `print_type()` in chapter 4.
- **Line width.** Keep displayed code lines to 77 characters, the width of the PDF's code box. `rustfmt --edition 2024 --config max_width=77` formats a longer Rust program to fit.
- **Rust chunk options.** Write them as `#|`, not `//|`. A line starting with `# ` is compiled but not shown, for setup repeated from an earlier example. A chunk meant to fail sets `#| error: true`.
- **Claims.** Check what the book says about R or Rust by running it, not from memory.
- **Writing.** Use the Oxford comma and contractions, and don't start a sentence with code.
- **Citations.** Cite in Chicago author-date style from `references.bib`, with section numbers in the locator, as in `[@rustbook, sec. 10.2]`.

## Commits and pull requests

- Write commit messages as [Conventional Commits](https://www.conventionalcommits.org/): a type such as `docs:`, `fix:`, or `ci:`, then a summary in the imperative mood, under 72 characters.
- Branch from `main` and open the pull request against `main`. Pull requests are merged with a merge commit, not squashed.

## License

Contributions are accepted under the book's licenses: text under CC BY-NC-ND 4.0 and code under the MIT License (see [LICENSE.md](LICENSE.md)).
