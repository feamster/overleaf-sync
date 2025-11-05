# Overleaf Sync - Never Touch Overleaf Again

A simple tool to add automatic Overleaf sync to any GitHub repository. Work entirely in GitHub/local environment without ever opening Overleaf's UI.

## The Problem

- People create Overleaf projects for papers
- You hate using Overleaf's interface
- You can't track updates or changes in Overleaf
- You want to work exclusively in GitHub/locally

## The Solution

This tool adds automatic bidirectional sync between your GitHub repository and Overleaf:
- **Hourly sync** from Overleaf (via GitHub Action)
- **Auto-sync on push** (via GitHub Action)
- **Never open Overleaf** - work entirely in GitHub/CLI
- Works with any existing GitHub repository

## How It Works

Run the Python script on any existing GitHub repository to add Overleaf sync:

```bash
python3 setup-overleaf-sync.py /path/to/your/repo --overleaf-id YOUR_PROJECT_ID
```

The script:
1. Adds a GitHub Actions workflow to your repo
2. Tells you exactly which GitHub secrets to configure
3. Optionally commits and pushes the changes

Once set up:
- **When you push to GitHub:** Changes automatically sync to Overleaf
- **When collaborators edit in Overleaf:** Hourly sync pulls changes to GitHub
- **You work in git:** Standard git workflow, no special tools needed

## Usage

### Add Sync to an Existing Repository

```bash
# Basic usage - adds workflow file
python3 setup-overleaf-sync.py /path/to/your/repo --overleaf-id YOUR_PROJECT_ID

# With auto-commit and push
python3 setup-overleaf-sync.py /path/to/your/repo --overleaf-id YOUR_PROJECT_ID --commit
```

### Configure GitHub Secrets

After running the script, add two secrets to your GitHub repository:

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Add `OVERLEAF_PROJECT_ID` - the ID from your Overleaf project URL
3. Add `OVERLEAF_GIT_TOKEN` - from https://www.overleaf.com/user/settings (Git Integration section)

The script will show you the exact values to use and the URL where to add them.

### Finding Your Overleaf Project ID

The project ID is in the Overleaf URL:
```
https://www.overleaf.com/project/507f1f77bcf86cd799439011
                                    ^^^^^^^^^^^^^^^^^^^^^^^^
                                    This is the project ID
```

### Daily Workflow

```bash
# Pull latest changes
cd your-repo
git pull

# Make edits to .tex files
vim main.tex

# Commit and push - standard git workflow
git add .
git commit -m "Update introduction"
git push

# What happens automatically:
# ✓ GitHub Action pushes your changes to Overleaf (within seconds)
# ✓ Collaborators see your changes in Overleaf immediately
# ✓ Hourly sync pulls collaborator changes to GitHub
# ✓ You see collaborator changes with: git pull
```

## What Gets Set Up

The script adds a workflow file to your repository:

```
your-repo/
├── .github/
│   └── workflows/
│       └── overleaf-sync.yml    # Bidirectional sync with Overleaf
├── main.tex                      # Your existing paper files
├── references.bib
└── ...
```

The GitHub Action workflow handles:
- **On push**: Automatically pushes your commits to Overleaf
- **Hourly**: Automatically pulls collaborator changes from Overleaf to GitHub
- **Manual**: Can be triggered anytime from Actions tab

## Sync Behavior

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

- Python 3
- Git
- GitHub account
- Overleaf account (free tier works)
- Overleaf Git Token (from Account Settings)

## Troubleshooting

### GitHub Action failing

Check that both secrets are set:
```bash
gh secret list --repo your-username/your-repo
```
Should show: `OVERLEAF_PROJECT_ID` and `OVERLEAF_GIT_TOKEN`

### Sync conflicts

If the Action fails due to conflicts:
```bash
cd your-repo
git pull  # Get latest from GitHub
# Fix any conflicts
git push  # Pushes to both GitHub and Overleaf
```

### Manual trigger

Force a sync anytime from GitHub Actions tab → Sync with Overleaf → Run workflow

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
- No local dependencies or virtual environments needed for daily use

## Workflow Summary

**Your collaborators:** Continue using Overleaf as normal

**You:** Work in GitHub/locally, never open Overleaf

**Magic:** Everything stays in sync automatically
