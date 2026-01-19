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

# Capture project root (where script is run from)
PROJECT_ROOT="$PWD"

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

if cd "$JOB_TMP/$OUTPUT_DIR"; then
    # Run Quarto directly to PDF
    # The config.yml now includes \mainmatter via include-before-body
    if quarto render "$BASE.qmd" --to pdf --metadata standalone-pdf:true --metadata-file ../../config.yml > "$LOG_FILE" 2>&1; then
        
        PDF_FILE="$BASE.pdf"
        
        if [ -f "$PDF_FILE" ]; then
            # Move result to final destination in PROJECT_ROOT
            mkdir -p "$PROJECT_ROOT/_book/$OUTPUT_DIR"
            mv "$PDF_FILE" "$PROJECT_ROOT/_book/$OUTPUT_DIR/$PDF_FILE"
            
            echo "  [DONE]  $QMD_FILE"
        else
            echo "  [FAIL]  $QMD_FILE (No PDF produced)"
            echo "    Error log tail:"
            tail -n 20 "$LOG_FILE" | sed 's/^/      /'
            exit 1
        fi
    else
        echo "  [FAIL]  $QMD_FILE (Quarto render failed)"
        tail -n 20 "$LOG_FILE" | sed 's/^/      /'
        exit 1
    fi
else
    echo "Error: Could not enter directory $JOB_TMP/$OUTPUT_DIR"
    exit 1
fi
