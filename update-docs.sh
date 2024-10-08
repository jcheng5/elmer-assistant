#!/bin/bash

set -e

OUTPUT_FILE="prompt.generated.md"

mkdir -p data
cp prompt-intro.md "$OUTPUT_FILE"

# Function to fetch and append content
fetch_and_append() {
    local repo=$1
    local file_path=$2
    local file_name=$(basename "$file_path")

    echo "" >> "$OUTPUT_FILE"
    echo "Here is the $file_name for $repo:" >> "$OUTPUT_FILE"
    echo "<$file_name>" >> "$OUTPUT_FILE"
    curl -L "https://raw.githubusercontent.com/$repo/main/$file_path" >> "$OUTPUT_FILE"
    echo "</$file_name>" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Fetch files for hadley/elmer
repo="hadley/elmer"
fetch_and_append "$repo" "README.md"
fetch_and_append "$repo" "vignettes/streaming-async.Rmd"
fetch_and_append "$repo" "vignettes/tool-calling.Rmd"

# Fetch README for jcheng5/shinychat
repo="jcheng5/shinychat"
fetch_and_append "$repo" "README.md"
