#!/bin/bash

# Debugging in case of bugs
# set -e

# ==============================================
# | Date: 2024-11-23                           |
# ==============================================
# | Description: Website Screenshot Tool.      |
# |                                            |
# ==============================================
# | Created By: Trabbit                        |
# ==============================================

# Clear the screen
clear

# VARIABLES
urls=()           # Array to hold URLs
argument=""       # Additional argument for full screenshot option

# Colors
RED="\e[31m"        # Classic RED
GREEN="\e[32m"      # Classic GREEN
YELLOW="\e[33m"     # Classic YELLOW
BLUE="\e[34m"       # Classic BLUE
PURPLE="\e[35m"     # Classic PURPLE
BG_RED="\e[41m"     # Background RED
BG_GREEN="\e[42m"   # Background GREEN
BG_YELLOW="\e[43m"  # Background YELLOW
BG_BLUE="\e[44m"    # Background BLUE
BG_PURPLE="\e[45m"  # Background PURPLE
NE="\e[0m"          # No color

# Dependencies check
check_dependencies() {
    command -v jq &>/dev/null || { echo -e "${RED}Error: jq is not installed. Please install it.${NE}"; exit 1; }
    command -v curl &>/dev/null || { echo -e "${RED}Error: curl is not installed. Please install it.${NE}"; exit 1; }
}

# Progress bar for downloading
progress_bar() {
    # This function will show a simple progress bar for wget
    local progress=$(($1 * 100 / $2))
    printf "\r[%-50s] %d%%" $(printf "%0.s#" $(seq 1 $progress)) $progress
}

# Retry mechanism for downloading the screenshot
download_screenshot() {
    local url=$1
    local filename=$2
    local retries=3
    local attempt=1

    while [[ $attempt -le $retries ]]; do
        wget -q --show-progress "$url" -O "$filename"
        if [[ $? -eq 0 ]]; then
            echo -e "\nScreenshot saved as: ${GREEN}$filename${NE}"
            echo
            echo -e "---------"
            echo
            return 0
        fi
        echo -e "${RED}Error: Download failed, retrying... ($attempt/$retries)${NE}"
        ((attempt++))
    done

    echo -e "${RED}Failed to download screenshot after $retries attempts.${NE}"
    exit 1
}

# Ensure the URL has a protocol (http:// or https://)
ensure_protocol() {
    if [[ ! $url =~ ^https?:// ]]; then
        url="https://$url"
    fi
}

# Function to handle getting the screenshot
get_screenshot() {
    if [[ -z $url ]]; then
        echo -e "Please Provide The Target URL"
        exit 0
    fi

    # Ensure the URL has the appropriate protocol
    ensure_protocol

    # Determine the screenshot URL
    if [[ -z $argument ]]; then
        screenshot_url=$(curl -sL "https://api.microlink.io/?url=$url/&screenshot" | jq -r '.data.screenshot.url')
    else
        case $argument in
            -f | -full)
                screenshot_url=$(curl -sL "https://api.microlink.io/?url=$url/&screenshot.element=body" | jq -r '.data.screenshot.url')
                ;;
            * )
                echo -e "Invalid Argument: $argument. Valid option is -f or -full."
                exit 0
                ;;
        esac
    fi

    if [[ -z $screenshot_url || $screenshot_url == "null" ]]; then
        echo -e "Failed to retrieve the screenshot URL. Check the target URL or API status."
        exit 1
    fi

    echo -e "Screenshot URL: ${GREEN}$screenshot_url${NE}"

    # Generate a unique filename based on the current timestamp
    timestamp=$(date +%Y%m%d%H%M%S)
    screenshot_filename="screenshot_$timestamp.png"

    download_screenshot "$screenshot_url" "$screenshot_filename"
}

# Help message
help() {
    echo -e "${YELLOW}Usage: $(basename $0) [options] <url1> [url2] [url3] ...${NE}"
    echo -e "This script takes a screenshot of websites and saves them as PNG images."
    echo -e "\nOptions:"
    echo -e "  -f, --full-page       Take a full-page screenshot of the webpage (default)."
    echo -e "  -h, --help      Show this help message."
    echo -e "\nExamples:"
    echo -e "  $(basename $0) http://example.com      Take a screenshot of http://example.com."
    echo -e "  $(basename $0) -f http://example.com   Take a full-page screenshot of http://example.com."
    echo -e "  $(basename $0) http://example1.com http://example2.com  Take screenshots of both URLs."
    echo -e "\nNote: If no URL protocol (http:// or https://) is provided, 'https' will be assumed."
    exit 0
}

# Parse command-line arguments
parse_args() {
    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            -f | --full-page)
                ensure_protocol
                argument="-full"
                shift
                ;;
            -h | --help)
                help
                ;;
            *)
                echo -e "${RED}Error: Invalid option $1${NE}"
                help
                ;;
        esac
    done

    # Capture the remaining arguments as URLs
    urls=("$@")

    # Check if URLs are provided
    if [[ ${#urls[@]} -lt 1 ]]; then
        echo -e "${RED}Error: No URLs provided.${NE}"
        help
    fi
}

# Main function
main() {
    check_dependencies
    menu
    parse_args "$@"

    for url in "${urls[@]}"; do
        get_screenshot "$url"
    done
}

# Menu
menu() {
    echo "           .---.  "
    echo "           |[ ]|  "
    echo "    _.==._.-----.___n__"
    echo "   | __ ___.-''-. _____|    SSHOT - Trabbit"
    echo "   |[__]  /.''''.\ _   |  Web Screenshot Tool"
    echo "   |     // /''\ \\\_)  |"
    echo "   |     \\\ \__/ //    |"
    echo "   |      \'.__.'/     |"
    echo "   \======='-..-'======/"
    echo "    '-----------------'"
    echo
}

# Call the main function
main "$@"
