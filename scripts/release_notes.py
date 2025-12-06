#!/usr/bin/env python3
"""
Extract release notes from CHANGELOG.md for a specific version.
Used by GitHub Actions to populate release body.

Usage:
    python scripts/release_notes.py v0.1.0
"""

import sys
import re


def extract_release_notes(version: str, changelog_path: str = "CHANGELOG.md") -> str:
    """Extract release notes for a specific version from CHANGELOG.md."""
    # Remove 'v' prefix if present
    version_clean = version.lstrip("v")

    try:
        with open(changelog_path, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        return f"Release {version}"

    # Pattern to match version headers: ## [0.1.0] or ## [0.1.0] - 2024-01-01
    pattern = rf"## \[{re.escape(version_clean)}\].*?\n(.*?)(?=\n## \[|\Z)"
    match = re.search(pattern, content, re.DOTALL)

    if match:
        notes = match.group(1).strip()
        return notes if notes else f"Release {version}"

    return f"Release {version}"


def main():
    if len(sys.argv) < 2:
        print("Usage: python release_notes.py <version>", file=sys.stderr)
        sys.exit(1)

    version = sys.argv[1]
    notes = extract_release_notes(version)
    print(notes)


if __name__ == "__main__":
    main()
