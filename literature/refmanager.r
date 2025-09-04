# Helper functions for rendering bibliographies with RefManageR in Quarto
#' Render a bibliography file as bullet list (HTML) or LaTeX bibliography (PDF)
#'
#' @param bibfile Character path to a .bib file (relative or absolute)
#' @param bib_style Bibliography style (default authoryear)
#' @param cite_style Citation style (default authoryear)
#' @param output_style One of 'auto', 'latex', 'html', 'markdown', 'text'. 'auto' picks latex for PDF else html.
#' @param collapse_newlines Logical; if TRUE collapse internal newlines in formatted entries.
#' @param bullet Logical; if TRUE prints each entry prefixed with a dash for HTML/text outputs.
#' @param wrap_urls Logical; wrap bare URLs in <...> for HTML-safe rendering.
#' @return Invisibly the BibEntry object (in case further processing is desired)
#' @examples
#' # In a Quarto/knitr chunk:
#' # source("literature/refmanager.r"); render_bib("literature/essential_readings.bib")
render_bib <- function(bibfile,
                       bib_style = "authoryear",
                       cite_style = "authoryear",
                       output_style = c("auto", "latex", "html", "markdown", "text"),
                       collapse_newlines = TRUE,
                       bullet = TRUE,
                       wrap_urls = TRUE,
                       html_list = TRUE,
                       container = c("list", "div", "dl")) {
  container <- match.arg(container)
  if (!requireNamespace("RefManageR", quietly = TRUE)) {
    stop("Package 'RefManageR' is required. Install it with install.packages('RefManageR').")
  }
  output_style <- match.arg(output_style)
  is_pdf <- knitr::is_latex_output()
  style <- if (output_style == "auto") if (is_pdf) "latex" else "html" else output_style
  # Configure options
  RefManageR::BibOptions(
    check.entries = FALSE,
    bib.style = bib_style,
    cite.style = cite_style,
    style = style,
    no.print.fields = c()
  )
  # Read bibliography
  bib <- RefManageR::ReadBib(bibfile, check = FALSE)
  if (is_pdf || style == "latex") {
    print(bib)
    return(invisible(bib))
  }
  # Non-PDF path: format entries
  formatted <- format(bib)
  if (collapse_newlines) {
    # Collapse any internal newlines plus surrounding whitespace into a single space
    formatted <- vapply(formatted, function(x) gsub("\n+", " ", x), character(1))
    formatted <- vapply(formatted, function(x) gsub("[[:space:]]+", " ", x), character(1))
  }
  if (wrap_urls) {
    # Wrap bare URLs (terminated by space or end-of-string) in angle brackets for safer HTML/Markdown rendering
    formatted <- vapply(formatted, function(x) gsub("(https?://[^[:space:]]+)", "<\\1>", x), character(1))
  }
  if (style %in% c("html", "markdown")) {
    if (container == "div") {
      cat("\n<div class=\"ref-bib\">\n")
      for (i in seq_along(formatted)) {
        cat("  <p class=\"ref-entry\">", formatted[i], "</p>\n", sep = "")
      }
      cat("</div>\n\n")
    } else if (container == "dl") {
      cat("\n<dl class=\"ref-bib\">\n")
      for (i in seq_along(formatted)) {
        cat("  <dt></dt><dd class=\"ref-entry\">", formatted[i], "</dd>\n", sep = "")
      }
      cat("</dl>\n\n")
    } else if (html_list) {
      cat("\n<ul class=\"ref-bib\">\n")
      for (i in seq_along(formatted)) {
        cat("  <li class=\"ref-entry\">", formatted[i], "</li>\n", sep = "")
      }
      cat("</ul>\n\n")
    }
  } else {
    cat("\n")
    for (i in seq_along(formatted)) {
      if (bullet) cat("- ", formatted[i], "\n", sep = "") else cat(formatted[i], "\n", sep = "")
    }
    cat("\n")
  }
  invisible(bib)
}
