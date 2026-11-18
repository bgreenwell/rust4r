# License

*Rust for R Programmers* is copyright 2026 Brandon M. Greenwell. It uses two
licenses: one for the text and one for the code.

## Text

The text of the book, in the `.qmd` files and the rendered HTML and PDF, is
licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives
4.0 International License (CC BY-NC-ND 4.0). You may copy and share it,
unchanged and for noncommercial purposes, with credit to the author. The full
legal code is in [LICENSE-TEXT](LICENSE-TEXT), and a summary is at
<https://creativecommons.org/licenses/by-nc-nd/4.0/>.

The same license covers everything else in this repository that isn't listed
below.

## Code

The code is licensed under the MIT License, below. It covers the R and Rust
examples in the book, in its code chunks and code blocks, and the files that
build the book: `_common.R`, `_quarto.yml`, `_quarto-crc.yml`,
`latex/crc-grayscale.tex`, `filters/`, `styles.css`, `cargo/`, and
`.github/`.

## Files with their own terms

- `chicago-author-date.csl` is a copy of Pandoc's default citation style,
  licensed under the Creative Commons Attribution-ShareAlike 3.0 License, as
  the file states.
- `krantz.cls` is CRC Press's LaTeX class for its books, included unchanged
  for the CRC build.
- `latex/crc-preamble.tex` comes from the template at
  <https://github.com/bgreenwell/quarto-crc>, which adapts Yihui Xie's
  bookdown-crc (MIT License).
- `data/airquality.csv` is R's `airquality` data set, written out with
  `write.csv()`. The data come from the New York State Department of
  Conservation and the National Weather Service (see `?airquality` in R).

## MIT License

Copyright (c) 2026 Brandon M. Greenwell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
