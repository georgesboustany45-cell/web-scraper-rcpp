#' Scrape a Single URL (Pure R version)
#'
#' Fetch content from a single URL using httr2 package
#'
#' @param url Character. The URL to scrape
#' @param config List. Optional configuration overrides
#'
#' @return A list with scrape result
#'
#' @export
scrape_url <- function(url, config = NULL) {
  
  if (!is.character(url) || length(url) != 1) {
    stop("url must be a single character string")
  }
  
  if (!grepl("^https?://", url)) {
    stop("url must start with http:// or https://")
  }
  
  if (is.null(config)) {
    config <- get_scraper_config()
  } else {
    global_config <- get_scraper_config()
    for (name in names(global_config)) {
      if (!(name %in% names(config))) {
        config[[name]] <- global_config[[name]]
      }
    }
  }
  
  validate_config()
  
  # Try to use httr2 if available, otherwise fall back to httr
  result <- tryCatch({
    if (requireNamespace("httr2", quietly = TRUE)) {
      scrape_with_httr2(url, config)
    } else if (requireNamespace("httr", quietly = TRUE)) {
      scrape_with_httr(url, config)
    } else {
      stop("Either 'httr2' or 'httr' package is required. Install with: install.packages('httr2')")
    }
  }, error = function(e) {
    list(
      url = url,
      html = "",
      headers = "",
      http_code = 0,
      error_message = e$message,
      success = FALSE,
      response_time = 0
    )
  })
  
  class(result) <- c("scrape_result", "list")
  return(result)
}

#' Scrape Multiple URLs
#'
#' @param urls Character vector of URLs
#' @param config List. Configuration
#' @param verbose Logical. Print progress
#'
#' @export
scrape_urls <- function(urls, config = NULL, verbose = TRUE) {
  
  if (!is.character(urls)) {
    stop("urls must be a character vector")
  }
  
  if (length(urls) == 0) {
    stop("urls cannot be empty")
  }
  
  if (any(!grepl("^https?://", urls))) {
    stop("All URLs must start with http:// or https://")
  }
  
  if (is.null(config)) {
    config <- get_scraper_config()
  } else {
    global_config <- get_scraper_config()
    for (name in names(global_config)) {
      if (!(name %in% names(config))) {
        config[[name]] <- global_config[[name]]
      }
    }
  }
  
  validate_config()
  
  if (verbose) {
    message(sprintf("Scraping %d URLs with %d second rate limit...",
                    length(urls), config$rate_limit))
  }
  
  results <- lapply(seq_along(urls), function(i) {
    result <- scrape_url(urls[i], config)
    
    if (i < length(urls) && config$rate_limit > 0) {
      Sys.sleep(config$rate_limit)
    }
    
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

#' Internal: Scrape with httr2
#'
#' @keywords internal
scrape_with_httr2 <- function(url, config) {
  library(httr2)
  
  start_time <- Sys.time()
  
  attempt <- 1
  result <- NULL
  
  while (attempt <= config$max_retries) {
    tryCatch({
      req <- request(url) %>%
        req_timeout(config$timeout) %>%
        req_user_agent(config$user_agent)
      
      if (!config$verify_ssl) {
        req <- req %>% req_retry(max_tries = 1)
      }
      
      resp <- req_perform(req)
      
      response_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      
      result <- list(
        url = url,
        html = resp_body_string(resp),
        headers = paste(names(resp_headers(resp)), ": ", resp_headers(resp), collapse = "\n"),
        http_code = resp_status(resp),
        error_message = "",
        success = resp_status(resp) >= 200 && resp_status(resp) < 300,
        response_time = response_time
      )
      
      if (result$success) {
        return(result)
      }
      
    }, error = function(e) {
      NULL
    })
    
    if (is.null(result) && attempt < config$max_retries) {
      Sys.sleep(config$rate_limit)
      attempt <<- attempt + 1
    } else {
      break
    }
  }
  
  if (is.null(result)) {
    response_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    result <- list(
      url = url,
      html = "",
      headers = "",
      http_code = 0,
      error_message = "Request failed after retries",
      success = FALSE,
      response_time = response_time
    )
  }
  
  return(result)
}

#' Internal: Scrape with httr
#'
#' @keywords internal
scrape_with_httr <- function(url, config) {
  library(httr)
  
  start_time <- Sys.time()
  
  attempt <- 1
  result <- NULL
  
  while (attempt <= config$max_retries) {
    tryCatch({
      resp <- GET(
        url,
        timeout(config$timeout),
        user_agent(config$user_agent),
        if (!config$verify_ssl) config(ssl_verifypeer = 0L) else NULL
      )
      
      response_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      
      result <- list(
        url = url,
        html = content(resp, as = "text"),
        headers = paste(names(headers(resp)), ": ", headers(resp), collapse = "\n"),
        http_code = status_code(resp),
        error_message = "",
        success = status_code(resp) >= 200 && status_code(resp) < 300,
        response_time = response_time
      )
      
      if (result$success || status_code(resp) == 429) {
        if (status_code(resp) == 429 && attempt < config$max_retries) {
          Sys.sleep(config$rate_limit * 2)
          attempt <<- attempt + 1
        } else {
          return(result)
        }
      } else {
        return(result)
      }
      
    }, error = function(e) {
      NULL
    })
    
    if (is.null(result) && attempt < config$max_retries) {
      Sys.sleep(config$rate_limit)
      attempt <<- attempt + 1
    } else {
      break
    }
  }
  
  if (is.null(result)) {
    response_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    result <- list(
      url = url,
      html = "",
      headers = "",
      http_code = 0,
      error_message = "Request failed after retries",
      success = FALSE,
      response_time = response_time
    )
  }
  
  return(result)
}
