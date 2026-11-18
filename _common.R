# Shared setup, sourced by a hidden setup chunk at the top of every chapter
# that runs code.

# knitr engine for Rust chunks ------------------------------------------------
#
# Each chunk is compiled with rustc and run as its own program; nothing is
# shared between chunks. Conventions:
#
# * A chunk without `fn main()` is wrapped in one.
# * Lines starting with "# " (or a lone "#") are compiled but not shown, the
#   hidden-line convention used by mdBook and rustdoc.
# * Chunk options are written `#| key: value`, not `//|`: knitr parses them
#   with xfun, which does not know Rust's comment syntax.
# * A compile error or a panic stops the render unless the chunk sets
#   `#| error: true`, in which case the compiler or panic message is shown.
#
# Chunks that need crates are built with Cargo instead:
#
# * `#| cargo: true` makes the chunk src/main.rs of a Cargo project whose
#   Cargo.toml and Cargo.lock are copied from cargo/, so only the crates
#   pinned there are available. `#| args: [a, b]` runs the program with those
#   command-line arguments, from the chapter's directory. `#| bin: name`
#   runs it under that name, which programs such as clap print in messages.
# * `#| write: src/stats.rs` adds a file to that project instead of running
#   anything, for the module chunks before a src/main.rs chunk. Written files
#   last until the end of the chapter.
# * `#| cargo: test` runs the tests in the chunk, one at a time so the order
#   is stable, and `#| cargo: clippy` runs the linter, with warnings shown.
#   `#| lints: ["-D clippy::unwrap_used"]` sets lint levels for a clippy
#   chunk, as a [lints] table in Cargo.toml would.
# * `#| cargo: rerun` runs the program from the previous `cargo: true` chunk
#   again with new `args`, without rebuilding; give it `echo: false` and a
#   placeholder comment as its code. A `test` or `clippy` chunk whose code is
#   only a comment checks the project as it stands.
#
# The project and its build output live in R's user cache directory, outside
# the book's folder, so Dropbox doesn't sync them.
#
# `#| save: mean.rs` writes a chunk to that file in the working directory and
# runs nothing, for code that R builds itself (chapter 30, which works in a
# temporary directory).

# Compiler messages can quote the standard library's source; drop the local
# toolchain path so they read `library/core/...` on every machine
rust_src <- file.path(
  system2("rustc", c("--print", "sysroot"), stdout = TRUE),
  "lib", "rustlib", "src", "rust"
)

knitr::knit_engines$set(rust = function(options) {
  code <- options$code
  hidden <- grepl("^#( |$)", code)
  shown <- code[!hidden]
  if (!isTRUE(options$eval)) {
    return(knitr::engine_output(options, shown, ""))
  }
  code[hidden] <- sub("^# ?", "", code[hidden])

  if (!is.null(options$write)) {
    cargo_write(options$write, code)
    return(knitr::engine_output(options, shown, ""))
  }
  if (!is.null(options$save)) {
    dir.create(dirname(options$save), recursive = TRUE, showWarnings = FALSE)
    writeLines(code, options$save)
    return(knitr::engine_output(options, shown, ""))
  }
  # A test, clippy, or rerun chunk with nothing but comments works on the
  # project as the earlier chunks left it, instead of replacing src/main.rs
  if (!is.null(options$cargo) && !isTRUE(options$cargo) &&
      all(grepl("^\\s*(//.*)?$", code))) {
    code <- character()
  }
  if (length(code) && !any(grepl("fn\\s+main\\s*\\(", code))) {
    code <- c("fn main() {", code, "}")
  }

  out <- if (is.null(options$cargo) || isFALSE(options$cargo)) {
    rustc_run(code)
  } else {
    cargo_run(code, options)
  }
  status <- attr(out, "status")
  out <- tidy_rust_output(out)

  if (!is.null(status) && !isTRUE(options$error)) {
    stop("Rust chunk '", options$label, "' failed:\n",
         paste(out, collapse = "\n"), call. = FALSE)
  }
  knitr::engine_output(options, shown, out)
})

exe_name <- function(name) {
  if (.Platform$OS.type == "windows") paste0(name, ".exe") else name
}

