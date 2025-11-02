#!/bin/bash
set -e

echo "🚀 Setting up Overleaf Sync environment..."
echo ""

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is required but not installed."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "✓ Found Python $PYTHON_VERSION"

# Create virtual environment
if [ -d "venv" ]; then
    echo "⚠️  Virtual environment already exists. Removing and recreating..."
    rm -rf venv
fi

echo "📦 Creating virtual environment..."
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

echo "📥 Installing dependencies..."
pip install --upgrade pip > /dev/null 2>&1
pip install overleaf-sync requests PyQt5 > /dev/null 2>&1

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Activate the virtual environment:"
echo "     source venv/bin/activate"
echo ""
echo "  2. Login to Overleaf (one-time):"
echo "     ols login"
echo ""
echo "  3. Set up a paper repo:"
echo "     ./setup-paper-repo.sh \"paper-name\" \"OVERLEAF_PROJECT_ID\""
echo ""
