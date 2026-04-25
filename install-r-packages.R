#!/usr/bin/env Rscript

# R package installation script for CI environment
# This script installs packages from renv.lock files in source repositories


# Default CRAN mirror used when no mirror is configured
CRAN_MIRROR <- Sys.getenv("CRAN_MIRROR", "https://cloud.r-project.org")


# Ensure a usable CRAN entry exists in a repos vector; fall back to CRAN_MIRROR
ensure_cran_repos <- function(repos = getOption("repos")) {
  if (is.null(repos) || length(repos) == 0) repos <- character()
  cran_url <- NULL
  if (length(repos) && !is.null(repos)) cran_url <- repos[["CRAN"]]
  # Treat '@CRAN@' or any string containing '@CRAN' as unset
  invalid <- is.null(cran_url) || !nzchar(cran_url) || (is.character(cran_url) && grepl("@CRAN", cran_url, fixed = TRUE))
  if (invalid) {
    repos <- c(CRAN = CRAN_MIRROR)
  }
  repos
}


# Configuring resilient defaults for network/package installation in CI
configure_install_defaults <- function() {
  options(repos = ensure_cran_repos(getOption("repos")))

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


# Remove a package directory and any compiled libraries for it
remove_package_dir <- function(pkg, lib) {
  pkg_dir <- file.path(lib, pkg)
  if (dir.exists(pkg_dir)) {
    cat("Removing package directory:", pkg_dir, "\n")
    unlink(pkg_dir, recursive = TRUE, force = TRUE)
  }
  libs_dir <- file.path(lib, pkg, "libs")
  if (dir.exists(libs_dir)) {
    cat("Removing compiled libs for:", pkg, "->", libs_dir, "\n")
    unlink(libs_dir, recursive = TRUE, force = TRUE)
  }
}


# Scan an installation library for packages that fail to load due to
# compiled/shared-object problems and remove them so they can be rebuilt.
check_and_remove_broken_packages <- function(lib) {
  inst <- tryCatch(installed.packages(lib.loc = lib), error = function(e) NULL)
  if (is.null(inst) || nrow(inst) == 0) return(invisible(character()))

  broken <- character()
  for (pkg in rownames(inst)) {
    err_msg <- NULL
    ok <- TRUE
    tryCatch({
      requireNamespace(pkg, quietly = TRUE)
    }, error = function(e) {
      ok <<- FALSE
      err_msg <<- conditionMessage(e)
    })

    if (!ok && is_shared_object_load_failure(err_msg)) {
      cat("Detected broken compiled package:", pkg, "->", err_msg, "\n")
      remove_package_dir(pkg, lib)
      broken <- c(broken, pkg)
    }
  }

  invisible(unique(broken))
}


# Ensure a package can be loaded; if not, attempt to install it (with a
# special GitHub fallback for `rlang` which commonly affects lazy-loading).
ensure_package_loaded_or_install <- function(pkg, repos = getOption("repos"), lib = getOption("ci.install.lib", .libPaths()[1])) {
  if (requireNamespace(pkg, quietly = TRUE)) return(TRUE)

  # Remove any on-disk remnants before attempting a clean install
  remove_package_dir(pkg, lib)

  install_single_package(pkg, repos = repos, lib = lib, attempts = 3, allow_repair = TRUE)
  if (requireNamespace(pkg, quietly = TRUE)) return(TRUE)

  # Special-case fallback: try GitHub for rlang if CRAN build keeps failing
  if (identical(pkg, "rlang")) {
    cat("Attempting fallback installation of rlang from GitHub (r-lib/rlang)\n")
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install_packages_safe("remotes", repos = repos, lib = lib)
    }
    if (requireNamespace("remotes", quietly = TRUE)) {
      tryCatch({
        remotes::install_github("r-lib/rlang", upgrade = FALSE, quiet = TRUE)
      }, error = function(e) {
        cat("remotes::install_github fallback for rlang failed:", conditionMessage(e), "\n")
      })
    }
    if (requireNamespace(pkg, quietly = TRUE)) return(TRUE)
  }

  FALSE
}


# Detecting load failures that typically indicate a broken compiled dependency
is_shared_object_load_failure <- function(error_message) {
  if (is.null(error_message) || !nzchar(error_message)) {
    return(FALSE)
  }

  grepl(
    "unable to load shared object|lazy loading failed|undefined symbol",
    error_message,
    ignore.case = TRUE
  )
}


# Extracting package names from shared-object load failures
extract_broken_packages <- function(error_message) {
  if (is.null(error_message) || !nzchar(error_message)) {
    return(character())
  }

  matches <- regmatches(
    error_message,
    gregexpr("/([^/]+)/libs/[^/]+\\.so", error_message, perl = TRUE)
  )[[1]]

  if (!length(matches) || identical(matches, character(0)) || matches[1] == "") {
    return(character())
  }

  unique(sub(".*/([^/]+)/libs/[^/]+\\.so.*", "\\1", matches, perl = TRUE))
}


