#' webScraperRcpp: High-Performance Web Scraper with R and C++
#'
#' A robust web scraper combining R for user interface and C++ via Rcpp
#' for high-performance data parsing, memory management, and network requests.
#'
#' @docType package
#' @name webScraperRcpp
#' @import Rcpp
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{scrape_url}}}{Scrape a single URL}
#'   \item{\code{\link{scrape_urls}}}{Scrape multiple URLs with rate limiting}
#'   \item{\code{\link{set_scraper_config}}}{Configure scraper settings}
#'   \item{\code{\link{get_scraper_config}}}{Get current configuration}
#'   \item{\code{\link{export_to_dataframe}}}{Export results to data.frame}
#'   \item{\code{\link{export_to_tibble}}}{Export results to tibble}
#' }
#'
#' @section Features:
#' \describe{
#'   \item{Performance}{C++ backend with Rcpp for fast parsing}
#'   \item{Robustness}{Automatic retries, rate limiting, and timeout handling}
#'   \item{Flexibility}{Configurable timeouts, retries, and user agents}
#'   \item{Data Export}{Easy conversion to R data structures}
#' }
#'
#' @examples
#' \dontrun{
#' library(webScraperRcpp)
#'
#' # Configure
#' set_scraper_config(timeout = 30, max_retries = 3)
#'
#' # Scrape single URL
#' result <- scrape_url("https://example.com")
#'
#' # Scrape multiple URLs
#' urls <- c("https://example.com", "https://example.org")
#' results <- scrape_urls(urls)
#'
#' # Export to dataframe
#' df <- export_to_dataframe(results)
#'
#' # Export to tibble
#' tbl <- export_to_tibble(results)
#' }
#'
NULL
