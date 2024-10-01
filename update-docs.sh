set -e

OUTPUT_FILE="prompt.generated.md"

mkdir -p data
cp prompt-intro.md "$OUTPUT_FILE"
repos=("hadley/elmer" "jcheng5/shinychat")
for repo in ${repos[@]}; do
  repo_name=$(basename $repo)
  echo "" >> "$OUTPUT_FILE"
  echo "Here is the README.md for $repo_name:" >> "$OUTPUT_FILE"
  echo "<README>" >> "$OUTPUT_FILE"
  curl "https://raw.githubusercontent.com/$repo/refs/heads/main/README.md" >> "$OUTPUT_FILE"
  echo "</README>" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
done
