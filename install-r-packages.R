#!/usr/bin/env Rscript

# R package installation script for CI environment
# This script installs packages from renv.lock files in source repositories

# Function to safely install packages 
install_packages_safe <- function(packages, repos = "https://cloud.r-project.org", allow_parallel = TRUE) {
  packages <- unique(packages)
  if (!length(packages)) return(invisible(character()))

  cat("Installing", length(packages), "packages:", paste(packages, collapse = ", "), "\n")

  failed <- character()
  # Attempt vectorised install first for dependency resolution efficiency
  to_install <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(to_install)) {
    cat("\n-- Installing missing set (batch):", paste(to_install, collapse = ", "), "\n")
    tryCatch({
      install.packages(to_install, repos = repos, quiet = TRUE)
    }, error = function(e) {
      cat("Batch install encountered an error:", e$message, "\nFalling back to per-package installs.\n")
    })
  }

  # Verify & fallback per package where still missing
  for (pkg in to_install) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cat("Retrying individual install:", pkg, "\n")
      ok <- TRUE
      tryCatch({
        install.packages(pkg, repos = repos, quiet = TRUE)
      }, error = function(e) {
        ok <<- FALSE
        cat("Failed to install", pkg, ":", e$message, "\n")
      })
      if (!ok || !requireNamespace(pkg, quietly = TRUE)) failed <- c(failed, pkg)
    } else {
      cat("Package", pkg, "already available after batch\n")
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
    install.packages("jsonlite", repos = "https://cloud.r-project.org", quiet = TRUE)
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
  critical_packages <- c("knitr", "rmarkdown", "RefManageR")
  cat("Verifying critical packages for Quarto:", paste(critical_packages, collapse = ", "), "\n")
  
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

# Main execution
main <- function() {
  cat("=== R Package Installation Script ===\n")
  cat("R version:", R.version.string, "\n")
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
      tryCatch({
        if (!requireNamespace("renv", quietly = TRUE)) {
          install.packages("renv", repos = "https://cloud.r-project.org", quiet = TRUE)
        }

        # Run restore in the project directory so that renv uses the correct lockfile
        old_wd <- getwd()
        on.exit(setwd(old_wd), add = TRUE)
        setwd(project_dir)
        renv::restore(lockfile = basename(lock_file), prompt = FALSE)
        cat("renv::restore completed for", project_dir, "\n")
      }, error = function(e) {
        cat("renv::restore failed for", project_dir, "- falling back to individual installs.\n")
        cat("  error:", conditionMessage(e), "\n")
        # Fallback to parsing lockfile and installing packages individually
        install_from_renv_lock(lock_file)
      })
    } else {
      install_from_renv_lock(lock_file)
    }
  }
  
  # Ensure critical packages are available
  ensure_critical_packages()
  
  cat("=== Package installation complete ===\n")
}

# Run main function
if (!interactive()) {
  main()
}