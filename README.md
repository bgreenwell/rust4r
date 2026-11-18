# Rust for R Programmers

A book that teaches standalone Rust to R programmers by pairing each Rust concept with the R idea it most resembles.

> **Rough draft.** Nothing in this book has been peer-reviewed, and chapters may change substantially. The code output is real, because every example runs when the book is built, but the explanations may still contain mistakes.

Read it online at <https://bgreenwell.github.io/rust4r/>, or download the [PDF](https://bgreenwell.github.io/rust4r/Rust-for-R-Programmers.pdf).

## Contents

- **Part I:** vectors, types, strings, and missing values.
- **Part II:** S3, S4, and S7 next to structs, traits, generics, and enums, built around one running example, a probability distribution.
- **Part III:** copy-on-modify and ownership, borrowing, environments, and cleanup with `Drop`.
- **Part IV:** the apply family and iterators, closures, errors, and macros.
- **Part V:** collections, files, crates, command-line programs, and concurrency, ending with `rsummary`, a tool that reproduces `summary()` and `table()`.
- **Chapter 30:** calling Rust from R, by hand with `.Call()` and with extendr.

## Building the book

The book is a [Quarto](https://quarto.org) project. Every R and Rust example runs during the build, so building it needs:

- Quarto
- R, with the knitr, rmarkdown, S7, rextendr, usethis, and devtools packages
- Rust 1.85 or later, installed with [rustup](https://rustup.rs)
- TinyTeX for the PDF (`quarto install tinytex`)

Then, from this folder:

```sh
quarto render
```

Quarto reuses the saved results in `_freeze/` for chapters that haven't changed. Delete `_freeze/` to run every example again. The first full build downloads the crates the examples use, so it needs a network connection.

## Development

`_common.R` holds the knitr engine that runs the Rust examples, with its chunk options described at the top of the file. Each push to `main` publishes the book, HTML and PDF, to GitHub Pages from the committed `_freeze/` results. `_freeze/` keeps separate results for each format, and rendering one chapter refreshes only the format you render, so run a full `quarto render` before pushing and commit `_freeze/` along with the source.

To report a mistake or suggest a change, see [CONTRIBUTING.md](CONTRIBUTING.md), which covers issues, small fixes, building the book, and its conventions.

## License

The text is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) and the code under the MIT License. [LICENSE.md](LICENSE.md) says which files each covers.