# Compile one file with rustc and run it. The result carries a "status"
# attribute when either step fails, as system2() output does.
rustc_run <- function(code) {
  # Work inside a temporary directory so messages refer to `main.rs`, not to
  # a temporary path
  dir <- tempfile("rust")
  dir.create(dir)
  old <- setwd(dir)
  on.exit({
    setwd(old)
    unlink(dir, recursive = TRUE)
  })
  writeLines(code, "main.rs")
  exe <- exe_name("main")

  # system2() warns on a non-zero exit status; it is checked by the engine
  out <- suppressWarnings(system2(
    "rustc",
    c("--edition=2024", "-A", "warnings",
      shQuote(paste0("--remap-path-prefix=", rust_src, "=")),
      "-o", exe, "main.rs"),
    stdout = TRUE, stderr = TRUE
  ))
  # Run the program from the chapter's directory, so relative paths such as
  # data/airquality.csv work
  if (is.null(attr(out, "status"))) {
    setwd(old)
    out <- suppressWarnings(
      system2(file.path(dir, exe), stdout = TRUE, stderr = TRUE)
    )
  }
  out
}

cargo_template <- normalizePath("cargo")
cargo_cache <- tools::R_user_dir("rust4r", which = "cache")
cargo_project <- file.path(cargo_cache, "cargo")

# Start each chapter (each R session) with an empty src/ and the current
# Cargo.toml and Cargo.lock. Copying only changed files keeps Cargo from
# rebuilding the crates.
cargo_reset <- local({
  done <- FALSE
  function() {
    if (done) return(invisible())
    unlink(file.path(cargo_project, "src"), recursive = TRUE)
    dir.create(file.path(cargo_project, "src"), recursive = TRUE)
    for (f in c("Cargo.toml", "Cargo.lock")) {
      from <- file.path(cargo_template, f)
      to <- file.path(cargo_project, f)
      if (!file.exists(to) || tools::md5sum(from) != tools::md5sum(to)) {
        file.copy(from, to, overwrite = TRUE)
      }
    }
    done <<- TRUE
  }
})

cargo_write <- function(path, code) {
  cargo_reset()
  file <- file.path(cargo_project, path)
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  writeLines(code, file)
}

# Run cargo on the project. Clippy gets its own build directory and no
# `-A warnings`, so switching between the two doesn't rebuild every crate.
cargo_command <- function(args, clippy = FALSE, program_args = character()) {
  target <- file.path(cargo_cache, if (clippy) "target-clippy" else "target")
  old <- Sys.getenv(c("CARGO_TARGET_DIR", "RUSTFLAGS"), unset = NA)
  Sys.setenv(CARGO_TARGET_DIR = target,
             RUSTFLAGS = if (clippy) "" else "-A warnings")
  on.exit({
    for (name in names(old)) {
      if (is.na(old[[name]])) Sys.unsetenv(name)
      else do.call(Sys.setenv, as.list(old[name]))
    }
  })
  suppressWarnings(system2(
    "cargo",
    c(args, "--locked", "--manifest-path",
      shQuote(file.path(cargo_project, "Cargo.toml")),
      if (length(program_args)) c("--", program_args)),
    stdout = TRUE, stderr = TRUE
  ))
}

cargo_run <- function(code, options) {
  cargo_reset()
  mode <- if (isTRUE(options$cargo)) "run" else options$cargo
  if (mode == "rerun") return(cargo_exec(options$args, options$bin))
  if (length(code)) writeLines(code, file.path(cargo_project, "src", "main.rs"))

  if (mode == "test") {
    out <- cargo_command("test", program_args = "--test-threads=1")
    status <- attr(out, "status")
    # Drop Cargo's progress lines, which include local paths, and the run time
    out <- out[!grepl("^ +(Compiling|Finished|Running) ", out) &
               !startsWith(out, "error: test failed, to rerun")]
    out <- sub("; finished in [0-9.]+s$", "", out)
    while (length(out) && out[1] == "") out <- out[-1]
    attr(out, "status") <- status
    return(out)
  }
  if (mode == "clippy") {
    # `lints: ["-D clippy::unwrap_used"]` passes lint levels for this crate
    # only, which is what Cargo does with a [lints] table in Cargo.toml, so
    # the messages are the same
    lints <- unlist(strsplit(as.character(unlist(options$lints)), " "))
    out <- cargo_command(c("clippy", "--quiet"), clippy = TRUE,
                         program_args = lints)
    status <- attr(out, "status")
    out <- out[!grepl("^warning: `example` \\(bin", out) &
               !startsWith(out, "error: could not compile `example`")]
    attr(out, "status") <- status
    return(out)
  }

  out <- cargo_command(c("build", "--quiet"))
  if (!is.null(attr(out, "status"))) {
    status <- attr(out, "status")
    out <- out[!startsWith(out, "error: could not compile `example`")]
    attr(out, "status") <- status
    return(out)
  }
  cargo_exec(options$args, options$bin)
}

