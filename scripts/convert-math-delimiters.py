#!/usr/bin/env python3
"""
Convert math delimiters in .qmd files:
- $...$ → \( ... \)  (inline math with spaces)
- $$...$$ → \[\n\t...\n\]  (display math with newlines and tabs)
"""

import re
import os
import glob

def convert_display_math(match):
    """Convert $$...$$ to \[...\] with proper formatting."""
    content = match.group(1).strip()
    # Check if it's already on multiple lines
    if '\n' in content:
        # Indent each line with a tab
        lines = content.split('\n')
        indented = '\n'.join('\t' + line if line.strip() else '' for line in lines)
        return f'\\[\n{indented}\n\\]'
    else:
        # Single line display math
        return f'\\[\n\t{content}\n\\]'

def convert_inline_math(match):
    """Convert $...$ to \( ... \) with spaces."""
    content = match.group(1)
    # Don't add extra spaces if content already has them
    content = content.strip()
    return f'\\( {content} \\)'

def convert_file(filepath):
    """Convert all math delimiters in a file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # First, convert display math ($$...$$) - must be done before inline
    # Match $$ followed by content (possibly multiline) followed by $$
    # Use non-greedy matching
    display_pattern = r'\$\$([\s\S]*?)\$\$'
    content = re.sub(display_pattern, convert_display_math, content)
    
    # Then convert inline math ($...$)
    # Match $ followed by content (not containing $ or newline) followed by $
    # Avoid matching \$ (escaped dollar signs)
    inline_pattern = r'(?<!\\)\$([^\$\n]+?)\$'
    content = re.sub(inline_pattern, convert_inline_math, content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    # Find all .qmd files
    qmd_files = glob.glob('src/**/*.qmd', recursive=True)
    qmd_files += glob.glob('*.qmd')  # Also check root
    qmd_files += glob.glob('config/**/*.qmd', recursive=True)
    
    modified_count = 0
    for filepath in qmd_files:
        if convert_file(filepath):
            print(f"✓ Converted: {filepath}")
            modified_count += 1
        else:
            print(f"  Unchanged: {filepath}")
    
    print(f"\n{modified_count} file(s) modified.")

if __name__ == '__main__':
    main()
