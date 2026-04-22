#!/usr/bin/env Rscript

# R package installation script for CI environment
# This script installs packages from renv.lock files in source repositories


# Configuring resilient defaults for network/package installation in CI
configure_install_defaults <- function() {
  repos <- getOption("repos")
  cran_repo <- repos[["CRAN"]]
  if (is.null(cran_repo) || !nzchar(cran_repo) || identical(cran_repo, "@CRAN")) {
    options(repos = c(CRAN = "https://cloud.r-project.org"))
  }

  timeout <- getOption("timeout")
  if (is.null(timeout) || timeout < 600) {
    options(timeout = 600)
  }

  cpu_count <- 2L
  if (requireNamespace("parallel", quietly = TRUE)) {
    detected <- parallel::detectCores(logical = FALSE)
    if (is.na(detected) || detected < 2) {
      detected <- parallel::detectCores(logical = TRUE)
    }
    if (!is.na(detected) && detected > 1) {
      cpu_count <- max(1L, min(4L, detected - 1L))
    }
  }

  options(Ncpus = cpu_count)
  options(download.file.method = "libcurl")

  cat("Install defaults:\n")
  cat("  CRAN:", getOption("repos")[["CRAN"]], "\n")
  cat("  timeout:", getOption("timeout"), "seconds\n")
  cat("  Ncpus:", getOption("Ncpus"), "\n")
}


# Selecting a writable package library and making it first in .libPaths()
ensure_writable_library <- function() {
  r_libs_user <- Sys.getenv("R_LIBS_USER", "")
  if (nzchar(r_libs_user)) {
    dir.create(r_libs_user, recursive = TRUE, showWarnings = FALSE)
    .libPaths(unique(c(r_libs_user, .libPaths())))
  }

  install_lib <- .libPaths()[1]
  if (file.access(install_lib, mode = 2) != 0) {
    fallback_lib <- file.path(tempdir(), "R-library")
    dir.create(fallback_lib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(fallback_lib, .libPaths()))
    install_lib <- fallback_lib
  }

  cat("Using installation library:", install_lib, "\n")
  install_lib
}


# Removing stale 00LOCK directories left by interrupted installs
cleanup_library_locks <- function(lib) {
  lock_dirs <- Sys.glob(file.path(lib, "00LOCK*"))
  if (length(lock_dirs)) {
    cat("Removing stale package lock directories:", paste(basename(lock_dirs), collapse = ", "), "\n")
    unlink(lock_dirs, recursive = TRUE, force = TRUE)
  }
}


# Installing a single package with retries and lock cleanup
install_single_package <- function(pkg, repos, lib, attempts = 3L) {
  for (attempt in seq_len(attempts)) {
    cleanup_library_locks(lib)
    cat(sprintf("Installing %s (attempt %d/%d)\n", pkg, attempt, attempts))

    tryCatch(
      {
        install.packages(
          pkg,
          repos = repos,
          lib = lib,
          quiet = FALSE,
          dependencies = c("Depends", "Imports", "LinkingTo")
        )
      },
      error = function(e) {
        cat("Install error for", pkg, ":", conditionMessage(e), "\n")
      }
    )

    if (requireNamespace(pkg, quietly = TRUE)) {
      return(TRUE)
    }

    pkg_dir <- file.path(lib, pkg)
    if (dir.exists(pkg_dir)) {
      cat("Removing incomplete package directory before retry:", pkg_dir, "\n")
      unlink(pkg_dir, recursive = TRUE, force = TRUE)
    }
  }

  FALSE
}

# Function to safely install packages
install_packages_safe <- function(
  packages,
  repos = getOption("repos"),
  lib = getOption("ci.install.lib", .libPaths()[1]),
  allow_parallel = TRUE,
  attempts = 3L
) {
  packages <- unique(packages)
  if (!length(packages)) {
    return(invisible(character()))
  }

  cat("Installing", length(packages), "packages:", paste(packages, collapse = ", "), "\n")
  cat("Target library:", lib, "\n")

  cleanup_library_locks(lib)

  failed <- character()
  # Attempt vectorised install first for dependency resolution efficiency
  to_install <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (!length(to_install)) {
    cat("All requested packages already available\n")
    return(invisible(character()))
  }

  if (allow_parallel) {
    batch_attempts <- min(2L, attempts)
  } else {
    batch_attempts <- 1L
  }

  if (batch_attempts > 0) {
    for (attempt in seq_len(batch_attempts)) {
      cleanup_library_locks(lib)
      cat("\n-- Installing missing set (batch attempt", attempt, "of", batch_attempts, "):", paste(to_install, collapse = ", "), "\n")
      tryCatch(
        {
          install.packages(
            to_install,
            repos = repos,
            lib = lib,
            quiet = FALSE,
            Ncpus = if (allow_parallel) getOption("Ncpus", 1L) else 1L,
            dependencies = c("Depends", "Imports", "LinkingTo")
          )
        },
        error = function(e) {
          cat("Batch install encountered an error:", conditionMessage(e), "\n")
        }
      )

      to_install <- to_install[!vapply(to_install, requireNamespace, logical(1), quietly = TRUE)]
      if (!length(to_install)) {
        break
      }
      cat("Still missing after batch attempt", attempt, ":", paste(to_install, collapse = ", "), "\n")
    }
  }

  # Verify & fallback per package where still missing
  for (pkg in to_install) {
    ok <- install_single_package(pkg, repos = repos, lib = lib, attempts = attempts)
    if (!ok || !requireNamespace(pkg, quietly = TRUE)) {
      failed <- c(failed, pkg)
    }
  }

  if (length(failed)) {
    cat("\nPackages still missing after attempts:", paste(failed, collapse = ", "), "\n")
  }

  invisible(failed)
}

