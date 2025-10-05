#!/bin/bash
# Self-contained GitHub setup script for webapp deployment template
# This script can be committed to the template repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 GitHub Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load configuration
if [ ! -f "$PROJECT_ROOT/deploy-config.env" ]; then
    echo "❌ deploy-config.env not found!"
    echo "   Make sure you're running this from the project root."
    exit 1
fi

source "$PROJECT_ROOT/deploy-config.env"

echo "📝 Configuration:"
echo "   APP_NAME: $APP_NAME"
echo "   DOMAIN: $DOMAIN"
echo "   DEPLOY_HOST: $DEPLOY_HOST"
echo ""

# Function to check if gh CLI is installed
check_gh_cli() {
    if command -v gh &> /dev/null; then
        echo "✅ GitHub CLI (gh) is already installed"
        gh --version
        return 0
    else
        return 1
    fi
}

# Function to install gh CLI locally (without sudo)
install_gh_cli_local() {
    echo "📦 GitHub CLI not found. Installing locally..."
    echo ""
    
    local GH_VERSION="2.40.0"
    local INSTALL_DIR="$HOME/.local/bin"
    local TMP_DIR="/tmp/gh-install-$$"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$TMP_DIR"
    
    cd "$TMP_DIR"
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) GH_ARCH="amd64" ;;
        aarch64) GH_ARCH="arm64" ;;
        *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    # Download and extract
    echo "📥 Downloading gh CLI v$GH_VERSION for linux-$GH_ARCH..."
    curl -sL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" -o gh.tar.gz
    
    tar -xzf gh.tar.gz
    cp "gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/gh"
    
    # Add to PATH for current session
    export PATH="$INSTALL_DIR:$PATH"
    
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    
    echo ""
    echo "✅ GitHub CLI installed to $INSTALL_DIR/gh"
    echo ""
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "⚠️  $INSTALL_DIR is not in your PATH"
        echo "   Add this to your ~/.bashrc or ~/.zshrc:"
        echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

# Function to install gh CLI with sudo
install_gh_cli_system() {
    echo "📦 Installing GitHub CLI system-wide (requires sudo)..."
    echo ""
    
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    sudo apt update
    sudo apt install -y gh
    
    echo ""
    echo "✅ GitHub CLI installed system-wide"
    echo ""
}

# Check if gh is installed
if ! check_gh_cli; then
    echo ""
    echo "GitHub CLI is required for automated secret management."
    echo ""
    echo "Installation options:"
    echo "  1) Local install to ~/.local/bin (no sudo required)"
    echo "  2) System-wide install (requires sudo)"
    echo "  3) Skip installation (manual setup required)"
    echo ""
    read -p "Choose option (1/2/3): " install_choice
    
    case $install_choice in
        1)
            install_gh_cli_local
            ;;
        2)
            install_gh_cli_system
            ;;
        3)
            echo ""
            echo "⚠️  Skipping installation. You'll need to:"
            echo "   1. Install gh CLI manually"
            echo "   2. Add secrets via GitHub web interface"
            echo ""
            exit 0
            ;;
        *)
            echo "❌ Invalid option"
            exit 1
            ;;
    esac
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 GitHub Authentication"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if authenticated
if gh auth status &> /dev/null; then
    echo "✅ Already authenticated with GitHub"
    gh auth status 2>&1 | head -3
else
    echo "Need to authenticate with GitHub..."
    echo ""
    gh auth login
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get GitHub username
GH_USER=$(gh api user -q .login)
echo "GitHub user: $GH_USER"
echo ""

# Determine repository name from git remote or directory
if git remote get-url origin &> /dev/null; then
    REPO_URL=$(git remote get-url origin)
    REPO_NAME=$(basename "$REPO_URL" .git)
    REPO_OWNER=$(echo "$REPO_URL" | sed -n 's/.*[:/]\([^/]*\)\/[^/]*$/\1/p')
    REPO_FULL="$REPO_OWNER/$REPO_NAME"
    echo "Detected repository: $REPO_FULL"
