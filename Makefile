# Makefile for Advanced Linear Algebra Notes
#
# Features:
#   - Auto-generates chapters list from src/ directory structure
#   - Builds HTML book + full book PDF
#   - Builds individual chapter PDFs with parallel processing
#   - Git integration for easy deployment
#
# Usage:
#   make all       - Build everything (auto-detect chapters, HTML, PDFs)
#   make book      - Build HTML + full book PDF only
#   make pdfs      - Build individual chapter PDFs only
#   make update    - Update _quarto.yml chapters list only
#   make preview   - Start live preview server
#   make deploy    - Build all, commit, and push to GitHub
#   make push      - Just commit and push (no build)
#   make clean     - Remove all generated files
#   make help      - Show this help message

.PHONY: all book pdfs update preview clean help deploy push info add-part add-chapter

# Parallel jobs for individual PDF rendering
MAX_JOBS ?= 4

# GitHub URLs
GITHUB_REPO := AkizumiFox/test-notes
DEPLOY_URL := https://github.com/$(GITHUB_REPO)/deployments
PAGES_URL := https://test.akizumifox.com/

# =============================================================================
# Main targets
# =============================================================================

# Default: update chapters, build book, build individual PDFs
all: update book pdfs

# Build HTML + full book PDF
book: update
	@echo "Building HTML book + full book PDF..."
	@quarto render
	@# Generate theorem mapping for cross-references
	@./scripts/generate-theorem-map.sh
	@# Copy CNAME for custom domain
	@[ -f CNAME ] && cp CNAME _book/ || true
	@echo "Done! HTML at _book/index.html, PDF at _book/Advanced-Linear-Algebra-Notes.pdf"

# Preview the book
preview: update
	@echo "Starting preview server..."
	@quarto preview

# =============================================================================
# Auto-generate chapters list in _quarto.yml
# =============================================================================

update:
	@echo "Auto-detecting chapters from src/..."
	@# Generate the chapters section
	@{ \
		echo "  # AUTO-GENERATED CHAPTERS - Do not edit manually"; \
		echo "  # Run 'make update' to regenerate from src/ directory"; \
		echo "  chapters:"; \
		echo "    - index.qmd"; \
		for part_dir in src/ch[0-9][0-9]-*/; do \
			if [ -d "$$part_dir" ]; then \
				part_index="$${part_dir}index.qmd"; \
				if [ -f "$$part_index" ]; then \
					echo ""; \
					echo "    - part: $$part_index"; \
					echo "      chapters:"; \
					for chapter in $${part_dir}[0-9][0-9]-*.qmd; do \
						if [ -f "$$chapter" ]; then \
							echo "        - $$chapter"; \
						fi; \
					done; \
				fi; \
			fi; \
		done; \
		echo ""; \
	} > .chapters.yml.tmp
	@# Update _quarto.yml by replacing chapters section
	@awk ' \
		BEGIN { in_chapters = 0; printed = 0 } \
		/^  # AUTO-GENERATED CHAPTERS/ { in_chapters = 1; next } \
		/^  chapters:/ && !printed { \
			in_chapters = 1; \
			while ((getline line < ".chapters.yml.tmp") > 0) print line; \
			printed = 1; \
			next \
		} \
		in_chapters && /^[a-z]/ { in_chapters = 0 } \
		in_chapters && /^filters:/ { in_chapters = 0 } \
		!in_chapters { print } \
	' _quarto.yml > _quarto.yml.tmp
	@mv _quarto.yml.tmp _quarto.yml
	@rm -f .chapters.yml.tmp
	@echo "Updated _quarto.yml with $$(find src/ch*-*/ -name '[0-9][0-9]-*.qmd' 2>/dev/null | wc -l | tr -d ' ') chapter files"

# =============================================================================
# Individual chapter PDFs (parallel processing)
# =============================================================================

