#!/bin/bash
#
# build-skill-for-web.sh - Create Claude Web-compatible skill ZIP archives
#
# Usage: ./build-skill-for-web.sh <skill-directory> [output-directory]
#
# This script creates a ZIP archive from a Claude Code skill directory,
# filtering frontmatter to only include Claude Web-allowed fields:
# name, description, license, compatibility, metadata
# (strips: allowed-tools, version, and any other custom fields)
#
# Arguments:
#   skill-directory   Path to the skill directory (must contain SKILL.md)
#   output-directory  Optional. Where to save the ZIP (default: current directory)
#
# Example:
#   ./build-skill-for-web.sh ./plugins/llm-author/skills/prompt-engineering
#   ./build-skill-for-web.sh ./plugins/llm-author/skills/prompt-engineering ./dist
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print error and exit
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Print success message
success() {
    echo -e "${GREEN}$1${NC}"
}

# Print info message
info() {
    echo -e "${YELLOW}$1${NC}"
}

# Check for required commands
check_dependencies() {
    for cmd in zip sed mktemp basename dirname; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command '$cmd' not found"
        fi
    done
}

# Extract skill name from SKILL.md frontmatter
get_skill_name() {
    local skill_file="$1"
    local name

    # Extract name from YAML frontmatter
    name=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep -E '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '\r')

    if [[ -z "$name" ]]; then
        # Fallback to directory name
        name=$(basename "$(dirname "$skill_file")")
    fi

    # Sanitize name for filename (lowercase, replace spaces with hyphens)
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-_'
}

# Filter SKILL.md frontmatter to only include Claude Web-allowed fields
# Claude Web only accepts: name, description, license, allowed-tools, compatibility, metadata
# However, allowed-tools is non-functional in Claude Web, so we strip it too
filter_frontmatter_fields() {
    local input_file="$1"
    local output_file="$2"

    # Fields allowed by Claude Web (from error: "properties must be in (...)")
    # Note: allowed-tools is accepted by schema but non-functional in Claude Web
    local allowed_fields="name|description|license|compatibility|metadata"

    # Use awk to filter frontmatter fields (BSD awk compatible)
    awk -v allowed="$allowed_fields" '
    BEGIN {
        in_frontmatter = 0
        frontmatter_end = 0
    }

    # First line must be ---
    NR == 1 && /^---$/ {
        in_frontmatter = 1
        print
        next
    }

    # End of frontmatter
    in_frontmatter && /^---$/ {
        in_frontmatter = 0
        frontmatter_end = 1
        print
        next
    }

    # Inside frontmatter: only print allowed fields
    in_frontmatter {
        # Check if line starts with a field name followed by colon
        if (/^[a-zA-Z][a-zA-Z0-9_-]*:/) {
            # Extract field name (everything before the colon)
            field = $0
            sub(/:.*$/, "", field)
            # Check if field is in allowed list
            if (field ~ "^(" allowed ")$") {
                print
            }
        }
        next
    }

    # After frontmatter: print everything
    frontmatter_end {
        print
    }
    ' "$input_file" > "$output_file"
}

# Main function
main() {
    # Check dependencies
    check_dependencies

    # Parse arguments
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill-directory> [output-directory]"
        echo ""
        echo "Creates a Claude Web-compatible ZIP archive from a skill directory."
        echo ""
        echo "Arguments:"
        echo "  skill-directory   Path to the skill directory (must contain SKILL.md)"
        echo "  output-directory  Optional. Where to save the ZIP (default: current directory)"
        exit 1
    fi

    local skill_dir="$1"
    local output_dir="${2:-.}"

    # Resolve to absolute paths
    skill_dir=$(cd "$skill_dir" 2>/dev/null && pwd) || error "Skill directory not found: $1"

    # Validate skill directory
    local skill_file="$skill_dir/SKILL.md"
    if [[ ! -f "$skill_file" ]]; then
        error "SKILL.md not found in $skill_dir"
    fi

    # Create output directory if needed
    mkdir -p "$output_dir"
    output_dir=$(cd "$output_dir" && pwd)

    # Get skill name for ZIP filename
    local skill_name
    skill_name=$(get_skill_name "$skill_file")
    info "Building ZIP for skill: $skill_name"

    # Create temp directory
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT

    # Create skill directory in temp
    local temp_skill_dir="$temp_dir/$skill_name"
    mkdir -p "$temp_skill_dir"

    # Copy all files to temp directory
    info "Copying skill files..."
    cp -r "$skill_dir"/* "$temp_skill_dir/"

    # Filter frontmatter to only include Claude Web-allowed fields
    info "Filtering frontmatter to Claude Web-allowed fields..."
    local temp_skill_file="$temp_skill_dir/SKILL.md"
    local processed_skill_file="$temp_skill_dir/SKILL.md.processed"

    filter_frontmatter_fields "$temp_skill_file" "$processed_skill_file"
    mv "$processed_skill_file" "$temp_skill_file"

    # Create ZIP archive
    local zip_file="$output_dir/${skill_name}.zip"
    info "Creating ZIP archive..."

    # Remove existing ZIP if present
    rm -f "$zip_file"

    # Create ZIP from temp directory
    (cd "$temp_dir" && zip -r "$zip_file" "$skill_name" -x "*.DS_Store" -x "*__MACOSX*")

    success "Created: $zip_file"

    # Show ZIP contents
    echo ""
    echo "ZIP contents:"
    unzip -l "$zip_file" | grep -E "^\s+[0-9]+" | awk '{print $4}'
}

# Run main function
main "$@"
