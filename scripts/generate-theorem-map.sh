#!/usr/bin/env bash
# Generate a JSON mapping file of all theorem IDs to their chapter.section.counter numbers

OUTPUT_FILE="theorem-map.json"
BOOK_DIR="_book"

echo "Generating theorem mapping..."

# Start JSON object
echo "{" > "$OUTPUT_FILE"

first_entry=true

# Find all HTML files in the book
# During preview, Quarto might serve from a temp dir, but let's check _book first
HTML_FILES=$(find "$BOOK_DIR/src" -name "*.html" 2>/dev/null | sort)

if [ -z "$HTML_FILES" ]; then
    echo "Warning: No HTML files found in $BOOK_DIR/src. Creating empty mapping."
    echo "{}" > "$OUTPUT_FILE"
    echo "window.theoremMap = {};" > "$JS_OUTPUT_FILE"
    exit 0
fi

for html_file in $HTML_FILES; do
    # Extract chapter and section from path
    # Pattern: _book/src/chXX-name/YY-name.html
    if [[ $html_file =~ ch([0-9]+)-[^/]+/([0-9]+)-[^/]+\.html$ ]]; then
        chapter=${BASH_REMATCH[1]}
        section=${BASH_REMATCH[2]}
        
        # Remove leading zeros
        chapter=$((10#$chapter))
        section=$((10#$section))
        
        # Extract theorem IDs from HTML in order
        # Looking for id="def-..." or id="thm-..." etc.
        
        # Initialize separate counters
        count_thm=0
        count_lem=0
        count_cor=0
        count_prp=0
        count_def=0
        count_exr=0
        count_alg=0
        
        # We need to process IDs sequentially to respect file order
        while IFS= read -r id; do
            prefix=$(echo "$id" | cut -d'-' -f1)
            
            should_map=false
            current_count=0
            
            case "$prefix" in
                "thm")
                    count_thm=$((count_thm + 1))
                    current_count=$count_thm
                    should_map=true
                    ;;
                "lem")
                    count_lem=$((count_lem + 1))
                    current_count=$count_lem
                    should_map=true
                    ;;
                "cor")
                    count_cor=$((count_cor + 1))
                    current_count=$count_cor
                    should_map=true
                    ;;
                "prp")
                    count_prp=$((count_prp + 1))
                    current_count=$count_prp
                    should_map=true
                    ;;
                "def")
                    count_def=$((count_def + 1))
                    current_count=$count_def
                    should_map=true
                    ;;
                "exr")
                    count_exr=$((count_exr + 1))
                    current_count=$count_exr
                    should_map=true
                    ;;
                "alg")
                    count_alg=$((count_alg + 1))
                    current_count=$count_alg
                    should_map=true
                    ;;
            esac
            
            if [ "$should_map" = true ]; then
                full_number="${chapter}.${section}.${current_count}"
                
                if [ "$first_entry" = true ]; then
                    first_entry=false
                else
                    echo "," >> "$OUTPUT_FILE"
                fi
                
                echo -n "  \"${id}\": \"${full_number}\"" >> "$OUTPUT_FILE"
            fi
        done < <(grep -oE 'id="(def|thm|lem|cor|prp|exm|exr|cnj|alg)-[^"]+"' "$html_file" | sed 's/id="//;s/"$//')
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Generated theorem mapping at $OUTPUT_FILE"

# Also generate JS file for client-side MathJax access
JS_OUTPUT_FILE="theorem-map.js"
echo "window.theoremMap = " > "$JS_OUTPUT_FILE"
cat "$OUTPUT_FILE" >> "$JS_OUTPUT_FILE"
echo ";" >> "$JS_OUTPUT_FILE"
echo "Generated JS mapping at $JS_OUTPUT_FILE"
