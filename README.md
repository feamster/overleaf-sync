# Overleaf Sync - Never Touch Overleaf Again

A complete solution for syncing Overleaf projects to GitHub and working entirely in GitHub/local environment without ever opening Overleaf's UI.

## The Problem

- People create Overleaf projects for papers
- You hate using Overleaf's interface
- You can't track updates or changes in Overleaf
- You want to work exclusively in GitHub/locally

## The Solution

This tool creates GitHub repositories for Overleaf projects with automatic bidirectional sync:
- **Hourly sync** from Overleaf (via GitHub Action)
- **Auto-sync on push/pull** (via git hooks)
- **Never open Overleaf** - work entirely in GitHub/CLI
- Integrates with your project tracker

## How It Works

**Two workflows supported:**

### Workflow 1: Overleaf-First (Someone Else Started It)
1. Someone creates an Overleaf project
2. You run `./setup-paper-repo.sh` with the project details
3. Script creates GitHub repo, sets up sync, clones locally
4. **From then on**: You only touch GitHub/local files

### Workflow 2: GitHub-First (You Start It)
1. You run `./setup-paper-repo.sh` with just a repo name
2. Script creates GitHub repo and workflow
3. You import the GitHub repo to Overleaf
4. You re-run the script with the Overleaf project ID
5. **From then on**: You only touch GitHub/local files

**In both cases:**
- GitHub Action pulls from Overleaf hourly
- Your changes automatically push back to Overleaf

## Quick Start

### Initial Setup (One-Time)

```bash
# Set GitHub token (only requirement!)
export GITHUB_TOKEN='your_github_token'
```

That's it! No Overleaf login, no Python, no installation needed.

### Creating a New Paper Repo

**Option 1: Overleaf-First** (existing Overleaf project):

```bash
# 1. Get the Overleaf project ID from the URL:
# https://www.overleaf.com/project/YOUR_PROJECT_ID_HERE

# 2. Run the setup script
./setup-paper-repo.sh "paper-name" "OVERLEAF_PROJECT_ID"

# 3. Add two GitHub secrets (script will tell you exactly what to add):
#    - OVERLEAF_PROJECT_ID
#    - OVERLEAF_GIT_TOKEN (from https://www.overleaf.com/user/settings)
```