# Installing a single package with retries and lock cleanup
install_single_package <- function(pkg, repos, lib, attempts = 3L, allow_repair = TRUE) {
  # Ensure repos is valid and contains a CRAN mirror
  repos_local <- ensure_cran_repos(repos)

  for (attempt in seq_len(attempts)) {
    cleanup_library_locks(lib)
    cat(sprintf("Installing %s (attempt %d/%d)\n", pkg, attempt, attempts))

    error_message <- NULL

    tryCatch(
      {
        install.packages(
          pkg,
          repos = repos_local,
          lib = lib,
          quiet = FALSE,
          dependencies = c("Depends", "Imports", "LinkingTo")
        )
      },
      error = function(e) {
        error_message <<- conditionMessage(e)
        cat("Install error for", pkg, ":", error_message, "\n")
      }
    )

    if (requireNamespace(pkg, quietly = TRUE)) {
      return(TRUE)
    }

    if (allow_repair && is_shared_object_load_failure(error_message)) {
      repair_targets <- unique(c(pkg, extract_broken_packages(error_message)))
      if (length(repair_targets)) {
        cat("Repairing package load failure for:", paste(repair_targets, collapse = ", "), "\n")
        for (repair_pkg in repair_targets) {
          cleanup_library_locks(lib)
          pkg_dir <- file.path(lib, repair_pkg)
          if (dir.exists(pkg_dir)) {
            cat("Removing broken package directory before repair:", pkg_dir, "\n")
            unlink(pkg_dir, recursive = TRUE, force = TRUE)
          }
          install_single_package(
            repair_pkg,
            repos = repos,
            lib = lib,
            attempts = max(1L, attempts - 1L),
            allow_repair = FALSE
          )
        }

        if (requireNamespace(pkg, quietly = TRUE)) {
          return(TRUE)
        }
      }
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

  # Normalise repos parameter to ensure a CRAN mirror is always set
  repos <- ensure_cran_repos(repos)

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
      repos = ensure_cran_repos(getOption("repos")),
      lib = getOption("ci.install.lib", .libPaths()[1]),
      quiet = FALSE,
      dependencies = c("Depends", "Imports", "LinkingTo")
    )
  }

  # Parse renv.lock
  lock_data <- jsonlite::fromJSON(lock_file)
  package_names <- names(lock_data$Packages)

  cat("Found", length(package_names), "packages in renv.lock\n")

  # Reinstall packages that are missing or load-failed, not just absent from the library index
  loadable <- vapply(package_names, requireNamespace, logical(1), quietly = TRUE)
  missing <- package_names[!loadable]

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
  critical_packages <- c("knitr", "rmarkdown", "RefManageR", "moments", "gridExtra", "rlang")
  optional_packages <- c("devtools", "tidyverse", "dplyr", "ggplot2", "lmtest", "treemap", "reshape2", "remotes")

  cat("Verifying critical packages for Quarto:", paste(critical_packages, collapse = ", "), "\n")
  cat("Optional packages:", paste(optional_packages, collapse = ", "), "\n")

  missing_critical <- critical_packages[!vapply(critical_packages, requireNamespace, logical(1), quietly = TRUE)]

  if (length(missing_critical) > 0) {
    cat("Installing missing critical packages:", paste(missing_critical, collapse = ", "), "\n")
    bootstrap_packages <- intersect(c("rlang"), missing_critical)
    if (length(bootstrap_packages)) {
      cat("Bootstrapping core dependency packages first:", paste(bootstrap_packages, collapse = ", "), "\n")
      for (pkg in bootstrap_packages) {
        install_single_package(pkg, repos = getOption("repos"), lib = getOption("ci.install.lib", .libPaths()[1]))
      }
    }

    remaining_critical <- setdiff(missing_critical, bootstrap_packages)
    failed <- character()
    if (length(remaining_critical) > 0) {
      failed <- install_packages_safe(remaining_critical)
    }
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

  # Detect and remove any broken compiled packages (e.g., rlang built against
  # a different R ABI) before attempting restores/installs.
  broken_pkgs <- check_and_remove_broken_packages(install_lib)
  if (length(broken_pkgs)) {
    cat("Removed broken packages:", paste(broken_pkgs, collapse = ", "), "\n")
  }

  # Ensure core compiled dependency `rlang` is present and loadable early so
  # packages that lazy-load it do not fail the build.
  if (!ensure_package_loaded_or_install("rlang", repos = getOption("repos"), lib = install_lib)) {
    cat("Warning: could not bootstrap 'rlang' before other installs; continuing and reporting later.\n")
  }

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