# Function to install packages from renv.lock
install_from_renv_lock <- function(lock_file) {
  if (!file.exists(lock_file)) {
    cat("No renv.lock found at:", lock_file, "\n")
    return()
  }

  cat("Processing renv.lock:", lock_file, "\n")

  # Install jsonlite first if needed for parsing
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    install.packages(
      "jsonlite",
      repos = getOption("repos"),
      lib = getOption("ci.install.lib", .libPaths()[1]),
      quiet = FALSE,
      dependencies = c("Depends", "Imports", "LinkingTo")
    )
  }

  # Parse renv.lock
  lock_data <- jsonlite::fromJSON(lock_file)
  package_names <- names(lock_data$Packages)

  cat("Found", length(package_names), "packages in renv.lock\n")

  # Get currently installed packages
  installed <- rownames(installed.packages())
  missing <- setdiff(package_names, installed)

  if (length(missing) > 0) {
    cat("Installing", length(missing), "missing packages\n")
    failed <- install_packages_safe(missing)
    if (length(failed)) {
      cat("Warning: some packages from", lock_file, "failed to install:", paste(failed, collapse = ", "), "\n")
    }
  } else {
    cat("All packages from renv.lock are already installed\n")
  }
}

# Function to ensure critical packages are available
ensure_critical_packages <- function() {
  # Add RefManageR (bibliography), treat as critical for render
  critical_packages <- c("knitr", "rmarkdown", "RefManageR", "moments", "gridExtra", "tidyverse", "dplyr", "ggplot2", "lmtest", "treemap", "reshape2", "remotes")
  optional_packages <- c("devtools")

  cat("Verifying critical packages for Quarto:", paste(critical_packages, collapse = ", "), "\n")
  cat("Optional packages:", paste(optional_packages, collapse = ", "), "\n")

  missing_critical <- critical_packages[!vapply(critical_packages, requireNamespace, logical(1), quietly = TRUE)]

  if (length(missing_critical) > 0) {
    cat("Installing missing critical packages:", paste(missing_critical, collapse = ", "), "\n")
    failed <- install_packages_safe(missing_critical)
    # Report any failed critical installs
    if (length(failed)) {
      cat("Warning: failed to install critical packages:", paste(failed, collapse = ", "), "\n")
    }

    # Verify again
    still_missing <- critical_packages[!vapply(critical_packages, requireNamespace, logical(1), quietly = TRUE)]

    if (length(still_missing) > 0) {
      stop("Failed to install critical packages: ", paste(still_missing, collapse = ", "))
    }
  }

  missing_optional <- optional_packages[!vapply(optional_packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_optional) > 0) {
    cat("Installing missing optional packages:", paste(missing_optional, collapse = ", "), "\n")
    optional_failed <- install_packages_safe(missing_optional)
    if (length(optional_failed)) {
      cat("Warning: optional packages still missing:", paste(optional_failed, collapse = ", "), "\n")
    }
  }

  # Report versions
  cat("Critical package versions:\n")
  for (pkg in critical_packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat(pkg, ":", as.character(utils::packageVersion(pkg)), "\n")
    } else {
      cat(pkg, ": (missing)\n")
    }
  }
}


# Adding helper to install GitHub packages with fallback tarball support
install_github_from_tarball <- function(repo, package, ref = NULL) {
  fallback_ref <- if (is.null(ref) || !nzchar(ref)) "main" else ref
  tarball_url <- sprintf("https://github.com/%s/archive/refs/heads/%s.tar.gz", repo, fallback_ref)
  dest <- tempfile(pattern = "githubpkg-", fileext = ".tar.gz")
  on.exit(unlink(dest), add = TRUE)

  cat("Downloading fallback tarball for", package, "from", tarball_url, "\n")

  ok <- TRUE
  tryCatch(
    {
      utils::download.file(tarball_url, dest, mode = "wb", quiet = TRUE)
      install.packages(dest, repos = NULL, type = "source", quiet = TRUE)
    },
    error = function(e) {
      ok <<- FALSE

      # Reporting tarball failure for diagnostics
      cat("Fallback tarball install failed for", package, ":", e$message, "\n")
    }
  )

  ok && requireNamespace(package, quietly = TRUE)
}