pdfs:
	@echo "Building individual chapter PDFs (parallel: $(MAX_JOBS) jobs)..."
	@# Create temp directory for isolated rendering
	@# Create template directory with full project structure
	@TEMPLATE_DIR=$$(mktemp -d); \
	trap 'rm -rf "$$TEMPLATE_DIR"' EXIT; \
	\
	echo "project:" > "$$TEMPLATE_DIR/_quarto.yml"; \
	echo "  type: default" >> "$$TEMPLATE_DIR/_quarto.yml"; \
	echo "latex-auto-install: true" >> "$$TEMPLATE_DIR/_quarto.yml"; \
	echo "keep-tex: true" >> "$$TEMPLATE_DIR/_quarto.yml"; \
	\
	printf '%s\n' "filters:" > "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "  - latex-environment" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "  - theorem-numbering" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "  - resolve-crossrefs" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "  - chapter-number" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "format:" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "  latex:" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "    documentclass: extbook" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "    classoption: [13.5pt, a4paper, oneside, openany]" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "    number-sections: true" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "    geometry:" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "      - margin=1.2in" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "    pdf-engine: lualatex" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "    include-in-header:" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "      - text: |" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \usepackage[quartoenv]{../../config/latex-template}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \directlua{require("../../config/strip-numbers")}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \AtBeginDocument{\let\maketitle\relax}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \usepackage{enumitem}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \setlist{itemsep=1.2em, parsep=0pt}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \newlist{customenum}{enumerate}{1}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \setlist[customenum,1]{label=\customenumprefix\arabic*, itemsep=1.2em}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \newcommand{\customenumprefix}{}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' '          \usepackage{../../config/chapter-style}' >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "    include-before-body:" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "      - text: |" >> "$$TEMPLATE_DIR/config.yml"; \
	printf '%s\n' "          \mainmatter" >> "$$TEMPLATE_DIR/config.yml"; \
	\
	\
	cp -r config "$$TEMPLATE_DIR/"; \
	cp index.qmd "$$TEMPLATE_DIR/"; \
	cp -r _extensions "$$TEMPLATE_DIR/"; \
	mkdir -p "$$TEMPLATE_DIR/_book"; \
	cp "_book/theorem-map.json" "$$TEMPLATE_DIR/_book/" 2>/dev/null || true; \
	\
	rsync -a --exclude .quarto --exclude _freeze --exclude _book src/ "$$TEMPLATE_DIR/src/"; \
	find "$$TEMPLATE_DIR/src" -name "_quarto.yml" -delete; \
	\
	if [ -n "$$TARGET_FILES" ]; then \
		QMD_FILES="$$TARGET_FILES"; \
	else \
		QMD_FILES=$$(find src/ch*-* -name '[0-9][0-9]-*.qmd' 2>/dev/null | sort); \
	fi; \
	echo "Found $$(echo "$$QMD_FILES" | wc -l | tr -d ' ') chapter files"; \
	\
	echo "$$QMD_FILES" | xargs -P $(MAX_JOBS) -I {} ./scripts/render-chapter.sh "{}" "$$TEMPLATE_DIR"
	@echo "Cleaning up auxiliary files..."
	@find . -maxdepth 4 \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \) -delete 2>/dev/null || true
	@echo "Done! PDFs are in _book/"

# =============================================================================
# Git deployment
# =============================================================================

# Commit message - can be overridden: make deploy MSG="your message"
MSG ?= "Update notes - $$(date '+%Y-%m-%d %H:%M')"

# Build everything, commit, and push
deploy: all
	@echo "Deploying to GitHub..."
	@git add -A
	@git commit -m "$(MSG)" || echo "Nothing to commit"
	@git push
	@echo "Deployed successfully!"

# Just commit and push (no build)
push:
	@echo "Pushing to GitHub..."
	@git add -A
	@git commit -m "$(MSG)" || echo "Nothing to commit"
	@git push
	@echo "Pushed successfully!"

# =============================================================================
# Project info
# =============================================================================

