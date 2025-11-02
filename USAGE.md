# How to Use This

## One-Time Setup

```bash
# Set GitHub token (that's all you need!)
export GITHUB_TOKEN='your_github_token'
```

No virtual environment. No ols. No Overleaf login. Just git!

## Create a Paper Repo

```bash
# 1. Get Overleaf project ID from URL
# https://www.overleaf.com/project/507f1f77bcf86cd799439011
#                                 ^^^^^^^^^^^^^^^^^^^^^^^^

# 2. Run the script
./setup-paper-repo.sh "my-paper" "507f1f77bcf86cd799439011"

# 3. Add GitHub secrets (script tells you exactly what to add)
# Go to: https://github.com/USERNAME/my-paper/settings/secrets/actions
# Add these two secrets:
#   OVERLEAF_PROJECT_ID = 507f1f77bcf86cd799439011
#   OVERLEAF_GIT_TOKEN = <from Overleaf Account Settings → Git Integration>
#
# To get OVERLEAF_GIT_TOKEN:
#   - Go to: https://www.overleaf.com/user/settings
#   - Scroll to 'Git Integration'
#   - Copy the token shown there
```

## What You Get

- GitHub repo created
- Overleaf project cloned locally
- GitHub Action that syncs bidirectionally:
  - Pushes your commits to Overleaf immediately
  - Pulls collaborator changes from Overleaf every hour
- Paper appears in your project tracker

## Daily Work

```bash
cd my-paper

# Standard git workflow - no special commands!
vim main.tex
git add .
git commit -m "Update intro"
git push  # Automatically goes to GitHub AND Overleaf
```

## If Something Failed

```bash
# Re-run to fix issues without starting over
./setup-paper-repo.sh "my-paper" "507f1f77bcf86cd799439011" "" --retry
```

## How Sync Works

**Pure git workflow via GitHub Actions:**

1. **When you push to GitHub:**
   - GitHub Action immediately pushes to Overleaf git remote
   - Collaborators see your changes in Overleaf within seconds

2. **When collaborators edit in Overleaf:**
   - Hourly GitHub Action pulls changes to GitHub
   - You see their changes with: `git pull`

3. **Manual sync anytime:**
   - Go to GitHub Actions tab → "Sync with Overleaf" → "Run workflow"

**No local tools needed!** Just standard git commands: commit, push, pull.

## That's It!

You never open Overleaf. Your project tracker shows all paper activity. Collaborators keep using Overleaf. Everyone happy.
