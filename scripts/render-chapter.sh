#!/usr/bin/env bash

# Script to render a single chapter PDF in isolation
# Usage: ./scripts/render-chapter.sh <qmd_file> <template_dir>

set -e

QMD_FILE="$1"
TEMPLATE_DIR="$2"

if [ -z "$QMD_FILE" ] || [ -z "$TEMPLATE_DIR" ]; then
    echo "Usage: $0 <qmd_file> <template_dir>"
    exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: Template directory not found: $TEMPLATE_DIR"
    exit 1
fi

# Create isolated job directory
JOB_TMP=$(mktemp -d)
# Ensure cleanup
trap 'rm -rf "$JOB_TMP"' EXIT

# Copy template content to job directory
cp -R "$TEMPLATE_DIR/"* "$JOB_TMP/"

OUTPUT_DIR=$(dirname "$QMD_FILE")
BASE=$(basename "$QMD_FILE" .qmd)
LOG_FILE="$JOB_TMP/render.log"

echo "  [START] $QMD_FILE"

# Prepare directory structure in job tmp
mkdir -p "$JOB_TMP/$OUTPUT_DIR"

# Copy the specific qmd file (if not already covered by rsync in Makefile, usually source is separate)
# In Makefile we rsyced src/ to TEMPLATE_DIR/src/. 
# So TEMPLATE_DIR already has the qmd file?
# Let's check Makefile logic: 
# rsync -a ... src/ "$$TEMPLATE_DIR/src/";
# So the qmd file IS inside TEMPLATE_DIR structure.
# But we need to run render from the correct relative path?

# Actually, the Makefile logic was:
# cp -R "$$template_dir/"* "$$job_tmp/"; \
# (cd "$$job_tmp/$$output_dir" && quarto render "$$base.qmd" ...

# So yes, the qmd file is already in JOB_TMP/OUTPUT_DIR because of the recursive copy of template (which contains src).

if cd "$JOB_TMP/$OUTPUT_DIR"; then
    # Run Quarto
    if quarto render "$BASE.qmd" --to latex --metadata standalone-pdf:true --metadata-file ../../config.yml > "$LOG_FILE" 2>&1; then
        
        TEX_FILE="$BASE.tex"
        PDF_FILE="$BASE.pdf"
        
        if [ -f "$TEX_FILE" ]; then
            # Fix document structure for standalone
            sed -i.bak 's/\\begin{document}/\\begin{document}\\mainmatter/g' "$TEX_FILE"
            
            # Helper to run latex
            run_latex() {
                lualatex -interaction=nonstopmode "$TEX_FILE" >> "$LOG_FILE" 2>&1
            }
            
            # Run Latex twice
            run_latex || true
            run_latex || true
            
            if [ -f "$PDF_FILE" ]; then
                # Move result to final destination
                # We need to move it to _book/$OUTPUT_DIR in the real project_dir
                # The script runs relative to project root? Yes, invoked from Makefile.
                
                mkdir -p "_book/$OUTPUT_DIR"
                mv "$PDF_FILE" "../../../_book/$OUTPUT_DIR/$PDF_FILE"
                
                echo "  [DONE]  $QMD_FILE"
            else
                echo "  [FAIL]  $QMD_FILE (No PDF produced)"
                echo "    Error log tail:"
                tail -n 10 "$LOG_FILE" | sed 's/^/      /'
                exit 1
            fi
        else
            echo "  [FAIL]  $QMD_FILE (No TEX produced)"
            tail -n 10 "$LOG_FILE" | sed 's/^/      /'
            exit 1
        fi
    else
        echo "  [FAIL]  $QMD_FILE (Quarto render failed)"
        tail -n 10 "$LOG_FILE" | sed 's/^/      /'
        exit 1
    fi
else
    echo "Error: Could not enter directory $JOB_TMP/$OUTPUT_DIR"
    exit 1
fi
