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