install_github_package <- function(repo, package = basename(repo), ref = NULL) {
  if (requireNamespace(package, quietly = TRUE)) {
    cat("GitHub package", package, "already installed\n")
    return(invisible(TRUE))
  }

  cat("Installing GitHub package", package, "from", repo, "\n")

  if (!requireNamespace("remotes", quietly = TRUE)) {

    # Installing remotes so install_github is available
    install_packages_safe("remotes")
  }

  if (!requireNamespace("remotes", quietly = TRUE)) {
    stop("Unable to load remotes required for GitHub package installs")
  }

  args <- list(repo = repo, quiet = TRUE)
  if (!is.null(ref)) {
    args$ref <- ref
  }

  ok <- TRUE
  err_message <- NULL
  tryCatch(
    {
      do.call(remotes::install_github, args)
    },
    error = function(e) {
      ok <<- FALSE
      err_message <<- conditionMessage(e)
      cat("Failed to install", package, "from", repo, ":", err_message, "\n")
    }
  )

  if (!ok || !requireNamespace(package, quietly = TRUE)) {
    if (!is.null(err_message) && grepl("HTTP error 401|Bad credentials", err_message, ignore.case = TRUE)) {
      cat("GitHub authentication failed; attempting anonymous tarball install\n")
      ok <- install_github_from_tarball(repo, package, ref)
    }
  }

  if (!ok || !requireNamespace(package, quietly = TRUE)) {
    stop(paste("Failed to install GitHub package:", package))
  }

  invisible(TRUE)
}


# Ensuring GitHub packages for course materials are installed
ensure_github_packages <- function() {
  github_packages <- list(
    list(repo = "DrBenjamin/ourdata", package = "ourdata")
  )

  for (pkg in github_packages) {
    install_github_package(pkg$repo, pkg$package)
  }
}

# Main execution
main <- function() {
  cat("=== R Package Installation Script ===\n")
  cat("R version:", R.version.string, "\n")

  configure_install_defaults()
  install_lib <- ensure_writable_library()
  options(ci.install.lib = install_lib)
  cleanup_library_locks(install_lib)

  cat("Library paths:\n")
  cat(paste("  -", .libPaths()), sep = "\n")
  cat("\n")

  # Process command line arguments
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    cat("Usage: Rscript install-r-packages.R <lock_file1> [lock_file2] ...\n")
    cat("Or set environment variable RENV_LOCK_FILES with space-separated paths\n")

    # Try environment variable
    env_files <- Sys.getenv("RENV_LOCK_FILES", "")
    if (env_files != "") {
      args <- unlist(strsplit(env_files, " "))
    }
  }

  # Install packages from each renv.lock file
  for (lock_file in args) {
    # If renv is available, prefer to perform a full renv::restore() in the
    # project directory that contains the lockfile. This restores package
    # library state deterministically rather than installing ad-hoc.
    project_dir <- dirname(lock_file)
    if (!project_dir %in% c("", ".") && file.exists(lock_file)) {
      cat("Attempting renv restore in project:", project_dir, "\n")
      # Ensure the R library path requested by CI (R_LIBS_USER) is present
      r_libs_user <- Sys.getenv("R_LIBS_USER", unset = "")
      if (nzchar(r_libs_user) && !r_libs_user %in% .libPaths()) {
        cat("Adding R_LIBS_USER to .libPaths():", r_libs_user, "\n")
        .libPaths(c(r_libs_user, .libPaths()))
      }

      # Attempt to use renv::restore() for deterministic restore. If renv is
      # missing, bootstrap it first (renv::hydrate/renv::restore will install
      # renv automatically when using the bootstrap script but we'll be explicit).
      tryCatch(
        {
          if (!requireNamespace("renv", quietly = TRUE)) {
            install_packages_safe("renv", allow_parallel = FALSE)
          }

          # Run restore in the project directory so that renv uses the correct lockfile
          old_wd <- getwd()
          on.exit(setwd(old_wd), add = TRUE)
          setwd(project_dir)
          renv::restore(lockfile = basename(lock_file), prompt = FALSE)
          cat("renv::restore completed for", project_dir, "\n")
        },
        error = function(e) {
          cat("renv::restore failed for", project_dir, "- falling back to individual installs.\n")
          cat("  error:", conditionMessage(e), "\n")
          # Fallback to parsing lockfile and installing packages individually
          install_from_renv_lock(lock_file)
        }
      )
    } else {
      install_from_renv_lock(lock_file)
    }
  }

  # Ensure critical packages are available
  ensure_critical_packages()

  # Ensuring GitHub packages are installed
  ensure_github_packages()

  cat("=== Package installation complete ===\n")
}

# Run main function
if (!interactive()) {
  main()
}