# Run the program built last, as `cargo run -- args` would. When the chunk
# sets `args`, even to [], the command is shown above the output. A program
# reports its own name from the file it was run as (clap's usage line does),
# so `#| bin: colmean` runs a copy named colmean instead of `example`.
cargo_exec <- function(args, bin = NULL) {
  exe <- file.path(cargo_cache, "target", "debug", exe_name("example"))
  if (!is.null(bin)) {
    dir.create(file.path(cargo_cache, "bin"), showWarnings = FALSE)
    copy <- file.path(cargo_cache, "bin", exe_name(bin))
    # Remove the old copy rather than overwrite it: macOS can kill a program
    # whose file was rewritten in place after it last ran
    unlink(copy)
    file.copy(exe, copy)
    exe <- copy
  }
  show_command <- !is.null(args)
  args <- as.character(unlist(args))
  out <- suppressWarnings(
    system2(exe, shQuote(args), stdout = TRUE, stderr = TRUE)
  )
  if (show_command) {
    status <- attr(out, "status")
    command <- if (length(args)) {
      paste("$ cargo run --", paste(args, collapse = " "))
    } else {
      "$ cargo run"
    }
    out <- c(command, out)
    attr(out, "status") <- status
  }
  out
}

# Panic messages start with a blank line, carry a thread id that changes on
# every run, and end with a hint about backtraces
tidy_rust_output <- function(out) {
  out <- sub("^(thread '[^']*') \\([0-9]+\\)", "\\1", out)
  panic <- grepl("^thread '[^']*' panicked", out)
  blank_before_panic <- out == "" & c(panic[-1], FALSE)
  out[!blank_before_panic &
      !startsWith(out, "note: run with `RUST_BACKTRACE=1`")]
}

# Language labels -------------------------------------------------------------
#
# R and Rust examples follow one another, so each displayed chunk gets a header
# naming its language (Quarto's `filename` option). A chunk that sets its own
# `filename`, such as `src/main.rs`, keeps it.
knitr::opts_hooks$set(engine = function(options) {
  label <- c(r = "R", rust = "Rust")[tolower(options$engine)]
  # A chunk that writes a file is labeled with its path
  if (!is.null(options$write)) label <- options$write
  if (!is.null(options$save)) label <- options$save
  if (is.null(options$filename) && !is.na(label) &&
      !isFALSE(options$echo) && !isFALSE(options$include)) {
    options$filename <- unname(label)
  }
  options
})

# tracemem() output -----------------------------------------------------------
#
# tracemem() reports each copy with the calls active when it was made. At the
# console those are the example's own calls, such as `f` for a copy inside
# f(), but under knitr they also include knitr's evaluation frames, from the
# first `eval` on. Drop those so the output matches the console.
local({
  output <- knitr::knit_hooks$get("output")
  knitr::knit_hooks$set(output = function(x, options) {
    x <- gsub("(tracemem\\[[^]\n]*\\]:(?: (?!eval )\\S+)*) eval [^\n]*", "\\1",
              x, perl = TRUE)
    output(x, options)
  })
})

# knitr splits an R chunk's code after every expression that prints, and
# filters/code-labels.lua joins the pieces back into one labeled block. Keep
# the blank lines at the edges of each piece so the joined code matches the
# chunk as written.
knitr::opts_chunk$set(strip.white = FALSE)
