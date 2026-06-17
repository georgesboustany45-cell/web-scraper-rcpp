#include <Rcpp.h>
#include <curl/curl.h>
#include <string>
#include <vector>
#include <map>
#include <chrono>
#include <thread>
#include <iostream>

using namespace Rcpp;

// Callback for libcurl to write data
static size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    userp->append((char*)contents, size * nmemb);
    return size * nmemb;
}

// Callback for libcurl to write headers
static size_t HeaderCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    userp->append((char*)contents, size * nmemb);
    return size * nmemb;
}

// Structure to hold scrape result
struct ScrapeResult {
    std::string url;
    std::string html;
    std::string headers;
    int http_code;
    std::string error_message;
    bool success;
    double response_time;
};

// Perform HTTP request with retry logic
ScrapeResult perform_http_request(
    const std::string& url,
    int timeout,
    int max_retries,
    double rate_limit,
    const std::string& user_agent,
    bool follow_redirects,
    bool verify_ssl
) {
    ScrapeResult result;
    result.url = url;
    result.success = false;
    result.http_code = 0;
    result.error_message = "";
    
    CURL* curl = curl_easy_init();
    if (!curl) {
        result.error_message = "Failed to initialize curl";
        return result;
    }
    
    auto start_time = std::chrono::high_resolution_clock::now();
    
    int attempt = 0;
    while (attempt < max_retries) {
        attempt++;
        
        // Reset for new attempt
        result.html.clear();
        result.headers.clear();
        
        // Set curl options
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, timeout);
        curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, timeout);
        curl_easy_setopt(curl, CURLOPT_USERAGENT, user_agent.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &result.html);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, HeaderCallback);
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, &result.headers);
        
        if (follow_redirects) {
            curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
            curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 5L);
        }
        
        if (!verify_ssl) {
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
        }
        
        // Perform request
        CURLcode res = curl_easy_perform(curl);
        
        // Get HTTP response code
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &result.http_code);
        
        if (res == CURLE_OK && result.http_code >= 200 && result.http_code < 300) {
            result.success = true;
            auto end_time = std::chrono::high_resolution_clock::now();
            result.response_time = std::chrono::duration<double>(end_time - start_time).count();
            break;
        }
        
        // Check for rate limiting
        if (result.http_code == 429) {
            result.error_message = "Rate limited (HTTP 429)";
            if (attempt < max_retries) {
                std::this_thread::sleep_for(std::chrono::seconds((int)(rate_limit * 2)));
            }
        } else if (res != CURLE_OK) {
            result.error_message = curl_easy_strerror(res);
        } else {
            result.error_message = "HTTP " + std::to_string(result.http_code);
        }
        
        // Wait before retry
        if (attempt < max_retries && rate_limit > 0) {
            std::this_thread::sleep_for(std::chrono::duration<double>(rate_limit));
        }
    }
    
    curl_easy_cleanup(curl);
    return result;
}

// [[Rcpp::export]]
Rcpp::List scrape_url_cpp(std::string url, Rcpp::List config) {
    // Extract configuration
    int timeout = config.containsElementNamed("timeout") ? 
        as<int>(config["timeout"]) : 30;
    int max_retries = config.containsElementNamed("max_retries") ? 
        as<int>(config["max_retries"]) : 3;
    double rate_limit = config.containsElementNamed("rate_limit") ? 
        as<double>(config["rate_limit"]) : 1.0;
    std::string user_agent = config.containsElementNamed("user_agent") ? 
        as<std::string>(config["user_agent"]) : "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";
    bool follow_redirects = config.containsElementNamed("follow_redirects") ? 
        as<bool>(config["follow_redirects"]) : true;
    bool verify_ssl = config.containsElementNamed("verify_ssl") ? 
        as<bool>(config["verify_ssl"]) : true;
    
    // Perform request
    ScrapeResult result = perform_http_request(
        url, timeout, max_retries, rate_limit, user_agent, follow_redirects, verify_ssl
    );
    
    // Return as R list
    Rcpp::List output = Rcpp::List::create(
        Rcpp::Named("url") = result.url,
        Rcpp::Named("html") = result.html,
        Rcpp::Named("headers") = result.headers,
        Rcpp::Named("http_code") = result.http_code,
        Rcpp::Named("error_message") = result.error_message,
        Rcpp::Named("success") = result.success,
        Rcpp::Named("response_time") = result.response_time
    );
    
    return output;
}

// [[Rcpp::export]]
Rcpp::List scrape_urls_cpp(Rcpp::StringVector urls, Rcpp::List config) {
    // Extract configuration
    double rate_limit = config.containsElementNamed("rate_limit") ? 
        as<double>(config["rate_limit"]) : 1.0;
    
    Rcpp::List results;
    
    for (int i = 0; i < urls.size(); ++i) {
        std::string url = as<std::string>(urls[i]);
        
        // Perform scrape
        Rcpp::List result = scrape_url_cpp(url, config);
        results.push_back(result);
        
        // Apply rate limiting between requests (except last one)
        if (i < urls.size() - 1 && rate_limit > 0) {
            std::this_thread::sleep_for(std::chrono::duration<double>(rate_limit));
        }
    }
    
    return results;
}
