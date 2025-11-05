#!/usr/bin/env python3
"""
Simplified Overleaf sync setup for GitHub repositories.
Adds GitHub Action workflow for bidirectional sync with Overleaf.
"""

import os
import sys
import shutil
import subprocess
import argparse
from pathlib import Path


def run_command(cmd, cwd=None, check=True):
    """Run a shell command and return the result."""
    result = subprocess.run(
        cmd,
        shell=True,
        cwd=cwd,
        capture_output=True,
        text=True,
        check=False
    )
    if check and result.returncode != 0:
        print(f"Error running command: {cmd}")
        print(f"stdout: {result.stdout}")
        print(f"stderr: {result.stderr}")
        sys.exit(1)
    return result


def main():
    parser = argparse.ArgumentParser(
        description="Set up Overleaf sync for a GitHub repository"
    )
    parser.add_argument(
        "repo_path",
        help="Path to the repository (can be relative or absolute)"
    )
    parser.add_argument(
        "--overleaf-id",
        help="Overleaf project ID (optional, for verification)"
    )
    parser.add_argument(
        "--commit",
        action="store_true",
        help="Automatically commit and push the workflow file"
    )

    args = parser.parse_args()

    # Get absolute path to repo
    repo_path = Path(args.repo_path).resolve()
    if not repo_path.exists():
        print(f"Error: Repository path does not exist: {repo_path}")
        sys.exit(1)

    # Check if it's a git repo
    if not (repo_path / ".git").exists():
        print(f"Error: {repo_path} is not a git repository")
        sys.exit(1)

    print(f"Setting up Overleaf sync for: {repo_path.name}")
    print()

    # Get script directory and workflow template
    script_dir = Path(__file__).parent
    workflow_template = script_dir / "overleaf-sync-workflow.yml"

    if not workflow_template.exists():
        print(f"Error: Workflow template not found at {workflow_template}")
        sys.exit(1)

    # Create .github/workflows directory
    workflows_dir = repo_path / ".github" / "workflows"
    workflows_dir.mkdir(parents=True, exist_ok=True)

    # Copy workflow file
    workflow_dest = workflows_dir / "overleaf-sync.yml"
    shutil.copy(workflow_template, workflow_dest)
    print(f"✓ Created workflow file: .github/workflows/overleaf-sync.yml")
    print()

    # Get GitHub repo info
    result = run_command(
        "git remote get-url origin",
        cwd=repo_path,
        check=False
    )

    if result.returncode == 0:
        origin_url = result.stdout.strip()
        # Parse owner/repo from URL
        if "github.com" in origin_url:
            # Handle both HTTPS and SSH URLs
            if origin_url.startswith("https://"):
                repo_path_part = origin_url.replace("https://github.com/", "").replace(".git", "")
            else:
                repo_path_part = origin_url.split(":")[-1].replace(".git", "")

            owner, repo_name = repo_path_part.split("/")
            secrets_url = f"https://github.com/{owner}/{repo_name}/settings/secrets/actions"

            print("=" * 70)
            print("NEXT STEPS - Set up GitHub Secrets")
            print("=" * 70)
            print()
            print(f"1. Go to: {secrets_url}")
            print()
            print("2. Add two repository secrets:")
            print()
            print("   Secret 1: OVERLEAF_PROJECT_ID")
            print("   - Get this from your Overleaf project URL:")
            print("     https://www.overleaf.com/project/YOUR_PROJECT_ID_HERE")
            if args.overleaf_id:
                print(f"   - Value: {args.overleaf_id}")
            print()
            print("   Secret 2: OVERLEAF_GIT_TOKEN")
            print("   - Get this from: https://www.overleaf.com/user/settings")
            print("   - Scroll to 'Git Integration' section")
            print("   - Copy the token shown there")
            print()
            print("=" * 70)
            print()

    # Optionally commit and push
    if args.commit:
        print("Committing and pushing workflow file...")
        run_command("git add .github/workflows/overleaf-sync.yml", cwd=repo_path)
        run_command(
            'git commit -m "Add Overleaf sync GitHub Action workflow"',
            cwd=repo_path
        )
        run_command("git push", cwd=repo_path)
        print("✓ Pushed to GitHub")
        print()
    else:
        print("To commit and push the workflow:")
        print("  cd", repo_path)
        print("  git add .github/workflows/overleaf-sync.yml")
        print('  git commit -m "Add Overleaf sync workflow"')
        print("  git push")
        print()

    print("✓ Setup complete!")
    print()
    print("Once secrets are set, the workflow will:")
    print("  - Push your commits to Overleaf automatically")
    print("  - Pull from Overleaf every hour")
    print("  - Allow manual sync from Actions tab")


if __name__ == "__main__":
    main()
