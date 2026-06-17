#' Default Scraper Configuration
#'
#' Internal environment to store global scraper configuration
#'
#' @keywords internal
.scraper_config <- new.env(parent = emptyenv())

#' Initialize Default Configuration
#'
#' @keywords internal
.init_config <- function() {
  .scraper_config$timeout <- 30
  .scraper_config$max_retries <- 3
  .scraper_config$rate_limit <- 1
  .scraper_config$user_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
  .scraper_config$follow_redirects <- TRUE
  .scraper_config$verify_ssl <- TRUE
  .scraper_config$proxy <- NULL
}

# Initialize on package load
.init_config()

#' Set Scraper Configuration
#'
#' Configure global settings for web scraping including timeouts,
#' retries, rate limiting, and SSL verification.
#'
#' @param timeout Integer. Request timeout in seconds (default: 30)
#' @param max_retries Integer. Maximum number of retry attempts (default: 3)
#' @param rate_limit Numeric. Delay between requests in seconds (default: 1)
#' @param user_agent Character. Custom User-Agent header
#' @param follow_redirects Logical. Follow HTTP redirects (default: TRUE)
#' @param verify_ssl Logical. Verify SSL certificates (default: TRUE)
#' @param proxy Character. Optional proxy URL
#'
#' @return Invisibly returns the configuration list
#'
#' @examples
#' \dontrun{
#' set_scraper_config(
#'   timeout = 60,
#'   max_retries = 5,
#'   rate_limit = 2
#' )
#' }
#'
#' @export
set_scraper_config <- function(
    timeout = NULL,
    max_retries = NULL,
    rate_limit = NULL,
    user_agent = NULL,
    follow_redirects = NULL,
    verify_ssl = NULL,
    proxy = NULL
) {
  
  if (!is.null(timeout)) {
    validate_positive_numeric(timeout, "timeout")
    .scraper_config$timeout <- as.integer(timeout)
  }
  
  if (!is.null(max_retries)) {
    validate_positive_numeric(max_retries, "max_retries")
    .scraper_config$max_retries <- as.integer(max_retries)
  }
  
  if (!is.null(rate_limit)) {
    validate_positive_numeric(rate_limit, "rate_limit")
    .scraper_config$rate_limit <- as.numeric(rate_limit)
  }
  
  if (!is.null(user_agent)) {
    if (!is.character(user_agent) || length(user_agent) != 1) {
      stop("user_agent must be a character string")
    }
    .scraper_config$user_agent <- user_agent
  }
  
  if (!is.null(follow_redirects)) {
    if (!is.logical(follow_redirects)) {
      stop("follow_redirects must be logical (TRUE/FALSE)")
    }
    .scraper_config$follow_redirects <- follow_redirects
  }
  
  if (!is.null(verify_ssl)) {
    if (!is.logical(verify_ssl)) {
      stop("verify_ssl must be logical (TRUE/FALSE)")
    }
    .scraper_config$verify_ssl <- verify_ssl
  }
  
  if (!is.null(proxy)) {
    if (!is.character(proxy) || length(proxy) != 1) {
      stop("proxy must be a character string or NULL")
    }
    .scraper_config$proxy <- proxy
  }
  
  message("Scraper configuration updated")
  invisible(get_scraper_config())
}

#' Get Current Scraper Configuration
#'
#' Retrieve the current global scraper configuration.
#'
#' @return A list containing the current configuration
#'
#' @examples
#' \dontrun{
#' config <- get_scraper_config()
#' str(config)
#' }
#'
#' @export
get_scraper_config <- function() {
  list(
    timeout = .scraper_config$timeout,
    max_retries = .scraper_config$max_retries,
    rate_limit = .scraper_config$rate_limit,
    user_agent = .scraper_config$user_agent,
    follow_redirects = .scraper_config$follow_redirects,
    verify_ssl = .scraper_config$verify_ssl,
    proxy = .scraper_config$proxy
  )
}

#' Validate Configuration
#'
#' Check if the current configuration is valid.
#'
#' @return Logical. TRUE if configuration is valid, otherwise raises error
#'
#' @examples
#' \dontrun{
#' validate_config()
#' }
#'
#' @export
validate_config <- function() {
  config <- get_scraper_config()
  
  if (config$timeout <= 0) {
    stop("timeout must be positive")
  }
  
  if (config$max_retries < 0) {
    stop("max_retries must be non-negative")
  }
  
  if (config$rate_limit < 0) {
    stop("rate_limit must be non-negative")
  }
  
  if (!is.logical(config$follow_redirects)) {
    stop("follow_redirects must be logical")
  }
  
  if (!is.logical(config$verify_ssl)) {
    stop("verify_ssl must be logical")
  }
  
  TRUE
}

#' Validate Positive Numeric
#'
#' @keywords internal
validate_positive_numeric <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1 || value <= 0) {
    stop(sprintf("%s must be a positive number", name))
  }
  invisible(TRUE)
}
