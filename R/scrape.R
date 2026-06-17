#' Scrape a Single URL
#'
#' Fetch and parse content from a single URL with configurable
#' timeout, retries, and rate limiting.
#'
#' @param url Character. The URL to scrape
#' @param config List. Optional configuration overrides. If NULL, uses global config
#'
#' @return A list containing:
#' \describe{
#'   \item{url}{The requested URL}
#'   \item{html}{The HTML content as character string}
#'   \item{headers}{HTTP response headers}
#'   \item{http_code}{HTTP status code}
#'   \item{error_message}{Error message if request failed}
#'   \item{success}{Logical indicating success}
#'   \item{response_time}{Response time in seconds}
#' }
#'
#' @examples
#' \dontrun{
#' result <- scrape_url("https://example.com")
#' if (result$success) {
#'   cat("Content length:", nchar(result$html), "\n")
#' } else {
#'   cat("Error:", result$error_message, "\n")
#' }
#' }
#'
#' @export
scrape_url <- function(url, config = NULL) {
  
  # Validate URL
  if (!is.character(url) || length(url) != 1) {
    stop("url must be a single character string")
  }
  
  if (!grepl("^https?://", url)) {
    stop("url must start with http:// or https://")
  }
  
  # Use provided config or get global config
  if (is.null(config)) {
    config <- get_scraper_config()
  } else {
    # Merge with global config (provided values override global)
    global_config <- get_scraper_config()
    for (name in names(global_config)) {
      if (!(name %in% names(config))) {
        config[[name]] <- global_config[[name]]
      }
    }
  }
  
  # Validate configuration
  validate_config()
  
  # Call C++ backend
  result <- scrape_url_cpp(url, config)
  
  # Add metadata
  result$url_requested <- url
  result$config_used <- config
  
  class(result) <- c("scrape_result", "list")
  
  return(result)
}

#' Scrape Multiple URLs
#'
#' Fetch and parse content from multiple URLs with automatic
#' rate limiting between requests.
#'
#' @param urls Character vector. URLs to scrape
#' @param config List. Optional configuration overrides
#' @param verbose Logical. Print progress messages (default: TRUE)
#'
#' @return A list of scrape_result objects
#'
#' @examples
#' \dontrun{
#' urls <- c("https://example.com", "https://example.org")
#' results <- scrape_urls(urls)
#' 
#' # Check success rate
#' success_count <- sum(sapply(results, function(x) x$success))
#' cat(success_count, "of", length(urls), "URLs scraped successfully\n")
#' }
#'
#' @export
scrape_urls <- function(urls, config = NULL, verbose = TRUE) {
  
  # Validate URLs
  if (!is.character(urls)) {
    stop("urls must be a character vector")
  }
  
  if (length(urls) == 0) {
    stop("urls cannot be empty")
  }
  
  if (any(!grepl("^https?://", urls))) {
    stop("All URLs must start with http:// or https://")
  }
  
  # Use provided config or get global config
  if (is.null(config)) {
    config <- get_scraper_config()
  } else {
    # Merge with global config
    global_config <- get_scraper_config()
    for (name in names(global_config)) {
      if (!(name %in% names(config))) {
        config[[name]] <- global_config[[name]]
      }
    }
  }
  
  # Validate configuration
  validate_config()
  
  if (verbose) {
    message(sprintf("Scraping %d URLs with %d second rate limit...",
                    length(urls), config$rate_limit))
  }
  
  # Call C++ backend for multiple URLs
  results_raw <- scrape_urls_cpp(urls, config)
  
  # Convert each result to scrape_result object
  results <- lapply(seq_along(results_raw), function(i) {
    result <- results_raw[[i]]
    result$url_requested <- urls[i]
    result$config_used <- config
    class(result) <- c("scrape_result", "list")
    result
  })
  
  class(results) <- c("scrape_results", "list")
  
  if (verbose) {
    success_count <- sum(sapply(results, function(x) x$success))
    message(sprintf("Completed: %d of %d URLs successful",
                    success_count, length(urls)))
  }
  
  return(results)
}

#' Print scrape_result
#'
#' @keywords internal
#' @export
print.scrape_result <- function(x, ...) {
  cat("Scrape Result:\n")
  cat("  URL:", x$url, "\n")
  cat("  Status:", if (x$success) "SUCCESS" else "FAILED", "\n")
  cat("  HTTP Code:", x$http_code, "\n")
  cat("  Content Length:", nchar(x$html), "bytes\n")
  cat("  Response Time:", sprintf("%.2f", x$response_time), "seconds\n")
  
  if (!x$success) {
    cat("  Error:", x$error_message, "\n")
  }
  
  invisible(x)
}

#' Print scrape_results
#'
#' @keywords internal
#' @export
print.scrape_results <- function(x, ...) {
  cat("Scrape Results:\n")
  cat("  Total URLs:", length(x), "\n")
  
  success_count <- sum(sapply(x, function(r) r$success))
  cat("  Successful:", success_count, "\n")
  cat("  Failed:", length(x) - success_count, "\n")
  
  total_time <- sum(sapply(x, function(r) r$response_time))
  cat("  Total Time:", sprintf("%.2f", total_time), "seconds\n")
  
  invisible(x)
}
