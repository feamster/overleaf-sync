#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 <repo-name> <overleaf-project-id> [github-org] [--retry]${NC}"
    echo ""
    echo "Example:"
    echo "  $0 \"my-paper\" \"507f1f77bcf86cd799439011\""
    echo "  $0 \"my-paper\" \"507f1f77bcf86cd799439011\" \"noise-lab\""
    echo "  $0 \"my-paper\" \"507f1f77bcf86cd799439011\" \"\" --retry  # Retry failed setup"
    echo ""
    echo "Find your Overleaf project ID in the URL:"
    echo "  https://www.overleaf.com/project/YOUR_PROJECT_ID"
    exit 1
fi

REPO_NAME=$1
OVERLEAF_ID=$2
GITHUB_ORG=${3:-}
RETRY_MODE=false

# Check for --retry flag
for arg in "$@"; do
    if [ "$arg" = "--retry" ]; then
        RETRY_MODE=true
    fi
done

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}⚠️  Virtual environment not activated!${NC}"
    echo "Please run: source venv/bin/activate"
    exit 1
fi

# Check if ols is installed
if ! command -v ols &> /dev/null; then
    echo -e "${RED}❌ Error: ols (overleaf-sync) is not installed${NC}"
    echo "Run ./install.sh first"
    exit 1
fi

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Error: GITHUB_TOKEN environment variable not set${NC}"
    echo "Please set it with: export GITHUB_TOKEN='your_github_token'"
    exit 1
fi

# Determine GitHub owner
if [ -n "$GITHUB_ORG" ]; then
    GITHUB_OWNER=$GITHUB_ORG
else
    # Get username from GitHub API
    GITHUB_OWNER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | python3 -c "import sys, json; print(json.load(sys.stdin)['login'])")
fi

echo -e "${BLUE}🚀 Setting up paper repository: $REPO_NAME${NC}"
echo -e "${BLUE}   Overleaf Project: $OVERLEAF_ID${NC}"
echo -e "${BLUE}   GitHub Owner: $GITHUB_OWNER${NC}"
echo ""

# Step 1: Create GitHub repository
echo -e "${GREEN}📝 Step 1: Creating GitHub repository...${NC}"

# Check if repo already exists
REPO_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_OWNER/$REPO_NAME")

if [ "$REPO_EXISTS" = "200" ]; then
    echo -e "${YELLOW}   Repository $GITHUB_OWNER/$REPO_NAME already exists${NC}"
    if [ "$RETRY_MODE" = false ]; then
        read -p "   Do you want to use the existing repository? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "   Aborted."
            exit 1
        fi
    else
        echo -e "${BLUE}   Using existing repository (retry mode)${NC}"
    fi
