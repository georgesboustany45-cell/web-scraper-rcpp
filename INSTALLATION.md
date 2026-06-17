# Installation Guide for webScraperRcpp

## Prerequisites

Before installing the package, ensure you have the required system dependencies and development tools.

### System Requirements

- **R >= 4.1.0**
- **C++17 compatible compiler**
- **libcurl development libraries**

### Operating System Specific Instructions

#### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required dependencies
brew install libcurl
brew install llvm  # If using Apple Clang, this is optional
```

#### Ubuntu / Debian

```bash
# Update package lists
sudo apt-get update

# Install required dependencies
sudo apt-get install -y libcurl4-openssl-dev
sudo apt-get install -y build-essential
sudo apt-get install -y r-base r-base-dev
```

#### Fedora / CentOS / RHEL

```bash
# Install required dependencies
sudo dnf install -y libcurl-devel
sudo dnf install -y gcc-c++ make
```

#### Windows

- Download and install Rtools from https://cran.r-project.org/bin/windows/Rtools/
- Rtools includes libcurl support
- Ensure Rtools is added to your PATH

## Installation Steps

### 1. From GitHub (Recommended)

```r
# Install devtools if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install the package from GitHub
devtools::install_github("georgesboustany45-cell/web-scraper-rcpp")
```

### 2. From Source

```bash
# Clone the repository
git clone https://github.com/georgesboustany45-cell/web-scraper-rcpp.git
cd web-scraper-rcpp

# Install dependencies
R -e "devtools::install_dev_deps()"

# Install the package
R CMD INSTALL .
```

### 3. From Local Directory

```r
# Navigate to package directory
setwd("/path/to/web-scraper-rcpp")

# Install
devtools::install()
```

## Verification

After installation, verify that the package works correctly:

```r
library(webScraperRcpp)

# Test basic functionality
set_scraper_config(timeout = 10)
result <- scrape_url("https://example.com")

if (result$success) {
  message("Installation successful!")
  message("Content length: ", nchar(result$html), " bytes")
} else {
  message("Installation test failed: ", result$error_message)
}
```

## Troubleshooting

### Compilation Errors Related to libcurl

**Problem:** `error: 'curl.h' file not found`

**Solution:**
- **macOS**: `brew install libcurl`
- **Linux**: `sudo apt-get install libcurl4-openssl-dev`
- **Windows**: Verify Rtools installation

### C++ Compilation Errors

**Problem:** C++ compiler not found or incompatible

**Solution:**
- **macOS**: Install Xcode: `xcode-select --install`
- **Linux**: Install build-essential: `sudo apt-get install build-essential`
- **Windows**: Install Rtools from https://cran.r-project.org/bin/windows/Rtools/

### pkg-config Not Found

**Problem:** `pkg-config: command not found`

**Solution:**
- **macOS**: `brew install pkg-config`
- **Linux**: `sudo apt-get install pkg-config`

### SSL Certificate Issues

If you encounter SSL certificate verification issues during installation:

```r
# Try installing with custom SSL settings
options(download.file.method = "curl")
devtools::install_github("georgesboustany45-cell/web-scraper-rcpp")
```

## Development Installation

For development and testing:

```r
# Install with all development dependencies
devtools::install_dev_deps()

# Build documentation
devtools::document()

# Run tests
devtools::test()

# Build vignettes
devtools::build_vignettes()
```

## Next Steps

After successful installation, see:
- [README.md](README.md) for overview
- `examples/basic_example.R` for basic usage
- `examples/advanced_example.R` for advanced patterns

## Getting Help

If you encounter installation issues:

1. Check that all prerequisites are installed
2. Review the system-specific instructions above
3. Try reinstalling libcurl
4. Open an issue on GitHub with:
   - Your operating system and version
   - R version (`R --version`)
   - Output of `devtools::session_info()`
   - Full error message
