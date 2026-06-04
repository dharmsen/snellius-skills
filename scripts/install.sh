#!/bin/bash
# Installation script for snellius-skills
# This script installs all snellius skills into Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_ROOT/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"

echo "=== Snellius Skills Installation ==="
echo "Project root: $PROJECT_ROOT"
echo "Skills directory: $SKILLS_DIR"
echo "Claude skills directory: $CLAUDE_SKILLS"
echo ""

# Create Claude skills directory if it doesn't exist
mkdir -p "$CLAUDE_SKILLS"

# Function to create symbolic link
install_skill() {
    local skill_path="$1"
    local skill_name="$(basename "$skill_path")"

    if [ -e "$CLAUDE_SKILLS/$skill_name" ]; then
        echo "  [SKIP] $skill_name already installed"
        return 0
    fi

    echo "  [INSTALL] $skill_name"
    ln -s "$skill_path" "$CLAUDE_SKILLS/$skill_name"
}

# Count total skills
total=0
installed=0
skipped=0

# List of all skill directories (hardcoded to avoid find issues)
declare -a skill_list=(
    "$SKILLS_DIR/core/snellius-core"
    "$SKILLS_DIR/core/snellius-slurm"
    "$SKILLS_DIR/core/snellius-storage"
    "$SKILLS_DIR/core/snellius-containers"
    "$SKILLS_DIR/workflow/snellius-nextflow"
    "$SKILLS_DIR/workflow/snellius-snakemake"
    "$SKILLS_DIR/domain-specific/snellius-ml"
    "$SKILLS_DIR/domain-specific/snellius-bioinformatics"
)

for skill_dir in "${skill_list[@]}"; do
    # Check if skill directory exists
    if [ ! -d "$skill_dir" ]; then
        echo "  [WARNING] Skill directory not found: $skill_dir"
        continue
    fi

    total=$((total + 1))

    # Extract skill name from directory path
    skill_name="$(basename "$skill_dir")"

    if [ -e "$CLAUDE_SKILLS/$skill_name" ]; then
        echo "  [SKIP] $skill_name already installed"
        skipped=$((skipped + 1))
    else
        install_skill "$skill_dir"
        installed=$((installed + 1))
    fi
done

echo ""
echo "=== Installation Summary ==="
echo "Total skills found: $total"
echo "Newly installed: $installed"
echo "Already present: $skipped"
echo ""

# Verify installation
echo "=== Verifying Installation ==="
missing=0
for skill_dir in "${skill_list[@]}"; do
    if [ ! -d "$skill_dir" ]; then
        continue
    fi
    skill_name="$(basename "$skill_dir")"
    if [ ! -L "$CLAUDE_SKILLS/$skill_name" ]; then
        echo "  [MISSING] $skill_name"
        missing=$((missing + 1))
    fi
done

if [ $missing -eq 0 ]; then
    echo "All skills verified!"
    echo ""
    echo "Installed skills:"
    for link in "$CLAUDE_SKILLS"/snellius-*; do
        if [ -L "$link" ]; then
            echo "  $(basename "$link")"
        fi
    done
    echo ""
    echo "Installation complete!"
else
    echo "Warning: $missing skills could not be verified"
    exit 1
fi
