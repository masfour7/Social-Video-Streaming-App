#!/bin/bash
# Run this once before pushing to GitHub.
# Untracks Replit-specific files (keeps them locally for Replit to work).
git rm --cached .replit replit.md server.js 2>/dev/null
git add -A
git commit -m "chore: add web-demo, docs, LICENSE, and professional README"
echo "Done. Push with: git push"
