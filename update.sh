#!/bin/sh

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

find . -name "*.DS_Store" -delete

# Build the project.
#hugo # if using a theme, replace with `hugo -t <YOURTHEME>`


# update bibliography
bash update_bib.sh

# Add changes to git.
rm -rf public && git add .
git commit -m "rebuilding site $(date)"
git push