#!/usr/bin/env Rscript

# R package installation script for CI environment
# This script installs packages from renv.lock files in source repositories

# Function to safely install packages 
install_packages_safe <- function(packages, repos = "https://cloud.r-project.org") {
  cat("Installing", length(packages), "packages:", paste(packages, collapse = ", "), "\n")
  
  for (pkg in packages) {
    tryCatch({
      if (!requireNamespace(pkg, quietly = TRUE)) {
        cat("Installing package:", pkg, "\n")
        install.packages(pkg, repos = repos, quiet = TRUE)
      } else {
        cat("Package", pkg, "already available\n")
      }
    }, error = function(e) {
      cat("Failed to install", pkg, ":", e$message, "\n")
    })
  }
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
    install_packages_safe(missing)
  } else {
    cat("All packages from renv.lock are already installed\n")
  }
}

# Function to ensure critical packages are available
ensure_critical_packages <- function() {
  critical_packages <- c("knitr", "rmarkdown")
  cat("Verifying critical packages for Quarto:", paste(critical_packages, collapse = ", "), "\n")
  
  missing_critical <- critical_packages[!sapply(critical_packages, function(pkg) {
    requireNamespace(pkg, quietly = TRUE)
  })]
  
  if (length(missing_critical) > 0) {
    cat("Installing missing critical packages:", paste(missing_critical, collapse = ", "), "\n")
    install_packages_safe(missing_critical)
    
    # Verify again
    still_missing <- critical_packages[!sapply(critical_packages, function(pkg) {
      requireNamespace(pkg, quietly = TRUE)
    })]
    
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
    install_from_renv_lock(lock_file)
  }
  
  # Ensure critical packages are available
  ensure_critical_packages()
  
  cat("=== Package installation complete ===\n")
}

# Run main function
if (!interactive()) {
  main()
}