echo "[+] Transforming  the bibTeX into CSL-JSON"
find . -type f -name "*.bib" | while read bibfile; do
    dir=$(dirname "$bibfile")
    pandoc -t csljson -s "$bibfile" -o "$dir/bib.json"
done 
echo ":) Done"
