# Project .Rprofile
# Keeping this minimal: session watcher should be started from the *user* ~/.Rprofile.
# This file exists to avoid accidental overrides and can host project-specific options.

# Adding project-specific options (example):
# options(stringsAsFactors = FALSE)

# Adding a lightweight check to inform if user-level watcher not active
if (interactive() && Sys.getenv("RSTUDIO") == "" && Sys.getenv("TERM_PROGRAM") == "vscode") {
  if (!any(grepl("tools:vscode", search(), fixed = TRUE))) {
    user_init <- file.path(Sys.getenv(if (.Platform$OS.type == "windows") "USERPROFILE" else "HOME"), ".vscode-R", "init.R")
    if (file.exists(user_init)) {
      message("(Project .Rprofile) Attempting to source user VS Code watcher init file...")
      try(local(source(user_init, chdir = TRUE, local = TRUE)), silent = TRUE)
      if (!any(grepl("tools:vscode", search(), fixed = TRUE))) {
        message("(Project .Rprofile) Sourcing did not attach tools:vscode. Check required packages (jsonlite, rlang) and extension path.")
      }
    } else {
      message("(Project .Rprofile) VS Code session watcher not yet attached and user init missing: " , user_init)
    }
  }
}

# --- Begin radian configuration (appended) ---
if (interactive()) {
  # Only proceed if we're inside radian (it sets RADIAN_VERSION)
  if (!is.null(Sys.getenv("RADIAN_VERSION", unset = NA))) {
    current_opts <- options()

    safe_set <- function(name, value) {
      if (is.null(current_opts[[name]])) {
        options(structure(list(value), names = name))
      }
    }

    # Core requested feature: automatic bracket/quote matching
    safe_set("radian.auto_match", TRUE)

    # Additional quality-of-life defaults (comment out any you don't want)
    safe_set("radian.insert_new_line", TRUE)
    safe_set("radian.color_scheme", "native")
    safe_set("radian.highlight_matching_bracket", TRUE)

    # Console friendliness / nicer printing
    safe_set("tibble.print_min", 6)
    safe_set("tibble.width", Inf)
    if (getOption("scipen", 0) < 6) options(scipen = 6)

    # reticulate: prefer project conda env python if not already pinned
    if (is.null(Sys.getenv("RETICULATE_PYTHON", unset = NULL))) {
      py_bin <- file.path(Sys.getenv("HOME"), "conda/envs/r-reticulate/bin/python")
      if (file.exists(py_bin)) Sys.setenv(RETICULATE_PYTHON = py_bin)
    }

    rm(safe_set, current_opts)
  }
}
# --- End radian configuration ---