**Option 2: GitHub-First** (you're starting the project):

```bash
# 1. Run the setup script (no Overleaf ID yet!)
./setup-paper-repo.sh "paper-name"

# 2. Import the GitHub repo to Overleaf:
#    - Go to: https://www.overleaf.com/project
#    - Click 'New Project' → 'Import from GitHub'
#    - Select your repository

# 3. Get the Overleaf project ID and re-run:
./setup-paper-repo.sh "paper-name" "OVERLEAF_PROJECT_ID"

# 4. Add GitHub secrets as usual (script will tell you)
```

**Both options result in:**
- A GitHub repository with your paper
- Automatic bidirectional sync via GitHub Actions
- Pure git workflow from then on

### If Setup Fails or You Need to Retry

```bash
# Re-run with --retry flag to fix issues without starting over
./setup-paper-repo.sh "paper-name" "OVERLEAF_PROJECT_ID" "" --retry
```

### Daily Workflow

```bash
# Pull latest changes from GitHub
cd paper-name
git pull

# Make your edits to .tex files
vim main.tex

# Commit and push - standard git workflow!
git add .
git commit -m "Update introduction"
git push

# What happens automatically:
# ✓ GitHub Action pushes your changes to Overleaf (within seconds)
# ✓ Collaborators see your changes in Overleaf immediately
# ✓ Hourly sync pulls collaborator changes to GitHub
# ✓ You see collaborator changes with: git pull
```

**That's it!** Pure git workflow, no special tools, no hooks, no `ols` needed locally.

## What Gets Set Up

For each paper repo, the script creates:

```
paper-name/
├── .github/
│   └── workflows/
│       └── overleaf-sync.yml    # Bidirectional sync with Overleaf
├── main.tex                      # Your paper files
├── references.bib
└── ...
```

The GitHub Action workflow handles:
- **On push**: Automatically pushes your commits to Overleaf
- **Hourly**: Automatically pulls collaborator changes from Overleaf to GitHub
- **Manual**: Can be triggered anytime from Actions tab

## Sync Behavior

### How It Works

The system uses **GitHub Actions only** - no local tools or hooks required:

1. **When you push to GitHub:**
   - GitHub Action automatically pushes your commits to Overleaf git remote
   - Collaborators see your changes in Overleaf immediately

2. **When collaborators edit in Overleaf:**
   - Hourly GitHub Action pulls changes from Overleaf
   - Changes appear in GitHub automatically
   - You see them with `git pull`

3. **Manual sync anytime:**
   - Trigger the workflow from Actions tab
   - Or just wait for the next hourly sync

### Automatic Syncing

- **On push to GitHub**: Immediately pushes to Overleaf
- **Hourly**: Pulls from Overleaf to GitHub (every hour on the hour)
- **Manual**: Trigger anytime from GitHub Actions tab

### Conflict Resolution

If both you and collaborators edit simultaneously:
- GitHub Action will fail on merge conflicts
- You'll receive a notification
- Resolve locally: `git pull`, fix conflicts, `git push`
- Hourly sync catches most conflicts before they become issues

## Requirements

- Git
- GitHub account with personal access token
- Overleaf account (free tier works)
- Overleaf Git Token (from Account Settings)

## Installation

No installation needed! The setup script only requires:

```bash
export GITHUB_TOKEN='your_github_token'
```

The sync happens entirely through GitHub Actions using Overleaf's git remote. No local Python tools, virtual environments, or `ols` required.

## Scripts

### `setup-overleaf-sync.py` (Recommended - Simple)
Clean Python script to add Overleaf sync to any existing GitHub repository.

**Usage:**
```bash
# Basic usage
python3 setup-overleaf-sync.py /path/to/your/repo

# With Overleaf project ID
python3 setup-overleaf-sync.py /path/to/your/repo --overleaf-id YOUR_PROJECT_ID

# Auto-commit and push
python3 setup-overleaf-sync.py /path/to/your/repo --overleaf-id YOUR_PROJECT_ID --commit
```

**What it does:**
1. Copies `overleaf-sync-workflow.yml` to `.github/workflows/` in your repo
2. Shows you the exact URL to add GitHub secrets
3. Provides instructions for the two required secrets
4. Optionally commits and pushes the workflow file

**Examples:**
```bash
# Add sync to an existing repo
python3 setup-overleaf-sync.py ~/Documents/research/my-paper --overleaf-id abc123

# Add sync and commit in one step
python3 setup-overleaf-sync.py ~/Documents/research/my-paper --overleaf-id abc123 --commit
```

### `setup-paper-repo.sh` (Legacy - Full Setup)
Full bash script that creates repositories and configures Overleaf sync.

**Usage:**
```bash
# Overleaf-first workflow
./setup-paper-repo.sh <repo-name> <overleaf-project-id> [github-org]

# GitHub-first workflow
./setup-paper-repo.sh <repo-name> [github-org]
```

**Arguments:**
- `repo-name`: Name for the GitHub repository (e.g., "fwa-paper")
- `overleaf-project-id`: (Optional for GitHub-first) ID from Overleaf URL
- `github-org`: (Optional) GitHub organization, defaults to your username

**Examples:**
```bash
# Overleaf-first (existing Overleaf project)
./setup-paper-repo.sh "network-measurement-paper" "507f1f77bcf86cd799439011"

# GitHub-first (you're starting the project)
./setup-paper-repo.sh "network-measurement-paper"
# ... then import to Overleaf and re-run with project ID
./setup-paper-repo.sh "network-measurement-paper" "507f1f77bcf86cd799439011"
```

**Note:** For most use cases with existing repos, `setup-overleaf-sync.py` is simpler and cleaner.

## Finding Your Overleaf Project ID

The project ID is in the Overleaf URL:
```
https://www.overleaf.com/project/507f1f77bcf86cd799439011
                                    ^^^^^^^^^^^^^^^^^^^^^^^^
                                    This is the project ID
```

## GitHub Secrets

The setup script will prompt you to add these secrets to your GitHub repo:
1. Go to repo Settings → Secrets and variables → Actions
2. Add `OVERLEAF_PROJECT_ID` (the ID from Overleaf URL)
3. Add `OVERLEAF_GIT_TOKEN` (from Overleaf Account Settings → Git Integration)

To get your Overleaf Git Token:
- Go to: https://www.overleaf.com/user/settings
- Scroll to 'Git Integration'
- Copy the token shown there

The script will remind you with the exact values to use.

## Integration with Project Tracker

This tool is designed to work with the project tracking system:
- Paper repos appear in your private projects list
- Hourly sync keeps tracking up to date
- Never miss collaborator updates

## Troubleshooting

### GitHub Action failing
Check that both secrets are set:
```bash
gh secret list --repo your-username/paper-name
```
Should show: `OVERLEAF_PROJECT_ID` and `OVERLEAF_GIT_TOKEN`

### Sync conflicts
If the Action fails due to conflicts:
```bash
cd paper-name
git pull  # Get latest from GitHub
# Fix any conflicts
git push  # Pushes to both GitHub and Overleaf
```

### Manual trigger
Force a sync anytime from GitHub Actions tab → Sync with Overleaf → Run workflow

## Advanced Usage

### Manual sync anytime
Go to GitHub Actions tab → "Sync with Overleaf" → "Run workflow"

### Disable auto-sync temporarily
Disable the GitHub Action workflow from the Actions tab

### Check sync status
View recent workflow runs in the Actions tab to see sync history

## Why This Is Better Than Overleaf's Native GitHub Sync

| Feature | This Tool | Overleaf Premium |
|---------|-----------|------------------|
| **Cost** | Free | Requires subscription |
| **Sync to existing repos** | ✅ Yes | ❌ No |
| **Hourly auto-sync** | ✅ Yes | Manual only |
| **CLI workflow** | ✅ Yes | Limited |
| **File limit** | None | 100 files |
| **Conflict resolution** | ✅ Yes | Limited |

## Notes

- First sync may take a moment depending on project size
- `.pdf` files are not synced (compile on Overleaf or locally with `pdflatex`)
- Pure git workflow - works on any machine with git installed
- No local dependencies or virtual environments needed

## Workflow Summary

**Your collaborators:** Continue using Overleaf as normal

**You:** Work in GitHub/locally, never open Overleaf

**Magic:** Everything stays in sync automatically 🎉