else
    # Use directory name and current user
    REPO_NAME=$(basename "$PROJECT_ROOT")
    REPO_FULL="$GH_USER/$REPO_NAME"
    echo "Using repository: $REPO_FULL (not yet created)"
fi

echo ""

# Check if repo exists
if gh repo view "$REPO_FULL" &> /dev/null; then
    echo "✅ Repository $REPO_FULL exists"
else
    echo "❌ Repository $REPO_FULL does not exist"
    echo ""
    read -p "Create repository now? (y/n): " create_repo
    
    if [[ "$create_repo" =~ ^[Yy]$ ]]; then
        echo "Creating repository $REPO_FULL..."
        gh repo create "$REPO_FULL" --public --source=. --remote=origin --push
        echo "✅ Repository created and code pushed"
    else
        echo "⚠️  Please create the repository manually and push your code"
        exit 0
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Adding GitHub Secrets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Secret 1: REGISTRY_USERNAME
echo "📝 Adding REGISTRY_USERNAME..."
read -p "   Enter registry username (default: $GH_USER): " REGISTRY_USER
REGISTRY_USER=${REGISTRY_USER:-$GH_USER}
echo "$REGISTRY_USER" | gh secret set REGISTRY_USERNAME --repo "$REPO_FULL"
echo "   ✅ REGISTRY_USERNAME set"
echo ""

# Secret 2: REGISTRY_PASSWORD
echo "📝 Adding REGISTRY_PASSWORD..."
read -sp "   Enter registry password: " REGISTRY_PASS
echo ""
if [ -z "$REGISTRY_PASS" ]; then
    echo "   ⚠️  Skipping REGISTRY_PASSWORD (empty)"
else
    echo "$REGISTRY_PASS" | gh secret set REGISTRY_PASSWORD --repo "$REPO_FULL"
    echo "   ✅ REGISTRY_PASSWORD set"
fi
echo ""

# Secret 3: DEPLOY_SSH_KEY
echo "📝 Adding DEPLOY_SSH_KEY..."
echo "   Looking for SSH key..."

SSH_KEY_FOUND=false

# Try common SSH key locations
for key_path in ~/.ssh/id_ed25519 ~/.ssh/id_rsa ~/.ssh/id_ed25519_infra; do
    if [ -f "$key_path" ]; then
        echo "   Found: $key_path"
        read -p "   Use this key? (y/n): " use_key
        if [[ "$use_key" =~ ^[Yy]$ ]]; then
            cat "$key_path" | gh secret set DEPLOY_SSH_KEY --repo "$REPO_FULL"
            echo "   ✅ DEPLOY_SSH_KEY set"
            SSH_KEY_FOUND=true
            break
        fi
    fi
done

if [ "$SSH_KEY_FOUND" = false ]; then
    echo "   ⚠️  No SSH key found or selected"
    read -p "   Enter path to SSH private key (or press Enter to skip): " CUSTOM_KEY
    if [ -n "$CUSTOM_KEY" ] && [ -f "$CUSTOM_KEY" ]; then
        cat "$CUSTOM_KEY" | gh secret set DEPLOY_SSH_KEY --repo "$REPO_FULL"
        echo "   ✅ DEPLOY_SSH_KEY set"
    else
        echo "   ⚠️  Skipping DEPLOY_SSH_KEY"
    fi
fi

echo ""

# Verify secrets
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Secrets Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
gh secret list --repo "$REPO_FULL"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure your server network (if not already done):"
echo "   Add to your server's docker-compose.yaml:"
echo "   networks:"
echo "     ${APP_NAME}_default:"
echo "       external: true"
echo ""
echo "2. Trigger deployment:"
echo "   git commit --allow-empty -m 'Trigger deployment'"
echo "   git push origin main"
echo ""
echo "3. Watch deployment:"
echo "   gh run watch --repo $REPO_FULL"
echo "   # Or visit: https://github.com/$REPO_FULL/actions"
echo ""
echo "4. After deployment (~2 minutes):"
echo "   Visit: https://$DOMAIN"
echo ""
