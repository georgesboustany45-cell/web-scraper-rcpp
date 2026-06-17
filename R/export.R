#' Export Scrape Results to Data Frame
#'
#' Convert scrape_result(s) to a data.frame for analysis
#'
#' @param results A scrape_result or scrape_results object
#' @param include_metadata Logical. Include response metadata (default: TRUE)
#' @param include_content Logical. Include HTML content (default: FALSE)
#'
#' @return A data.frame with columns:
#' \describe{
#'   \item{url}{The requested URL}
#'   \item{http_code}{HTTP status code}
#'   \item{success}{Logical success indicator}
#'   \item{response_time}{Response time in seconds}
#'   \item{content_length}{Size of HTML content in bytes}
#'   \item{error_message}{Error message if applicable}
#'   \item{html}{HTML content (if include_content = TRUE)}
#' }
#'
#' @examples
#' \dontrun{
#' result <- scrape_url("https://example.com")
#' df <- export_to_dataframe(result)
#' head(df)
#' }
#'
#' @export
export_to_dataframe <- function(results, include_metadata = TRUE, include_content = FALSE) {
  
  # Handle single result
  if (inherits(results, "scrape_result")) {
    results <- list(results)
  }
  
  if (!inherits(results, "scrape_results") && !is.list(results)) {
    stop("results must be a scrape_result or scrape_results object")
  }
  
  # Extract data
  data <- data.frame(
    url = sapply(results, function(x) x$url),
    http_code = sapply(results, function(x) x$http_code),
    success = sapply(results, function(x) x$success),
    response_time = sapply(results, function(x) x$response_time),
    content_length = sapply(results, function(x) nchar(x$html)),
    error_message = sapply(results, function(x) x$error_message),
    stringsAsFactors = FALSE
  )
  
  if (include_content) {
    data$html <- sapply(results, function(x) x$html)
  }
  
  if (include_metadata) {
    data$headers <- sapply(results, function(x) x$headers)
  }
  
  return(data)
}

#' Export Scrape Results to Tibble
#'
#' Convert scrape_result(s) to a tibble for analysis
#'
#' @param results A scrape_result or scrape_results object
#' @param include_metadata Logical. Include response metadata (default: TRUE)
#' @param include_content Logical. Include HTML content (default: FALSE)
#'
#' @return A tibble with the same columns as export_to_dataframe()
#'
#' @examples
#' \dontrun{
#' result <- scrape_url("https://example.com")
#' tbl <- export_to_tibble(result)
#' print(tbl)
#' }
#'
#' @export
export_to_tibble <- function(results, include_metadata = TRUE, include_content = FALSE) {
  
  df <- export_to_dataframe(results, include_metadata, include_content)
  
  # Convert to tibble if available
  if (requireNamespace("tibble", quietly = TRUE)) {
    df <- tibble::as_tibble(df)
  }
  
  return(df)
}

#' Summary method for scrape_results
#'
#' @keywords internal
#' @export
summary.scrape_results <- function(object, ...) {
  
  total <- length(object)
  successful <- sum(sapply(object, function(x) x$success))
  failed <- total - successful
  
  total_time <- sum(sapply(object, function(x) x$response_time))
  avg_time <- mean(sapply(object, function(x) x$response_time))
  
  total_content <- sum(sapply(object, function(x) nchar(x$html)))
  
  http_codes <- table(sapply(object, function(x) x$http_code))
  
  result <- list(
    total_urls = total,
    successful = successful,
    failed = failed,
    success_rate = successful / total,
    total_time = total_time,
    average_time = avg_time,
    total_content_bytes = total_content,
    http_codes = http_codes
  )
  
  class(result) <- "summary.scrape_results"
  result
}

#' Print summary
#'
#' @keywords internal
#' @export
print.summary.scrape_results <- function(x, ...) {
  cat("=== Scrape Summary ===\n")
  cat("Total URLs:", x$total_urls, "\n")
  cat("Successful:", x$successful, "\n")
  cat("Failed:", x$failed, "\n")
  cat("Success Rate:", sprintf("%.1f%%", x$success_rate * 100), "\n")
  cat("Total Time:", sprintf("%.2f", x$total_time), "seconds\n")
  cat("Average Time:", sprintf("%.2f", x$average_time), "seconds\n")
  cat("Total Content:", sprintf("%.2f", x$total_content_bytes / 1024 / 1024), "MB\n")
  
  if (length(x$http_codes) > 0) {
    cat("\nHTTP Status Codes:\n")
    for (code in names(x$http_codes)) {
      cat("  ", code, ":", x$http_codes[[code]], "\n")
    }
  }
  
  invisible(x)
}
