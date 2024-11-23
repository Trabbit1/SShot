#!/bin/bash

# Debugging in case of bugs
# set -e

# ////////////////////////////////////////////
# //  THIS IS A SHELL CODE TEMPLATE MODAL   //
# ////////////////////////////////////////////

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
url="$1"
argument="$2"

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

# Functions

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

get_screenshot() {
    if [[ -z $url ]]; then
        echo -e "Please Provide The Target URL"
        exit 0
    fi

    # Determine the screenshot URL
    if [[ -z $argument ]]; then
        screenshot_url=$(curl -sL "https://api.microlink.io/?url=$url/&screenshot" | jq -r '.data.screenshot.url')
    else
        case $argument in
            -f | -full)
                screenshot_url=$(curl -sL "https://api.microlink.io/?url=$url/&screenshot.element=body" | jq -r '.data.screenshot.url')
                ;;
            *)
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

    # Download the screenshot with the unique filename
    wget -q "$screenshot_url" -O "$screenshot_filename"
    if [[ $? -eq 0 ]]; then
        echo -e "Screenshot saved as: ${GREEN}$screenshot_filename${NE}"
    else
        echo -e "${RED}Error: Failed to save the screenshot.${NE}"
        exit 1
    fi
}

# Main function
main() {
    check_dependencies
    menu
    get_screenshot
}

# Call the main function
main
