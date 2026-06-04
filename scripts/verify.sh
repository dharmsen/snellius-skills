#!/bin/bash
# Verification script for snellius-skills
# This script validates that all skills are properly installed and have valid frontmatter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_ROOT/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"

echo "=== Snellius Skills Verification ==="
echo ""

# Function to validate YAML frontmatter
validate_frontmatter() {
    local skill_file="$1"
    local skill_name="$(basename "$(dirname "$skill_file")")"

    # Check if file exists
    if [ ! -f "$skill_file" ]; then
        echo "  [ERROR] $skill_name - SKILL.md not found"
        return 1
    fi

    # Check for YAML frontmatter markers
    if ! grep -q "^---" "$skill_file"; then
        echo "  [ERROR] $skill_name - Missing YAML frontmatter marker"
        return 1
    fi

    # Check for required frontmatter fields
    local missing_fields=""

    if ! grep -q "^name:" "$skill_file"; then
        missing_fields="$missing_fields name"
    fi

    if ! grep -q "^description:" "$skill_file"; then
        missing_fields="$missing_fields description"
    fi

    if [ -n "$missing_fields" ]; then
        echo "  [ERROR] $skill_name - Missing fields:$missing_fields"
        return 1
    fi

    # Extract and display skill info
    local name=$(grep "^name:" "$skill_file" | cut -d':' -f2- | xargs)
    local description=$(grep "^description:" "$skill_file" | cut -d':' -f2- | xargs | cut -c1-60)

    echo "  [OK] $name - $description..."
    return 0
}

# Function to check skill installation
check_installation() {
    local skill_name="$1"

    if [ -L "$CLAUDE_SKILLS/$skill_name" ]; then
        local target="$(readlink -f "$CLAUDE_SKILLS/$skill_name")"
        if [ -d "$target" ]; then
            return 0
        else
            echo "  [BROKEN] $skill_name - Broken symlink"
            return 1
        fi
    else
        echo "  [MISSING] $skill_name - Not installed"
        return 1
    fi
}

echo "=== Checking Installation ==="
installed=0
missing=0
broken=0

# Hardcoded skill list to avoid find issues
declare -a skill_list=(
    "snellius-core"
    "snellius-slurm"
    "snellius-storage"
    "snellius-containers"
    "snellius-nextflow"
    "snellius-snakemake"
    "snellius-ml"
    "snellius-bioinformatics"
)

for skill_name in "${skill_list[@]}"; do
    if [ -L "$CLAUDE_SKILLS/$skill_name" ]; then
        target="$(readlink -f "$CLAUDE_SKILLS/$skill_name")"
        if [ -d "$target" ]; then
            installed=$((installed + 1))
            echo "  [OK] $skill_name installed"
        else
            broken=$((broken + 1))
            echo "  [BROKEN] $skill_name - broken symlink"
        fi
    else
        missing=$((missing + 1))
        echo "  [MISSING] $skill_name - not installed"
    fi
done

echo ""
echo "Installation Status: $installed installed, $missing missing, $broken broken"
echo ""

echo "=== Validating Frontmatter ==="
valid=0
invalid=0

# Hardcoded skill paths
declare -a skill_paths=(
    "$SKILLS_DIR/core/snellius-core/SKILL.md"
    "$SKILLS_DIR/core/snellius-slurm/SKILL.md"
    "$SKILLS_DIR/core/snellius-storage/SKILL.md"
    "$SKILLS_DIR/core/snellius-containers/SKILL.md"
    "$SKILLS_DIR/workflow/snellius-nextflow/SKILL.md"
    "$SKILLS_DIR/workflow/snellius-snakemake/SKILL.md"
    "$SKILLS_DIR/domain-specific/snellius-ml/SKILL.md"
    "$SKILLS_DIR/domain-specific/snellius-bioinformatics/SKILL.md"
)

for skill_file in "${skill_paths[@]}"; do
    if [ -f "$skill_file" ]; then
        if validate_frontmatter "$skill_file"; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
        fi
    else
        echo "  [WARNING] File not found: $skill_file"
        invalid=$((invalid + 1))
    fi
done

echo ""
echo "Frontmatter Status: $valid valid, $invalid invalid"
echo ""

echo "=== Checking Reference Files ==="
refs_found=0
refs_missing=0

# Check specific reference files
declare -a ref_files=(
    "$SKILLS_DIR/core/snellius-core/references/partition-specs.md"
    "$SKILLS_DIR/core/snellius-core/references/hardware-specs.md"
    "$SKILLS_DIR/core/snellius-storage/references/filesystem-specs.md"
)

for ref_file in "${ref_files[@]}"; do
    if [ -f "$ref_file" ]; then
        echo "  [OK] $(basename "$ref_file")"
        refs_found=$((refs_found + 1))
    else
        echo "  [MISSING] $(basename "$ref_file")"
        refs_missing=$((refs_missing + 1))
    fi
done

echo ""
echo "Reference Files: $refs_found found, $refs_missing missing"
echo ""

# Summary
echo "=== Summary ==="
total=$((installed + missing + broken))
if [ $installed -eq $total ] && [ $invalid -eq 0 ]; then
    echo "✓ All skills properly installed and validated!"
    exit 0
elif [ $missing -gt 0 ] || [ $broken -gt 0 ]; then
    echo "⚠ Some skills are not properly installed"
    echo "  Run: bash scripts/install.sh"
    exit 1
elif [ $invalid -gt 0 ]; then
    echo "⚠ Some skills have invalid frontmatter"
    exit 1
else
    echo "⚠ Verification completed with warnings"
    exit 1
fi
