#!/opt/homebrew/bin/bash

# Generate Alfred workflows showcase for public sharing
# Outputs safe metadata only - no credentials or code

set -e

ALFRED_WORKFLOWS_DIR="$HOME/Library/CloudStorage/Dropbox/settings/alfred/Alfred.alfredpreferences/workflows"
OUTPUT_FILE="$(cd "$(dirname "$0")" && pwd)/dotfiles/alfred/workflows-i-use.md"

echo "========================================="
echo "Generating Alfred Workflows Showcase..."
echo "========================================="
echo ""

# Check if Alfred workflows directory exists
if [ ! -d "$ALFRED_WORKFLOWS_DIR" ]; then
    echo "❌ ERROR: Alfred workflows directory not found: $ALFRED_WORKFLOWS_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Count workflows
workflow_count=$(find "$ALFRED_WORKFLOWS_DIR" -name "info.plist" -type f | wc -l | tr -d ' ')
echo "Found $workflow_count workflows"
echo ""

# Start markdown file
cat > "$OUTPUT_FILE" << 'EOF'
# Alfred Workflows I Use

A showcase of the Alfred workflows that power my productivity. Feel free to explore and discover new workflows!

EOF

echo "Last updated: $(date "+%Y-%m-%d %H:%M:%S")" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Total workflows: $workflow_count" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat >> "$OUTPUT_FILE" << 'EOF'
> **Note**: This is a showcase list only. Actual workflow files are not included for security reasons (may contain API keys). Find these workflows on [Alfred Gallery](https://alfred.app/workflows/), [Packal](http://www.packal.org/), or GitHub.

## Workflows

| Name | Bundle ID | Description | Version |
|------|-----------|-------------|---------|
EOF

# Parse each workflow's info.plist
processed=0
for plist in "$ALFRED_WORKFLOWS_DIR"/*/info.plist; do
    if [ -f "$plist" ]; then
        # Extract safe metadata using PlistBuddy
        name=$(/usr/libexec/PlistBuddy -c "Print :name" "$plist" 2>/dev/null || echo "Unknown")
        bundleid=$(/usr/libexec/PlistBuddy -c "Print :bundleid" "$plist" 2>/dev/null || echo "Unknown")
        description=$(/usr/libexec/PlistBuddy -c "Print :description" "$plist" 2>/dev/null || echo "")
        version=$(/usr/libexec/PlistBuddy -c "Print :version" "$plist" 2>/dev/null || echo "")

        # Clean up values (remove newlines, extra spaces, pipe characters that would break table)
        name=$(echo "$name" | tr -d '\n' | tr '|' '-')
        bundleid=$(echo "$bundleid" | tr -d '\n' | tr '|' '-')
        description=$(echo "$description" | tr -d '\n' | tr '|' '-')
        version=$(echo "$version" | tr -d '\n' | tr '|' '-')

        # Write to markdown table
        echo "| $name | $bundleid | $description | $version |" >> "$OUTPUT_FILE"

        processed=$((processed + 1))
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat >> "$OUTPUT_FILE" << 'EOF'
## How to Find These Workflows

Search for workflows by name on:
- [Alfred Gallery](https://alfred.app/workflows/) - Official Alfred workflow gallery
- [Packal](http://www.packal.org/) - Community workflow repository
- GitHub - Many workflows are open source

## Categories

My workflows help with:
- **Productivity**: Snippet transformers, clipboard managers, timers
- **Development**: Code snippets, GitHub integration, documentation search
- **System**: File navigation, app launching, system controls
- **Web**: Search engines, API integrations, bookmarks

---

*Note: Actual workflow files are backed up separately via Dropbox (not in this public repo).*
EOF

echo ""
echo "========================================="
echo "✓ Showcase generation complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  • Processed: $processed workflows"
echo "  • Output: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Review output: cat $OUTPUT_FILE"
echo "  2. Check for sensitive data: grep -i 'api.key\\|token\\|password\\|secret' $OUTPUT_FILE"
echo "  3. Integrate with sync script"
echo ""
