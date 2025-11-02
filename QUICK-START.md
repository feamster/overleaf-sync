# Quick Start Guide

## First Time Setup (30 seconds)

```bash
# Set GitHub token (that's it!)
export GITHUB_TOKEN='your_github_token'
```

No Overleaf login needed. No Python, no installation, no dependencies.

## Creating a Paper Repo (2 minutes)

```bash
# 1. Get the Overleaf project ID from the URL
# Example URL: https://www.overleaf.com/project/507f1f77bcf86cd799439011
#              The ID is: ^^^^^^^^^^^^^^^^^^^^^^^^

# 2. Run the setup script
cd /path/to/overleaf-sync
./setup-paper-repo.sh "my-paper-name" "507f1f77bcf86cd799439011"

# 3. Add GitHub secrets (script will tell you exactly what to add):
#    Go to: Settings → Secrets → Actions
#    Add two secrets:
#      - OVERLEAF_PROJECT_ID = 507f1f77bcf86cd799439011
#      - OVERLEAF_GIT_TOKEN = <from https://www.overleaf.com/user/settings>
```

## If Setup Had Issues

```bash
# Re-run with --retry to fix without starting over
./setup-paper-repo.sh "my-paper-name" "507f1f77bcf86cd799439011" "" --retry
```

## Daily Workflow

```bash
# Standard git workflow - no special commands!
cd my-paper-name

# Pull latest
git pull

# Edit your paper
vim main.tex

# Commit and push
git add .
git commit -m "Update introduction"
git push

# What happens automatically:
# ✓ GitHub Action pushes to Overleaf (within seconds)
# ✓ Collaborators see your changes immediately
# ✓ Hourly sync pulls their changes to GitHub
# ✓ You see their changes with: git pull
```

## That's It!

- Pure git workflow - just commit, push, pull
- Hourly sync runs automatically via GitHub Action
- Your changes go to Overleaf automatically on every push
- Collaborator changes come to GitHub every hour
- You never open Overleaf 🎉

## Troubleshooting

### GitHub Action not working?
Check that you added both secrets:
```bash
gh secret list --repo your-username/my-paper-name
```
Should show: `OVERLEAF_PROJECT_ID` and `OVERLEAF_GIT_TOKEN`

### Manual sync needed?
Go to GitHub Actions tab → "Sync with Overleaf" → "Run workflow"

### Conflicts?
```bash
git pull  # Get latest
# Fix conflicts
git push  # Pushes to GitHub and Overleaf
```
