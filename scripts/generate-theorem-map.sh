#!/bin/bash
# Generate a JSON mapping file of all theorem IDs to their chapter.section.counter numbers

OUTPUT_FILE="_book/theorem-map.json"
BOOK_DIR="_book"

echo "Generating theorem mapping..."

# Start JSON object
echo "{" > "$OUTPUT_FILE"

first_entry=true

# Find all HTML files in the book
for html_file in $(find "$BOOK_DIR/src" -name "*.html" | sort); do
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
        counter=0
        while IFS= read -r id; do
            counter=$((counter + 1))
            full_number="${chapter}.${section}.${counter}"
            
            if [ "$first_entry" = true ]; then
                first_entry=false
            else
                echo "," >> "$OUTPUT_FILE"
            fi
            
            echo -n "  \"${id}\": \"${full_number}\"" >> "$OUTPUT_FILE"
        done < <(grep -oE 'id="(def|thm|lem|cor|prp|exm|exr|cnj|alg)-[^"]+"' "$html_file" | sed 's/id="//;s/"$//')
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Generated theorem mapping at $OUTPUT_FILE"
