set -e

mkdir -p data
cp prompt-intro.md prompt.md
repos=("hadley/elmer" "jcheng5/shinychat")
for repo in ${repos[@]}; do
  repo_name=$(basename $repo)
  echo "" >> prompt.md
  echo "Here is the README.md for $repo_name:" >> prompt.md
  echo "<README>" >> prompt.md
  curl "https://raw.githubusercontent.com/$repo/refs/heads/main/README.md" >> prompt.md
  echo "</README>" >> prompt.md
  echo "" >> prompt.md
done
