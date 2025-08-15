#!/bin/bash

# ==============================================
# | Date: 2024-11-23                           |
# ==============================================
# | Description: Website Screenshot Tool.      |
# ==============================================
# | Created By: Trabbit                        |
# ==============================================

clear

# VARIABLES
urls=()
argument=""
list_file=""

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NE="\e[0m"

# Dependencies check
check_dependencies() {
    command -v jq &>/dev/null || { echo -e "${RED}Error: jq is not installed.${NE}"; exit 1; }
    command -v curl &>/dev/null || { echo -e "${RED}Error: curl is not installed.${NE}"; exit 1; }
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
            echo -e "\nScreenshot saved as: ${GREEN}$filename${NE}\n---------\n"
            return 0
        fi
        echo -e "${RED}Error: Download failed, retrying... ($attempt/$retries)${NE}"
        ((attempt++))
    done

    echo -e "${RED}Failed to download screenshot after $retries attempts.${NE}"
    exit 1
}

# Ensure URL has protocol
ensure_protocol() {
    if [[ ! $1 =~ ^https?:// ]]; then
        echo "https://$1"
    else
        echo "$1"
    fi
}

# Screenshot handler
get_screenshot() {
    local url=$1

    url=$(ensure_protocol "$url")

    if [[ -z $argument ]]; then
        screenshot_url=$(curl -sL "https://api.microlink.io/?url=$url/&screenshot&waitUntil=load" | jq -r '.data.screenshot.url')
    else
        case $argument in
            -full)
                screenshot_url=$(curl -sL "https://api.microlink.io/?url=$url/&screenshot.element=body&waitUntil=load" | jq -r '.data.screenshot.url')
                ;;
            *)
                echo -e "${RED}Invalid argument: $argument. Use -f or --full-page.${NE}"
                exit 1
                ;;
        esac
    fi

    if [[ -z $screenshot_url || $screenshot_url == "null" ]]; then
        echo -e "${RED}Failed to get screenshot URL for $url.${NE}"
        return 1
    fi

    echo -e "Screenshot URL: ${GREEN}$screenshot_url${NE}"

    mkdir -p /screenshots
    timestamp=$(date +%Y%m%d%H%M%S)
    screenshot_filename="/screenshots/screenshot_$(echo $url | sed 's|https\?://||; s|/|_|g')_$timestamp.png"

    download_screenshot "$screenshot_url" "$screenshot_filename"
}

# Help
help() {
    echo -e "Usage: sshot [options] <url1> [url2] ..."
    echo -e "\nOptions:"
    echo -e "  -f, --full-page     Full-page screenshot"
    echo -e "  -l <file>           Read URLs from a file (one per line)"
    echo -e "  -h, --help          Show this help message"
    echo -e "\nExamples:"
    echo -e "  sshot http://example.com"
    echo -e "  sshot -f http://example.com"
    echo -e "  sshot -f -l urls.txt"
    echo -e "  sshot -l urls.txt"
    echo -e "\nScreenshots are saved to: /screenshots"
    exit 0
}

# Parse args
parse_args() {
    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            -f | --full-page)
                argument="-full"
                shift
                ;;
            -l)
                list_file="$2"
                shift 2
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

    if [[ -n $list_file ]]; then
        if [[ ! -f $list_file ]]; then
            echo -e "${RED}Error: File $list_file does not exist.${NE}"
            exit 1
        fi
        mapfile -t urls < "$list_file"
    else
        urls=("$@")
    fi

    if [[ ${#urls[@]} -lt 1 ]]; then
        help
    fi
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

# Main
main() {
    check_dependencies
    menu
    parse_args "$@"

    for url in "${urls[@]}"; do
        get_screenshot "$url"
    done
}

main "$@"
