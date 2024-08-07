#!/bin/sh

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

find . -name "*.DS_Store" -delete

<< COMMENT
# Build the project.
hugo # if using a theme, replace with `hugo -t <YOURTHEME>`

# Go To Public folder
cd public

origin='KingHwa_OldSong.ttf'
optimized='KingHwa.woff2'
echo "[+] optimizing font..."
pyftsubset "fonts/$origin" --text=$(rg -e '[\w\d]' -oN --no-filename|sort|uniq|tr -d '\n') --no-hinting
echo "[+] transfer to woff2 [${origin} -> ${optimized}"
fonttools ttLib.woff2 compress -o "fonts/$optimized" "fonts/KingHwa_OldSong.subset.ttf"

mv "fonts/$optimized" "../static/fonts/$optimized"
cd ..
COMMENT
# update bibliography
bash update_bib.sh

# Add changes to git.
rm -rf public && git add .
git commit -m "rebuilding site $(date)"
git push