info:
	@echo "=== Project Info ==="
	@echo ""
	@echo "GitHub Repository: https://github.com/$(GITHUB_REPO)"
	@echo "Deployment Status: $(DEPLOY_URL)"
	@echo "Live Website:      $(PAGES_URL)"
	@echo ""
	@echo "=== Current Structure ==="
	@for part_dir in src/ch[0-9][0-9]-*/; do \
		if [ -d "$$part_dir" ]; then \
			part_name=$$(basename "$$part_dir"); \
			echo "$$part_name/"; \
			for chapter in $${part_dir}[0-9][0-9]-*.qmd; do \
				if [ -f "$$chapter" ]; then \
					echo "  └── $$(basename $$chapter)"; \
				fi; \
			done; \
		fi; \
	done
	@echo ""
	@echo "Total parts: $$(ls -d src/ch[0-9][0-9]-*/ 2>/dev/null | wc -l | tr -d ' ')"
	@echo "Total chapters: $$(find src/ch*-* -name '[0-9][0-9]-*.qmd' 2>/dev/null | wc -l | tr -d ' ')"

# =============================================================================
# Add new content
# =============================================================================

# Add a new part (chapter directory)
# Usage: make add-part NAME=topic-name
add-part:
ifndef NAME
	$(error Usage: make add-part NAME=topic-name)
endif
	@# Find next part number
	@NEXT_NUM=$$(printf "%02d" $$(($$(ls -d src/ch[0-9][0-9]-*/ 2>/dev/null | wc -l) + 1))); \
	DIR_NAME="src/ch$${NEXT_NUM}-$(NAME)"; \
	if [ -d "$$DIR_NAME" ]; then \
		echo "Error: $$DIR_NAME already exists"; \
		exit 1; \
	fi; \
	mkdir -p "$$DIR_NAME"; \
	TITLE=$$(echo "$(NAME)" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $$i=toupper(substr($$i,1,1)) tolower(substr($$i,2))}1'); \
	echo "# $$TITLE {.unnumbered}" > "$$DIR_NAME/index.qmd"; \
	echo "" >> "$$DIR_NAME/index.qmd"; \
	echo "This part covers $$TITLE." >> "$$DIR_NAME/index.qmd"; \
	echo "" >> "$$DIR_NAME/index.qmd"; \
	echo "## Overview" >> "$$DIR_NAME/index.qmd"; \
	echo "" >> "$$DIR_NAME/index.qmd"; \
	echo "In this part, we will explore:" >> "$$DIR_NAME/index.qmd"; \
	echo "" >> "$$DIR_NAME/index.qmd"; \
	echo "- **Topic 1**: Description" >> "$$DIR_NAME/index.qmd"; \
	echo "- **Topic 2**: Description" >> "$$DIR_NAME/index.qmd"; \
	echo ""; \
	echo "Created: $$DIR_NAME/"; \
	echo "  └── index.qmd"; \
	echo ""; \
	echo "Next: make add-chapter NAME=topic PART=$${NEXT_NUM}"

# Add a new chapter (subchapter file)
# Usage: make add-chapter NAME=topic-name PART=01
add-chapter:
ifndef NAME
	$(error Usage: make add-chapter NAME=topic-name PART=01)
endif
ifndef PART
	$(error Usage: make add-chapter NAME=topic-name PART=01)
