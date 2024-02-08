find . -type f -name "*.bib" | while read bibfile; do
    dir=$(dirname "$bibfile")
    pandoc -t csljson -s "$bibfile" -o "$dir/bib.json"
done 
