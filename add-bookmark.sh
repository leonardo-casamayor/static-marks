#!/usr/bin/env bash

# add-bookmark.sh - Helper to add bookmarks to YAML files

# 1. Prerequisite checks
MISSING_TOOLS=()
command -v fzf >/dev/null 2>&1 || MISSING_TOOLS+=("fzf")
command -v yq >/dev/null 2>&1 || MISSING_TOOLS+=("yq")

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Error: The following tools are required but not installed: ${MISSING_TOOLS[*]}"
    if [[ " ${MISSING_TOOLS[*]} " == *" yq "* ]]; then
        echo "You can install yq via Homebrew: brew install yq"
    fi
    exit 1
fi

if [ ! -d "bookmarks" ]; then
    echo "Error: 'bookmarks' directory not found in $(pwd)."
    exit 1
fi

# 2. Select the YAML file
FILE=$(ls bookmarks/*.yml | fzf --prompt="Select Bookmark File: " --height=10 --border)
[ -z "$FILE" ] && exit 0

# 3. Select Level 1 (Category - e.g., Development, General)
L1=$(yq 'keys | .[]' "$FILE" | fzf --prompt="Select Category: " --height=10 --border)
[ -z "$L1" ] && exit 0

# 4. Select Level 2 (Section - e.g., Tools, Xcode)
# The structure is Level1: [ {Level2: [...]}, ... ]
L2=$(yq ".$L1[] | keys | .[]" "$FILE" | fzf --prompt="Select Section: " --height=10 --border)
[ -z "$L2" ] && exit 0

# 5. Prompt for Name and URL
echo -e "\nAdding to $FILE > $L1 > $L2"
read -p "Bookmark Name: " NAME
read -p "Bookmark URL:  " URL

if [ -z "$NAME" ] || [ -z "$URL" ]; then
    echo "Error: Name and URL cannot be empty."
    exit 1
fi

# 6. Insert the new entry
# This command finds the section in the list and appends the new name:url pair
yq -i "(.$L1[] | select(has(\"$L2\")).$L2) += {\"$NAME\": \"$URL\"}" "$FILE"

if [ $? -eq 0 ]; then
    echo -e "\nSuccessfully added '$NAME' to $L2."
else
    echo -e "\nFailed to add bookmark. Please check if the YAML structure matches expectations."
    exit 1
fi