endif
	@# Find the part directory
	@PART_DIR=$$(ls -d src/ch$(PART)-*/ 2>/dev/null | head -1); \
	if [ -z "$$PART_DIR" ]; then \
		echo "Error: Part $(PART) not found. Available parts:"; \
		ls -d src/ch[0-9][0-9]-*/ 2>/dev/null | sed 's/src\//  /'; \
		exit 1; \
	fi; \
	PART_DIR=$${PART_DIR%/}; \
	NEXT_NUM=$$(printf "%02d" $$(($$(ls $${PART_DIR}/[0-9][0-9]-*.qmd 2>/dev/null | wc -l) + 1))); \
	FILE_NAME="$$PART_DIR/$${NEXT_NUM}-$(NAME).qmd"; \
	if [ -f "$$FILE_NAME" ]; then \
		echo "Error: $$FILE_NAME already exists"; \
		exit 1; \
	fi; \
	CHAPTER_NUM=$$(echo $(PART) | sed 's/^0*//'); \
	TITLE=$$(echo "$(NAME)" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $$i=toupper(substr($$i,1,1)) tolower(substr($$i,2))}1'); \
	echo "---" > "$$FILE_NAME"; \
	echo "chapter-number: $$CHAPTER_NUM" >> "$$FILE_NAME"; \
	echo "filters:" >> "$$FILE_NAME"; \
	echo "  - latex-environment" >> "$$FILE_NAME"; \
	echo "  - chapter-number" >> "$$FILE_NAME"; \
	echo "format:" >> "$$FILE_NAME"; \
	echo "  pdf:" >> "$$FILE_NAME"; \
	echo "    documentclass: memoir" >> "$$FILE_NAME"; \
	echo "    classoption: [13pt, a4paper]" >> "$$FILE_NAME"; \
	echo "    number-sections: true" >> "$$FILE_NAME"; \
	echo "    pdf-engine: lualatex" >> "$$FILE_NAME"; \
	echo "    geometry: [top=30mm, left=25mm, right=25mm, bottom=30mm]" >> "$$FILE_NAME"; \
	echo "    include-in-header:" >> "$$FILE_NAME"; \
	echo "      text: |" >> "$$FILE_NAME"; \
	echo "        \usepackage[quartoenv]{../../config/latex-template}" >> "$$FILE_NAME"; \
	echo "        \directlua{require(\"../../config/strip-numbers\")}" >> "$$FILE_NAME"; \
	echo "---" >> "$$FILE_NAME"; \
	echo "" >> "$$FILE_NAME"; \
	echo '{{< include ../../config/macros.qmd >}}' >> "$$FILE_NAME"; \
	echo "" >> "$$FILE_NAME"; \
	echo "# $$TITLE" >> "$$FILE_NAME"; \
	echo "" >> "$$FILE_NAME"; \
	echo "## Introduction" >> "$$FILE_NAME"; \
	echo "" >> "$$FILE_NAME"; \
	echo "Content goes here." >> "$$FILE_NAME"; \
	echo ""; \
	echo "Created: $$FILE_NAME"; \
	echo ""; \
	echo "Run 'make update' to add to _quarto.yml"

# =============================================================================
# Mermaid diagrams (pre-compile for CI)
# =============================================================================

# Compile all mermaid blocks from qmd files to SVG for CI
# Run this locally before pushing, then commit _mermaid-cache/
mermaid:
	@./scripts/compile-mermaid.sh

# =============================================================================
# Cleanup
# =============================================================================

clean:
	@echo "Cleaning generated files..."
	@rm -rf _book
	@rm -rf .quarto
	@find . -name "*_files" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -maxdepth 4 \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \) -delete 2>/dev/null || true
	@echo "Clean complete."

# =============================================================================
# Help
# =============================================================================

help:
	@echo "Advanced Linear Algebra Notes - Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Build targets:"
	@echo "  all        - Build everything (update chapters, HTML+PDF, individual PDFs)"
	@echo "  book       - Build HTML book + full book PDF"
	@echo "  pdfs       - Build individual chapter PDFs (parallel processing)"
	@echo "  update     - Auto-update _quarto.yml chapters from src/ directory"
	@echo "  preview    - Start live preview server"
	@echo "  clean      - Remove all generated files"
	@echo ""
	@echo "Git targets:"
	@echo "  deploy     - Build all, then commit and push to GitHub"
	@echo "  push       - Just commit and push (no build)"
	@echo "  info       - Show project URLs and structure"
	@echo ""
	@echo "Content creation:"
	@echo "  add-part NAME=...       - Create new part directory with index.qmd"
	@echo "  add-chapter NAME=... PART=...  - Add chapter file to existing part"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy                        # Build and push with auto timestamp"
	@echo "  make deploy MSG=\"Add ch04\"         # Build and push with custom message"
	@echo "  make push MSG=\"Fix typo\"           # Quick push without rebuilding"
	@echo "  make add-part NAME=inner-products  # Create src/ch04-inner-products/"
	@echo "  make add-chapter NAME=norms PART=04  # Create 01-norms.qmd in part 04"
	@echo "  make info                          # Show URLs and project structure"
	@echo ""
	@echo "Environment variables:"
	@echo "  MAX_JOBS - Number of parallel jobs for PDF rendering (default: 4)"
	@echo "  MSG      - Git commit message (default: auto timestamp)"
	@echo ""
	@echo "URLs:"
	@echo "  Website:    $(PAGES_URL)"
	@echo "  Deployment: $(DEPLOY_URL)"