else
    # Create the repository
    CREATE_PAYLOAD=$(cat <<EOF
{
  "name": "$REPO_NAME",
  "description": "LaTeX paper synced from Overleaf",
  "private": true,
  "auto_init": false
}
EOF
)

    if [ -n "$GITHUB_ORG" ]; then
        # Create in organization
        CREATE_RESPONSE=$(curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/orgs/$GITHUB_ORG/repos" \
            -d "$CREATE_PAYLOAD")
    else
        # Create in user account
        CREATE_RESPONSE=$(curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/user/repos" \
            -d "$CREATE_PAYLOAD")
    fi

    # Check if creation was successful
    if echo "$CREATE_RESPONSE" | grep -q "\"full_name\""; then
        echo -e "${GREEN}   ✓ Created repository: https://github.com/$GITHUB_OWNER/$REPO_NAME${NC}"
    else
        echo -e "${RED}   ❌ Failed to create repository${NC}"
        echo "$CREATE_RESPONSE" | python3 -m json.tool
        exit 1
    fi
fi

# Step 2: Clone Overleaf project using ols
echo ""
echo -e "${GREEN}📥 Step 2: Syncing Overleaf project with ols...${NC}"

if [ -d "$REPO_NAME" ]; then
    if [ "$RETRY_MODE" = false ]; then
        echo -e "${YELLOW}   Directory $REPO_NAME already exists${NC}"
        read -p "   Do you want to remove it and re-sync? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$REPO_NAME"
        else
            echo "   Using existing directory"
        fi
    else
        echo -e "${BLUE}   Using existing directory (retry mode)${NC}"
    fi
fi

if [ ! -d "$REPO_NAME" ]; then
    mkdir -p "$REPO_NAME"
fi

cd "$REPO_NAME"

# Initialize git repo if needed
if [ ! -d ".git" ]; then
    git init
    echo -e "${GREEN}   ✓ Initialized git repository${NC}"
fi

# Add GitHub remote if not exists
if ! git remote | grep -q "^origin$"; then
    git remote add origin "https://github.com/$GITHUB_OWNER/$REPO_NAME.git"
    echo -e "${GREEN}   ✓ Added GitHub remote${NC}"
fi

# Sync from Overleaf using ols
echo "   Running ols to sync from Overleaf..."
echo "   (This will use the project name: $REPO_NAME)"

if ols -n "$REPO_NAME" -p . 2>&1; then
    echo -e "${GREEN}   ✓ Successfully synced from Overleaf${NC}"
else
    echo -e "${YELLOW}   ⚠️  ols sync had issues. This might be normal on first run.${NC}"
    echo "   Try running: cd $REPO_NAME && ols"
fi

cd ..
cd "$REPO_NAME"

# Step 3: Create GitHub Action workflow
echo ""
echo -e "${GREEN}⚙️  Step 3: Setting up GitHub Action for hourly sync...${NC}"

mkdir -p .github/workflows

cat > .github/workflows/overleaf-sync.yml << 'WORKFLOW_EOF'
name: Sync with Overleaf

on:
  push:
    branches: [master, main]
  schedule:
    - cron: '0 * * * *'  # Every hour
  workflow_dispatch:  # Allow manual triggering

permissions:
  contents: write  # Allow the action to push commits

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git config --global user.name "github-actions[bot]"

      - name: Setup Overleaf remote
        env:
          OVERLEAF_PROJECT_ID: ${{ secrets.OVERLEAF_PROJECT_ID }}
          OVERLEAF_GIT_TOKEN: ${{ secrets.OVERLEAF_GIT_TOKEN }}
        run: |
          # Add Overleaf git remote if not exists
          if ! git remote | grep -q "^overleaf$"; then
            git remote add overleaf "https://git@git.overleaf.com/${OVERLEAF_PROJECT_ID}"
          fi

          # Configure git credential helper to use the token
          git config credential.helper store
          echo "https://git:${OVERLEAF_GIT_TOKEN}@git.overleaf.com" > ~/.git-credentials

      - name: Pull from Overleaf (scheduled/manual trigger)
        if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
        run: |
          # Fetch from Overleaf
          git fetch overleaf master

          # Merge changes from Overleaf (if any)
          if [ -n "$(git rev-list HEAD..overleaf/master 2>/dev/null)" ]; then
            git merge overleaf/master -m "Auto-sync from Overleaf [skip ci]" --no-edit --allow-unrelated-histories || {
              echo "Merge conflict detected. Manual resolution required."
              exit 1
            }

            # Push to GitHub
            BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
            git push origin $BRANCH_NAME
          fi

      - name: Push to Overleaf (on push event)
        if: github.event_name == 'push'
        run: |
          # Push to Overleaf
          git push overleaf HEAD:master || {
            echo "Failed to push to Overleaf. May need manual resolution."
            exit 1
          }
WORKFLOW_EOF

echo -e "${GREEN}   ✓ Created .github/workflows/overleaf-sync.yml${NC}"

# Step 4: Initial commit and push to GitHub
echo ""
echo -e "${GREEN}📤 Step 4: Pushing to GitHub...${NC}"

# Add all files
git add .

# Commit
git commit -m "Initial sync from Overleaf

🤖 Generated with overleaf-sync setup script" || echo "Nothing new to commit"

# Determine the branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Set upstream and push
if git push -u origin $BRANCH_NAME 2>&1; then
    echo -e "${GREEN}   ✓ Pushed to GitHub${NC}"
else
    echo -e "${YELLOW}   ⚠️  Push had issues, you may need to push manually${NC}"
fi

cd ..

# Step 5: Show setup completion and next steps
echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo ""
echo "1. Add GitHub secrets for the hourly sync workflow:"
echo "   Go to: https://github.com/$GITHUB_OWNER/$REPO_NAME/settings/secrets/actions"
echo ""
echo "   Add these two secrets:"
echo -e "   ${YELLOW}OVERLEAF_PROJECT_ID${NC} = $OVERLEAF_ID"
echo -e "   ${YELLOW}OVERLEAF_GIT_TOKEN${NC} = <get from Overleaf Account Settings → Git Integration>"
echo ""
echo "   To get your Overleaf Git Token:"
echo "   - Go to: https://www.overleaf.com/user/settings"
echo "   - Scroll to 'Git Integration'"
echo "   - Copy the token shown there"
echo ""
echo "2. Start working - pure git workflow, no special tools needed!"
echo -e "   ${YELLOW}cd $REPO_NAME${NC}"
echo -e "   ${YELLOW}vim main.tex${NC}"
echo -e "   ${YELLOW}git add . && git commit -m \"Update paper\"${NC}"
echo -e "   ${YELLOW}git push${NC}"
echo ""
echo "   What happens automatically:"
echo "   ✓ Your push triggers GitHub Action → pushes to Overleaf"
echo "   ✓ Collaborators see your changes in Overleaf immediately"
echo "   ✓ Hourly sync pulls collaborator changes from Overleaf to GitHub"
echo "   ✓ You see collaborator changes with: git pull"
echo ""
echo -e "${GREEN}🎉 You're all set! The repo will appear in your project tracker!${NC}"
echo ""
echo "If you had issues, re-run with:"
echo "  $0 \"$REPO_NAME\" \"$OVERLEAF_ID\" \"$GITHUB_ORG\" --retry"
echo ""
