# GitHub Setup Scripts

This directory contains scripts for setting up GitHub repositories and secrets for automated deployment.

## Quick Start

From your project root, run:

```bash
./scripts/setup-github.sh
```

This script will:
1. Check if GitHub CLI (gh) is installed
2. Install it locally if needed (no sudo required)
3. Authenticate with GitHub
4. Create repository if it doesn't exist
5. Add deployment secrets automatically
6. Verify everything is ready

## What It Does

The setup script handles:
- ✅ Detecting existing gh CLI installation
- ✅ Installing gh CLI locally to `~/.local/bin` (option 1)
- ✅ Installing gh CLI system-wide with sudo (option 2)
- ✅ Interactive authentication with GitHub
- ✅ Creating repository if needed
- ✅ Adding all 3 required secrets:
  - `REGISTRY_USERNAME`
  - `REGISTRY_PASSWORD`
  - `DEPLOY_SSH_KEY`

## Manual Setup

If you prefer manual setup, see `DEPLOYMENT.md` for detailed instructions.

## Secrets Required

The script will prompt you for:

1. **REGISTRY_USERNAME** - Your Docker registry username
2. **REGISTRY_PASSWORD** - Your Docker registry password
3. **DEPLOY_SSH_KEY** - SSH private key for deployment (auto-detected from `~/.ssh/`)

## Troubleshooting

### GitHub CLI Not Found

The script will offer to install gh CLI automatically. Choose:
- Option 1: Local install (no sudo) - installs to `~/.local/bin`
- Option 2: System install (requires sudo) - installs system-wide
- Option 3: Skip - manual setup required

### Authentication Issues

If `gh auth login` fails:
1. Make sure you have a GitHub account
2. Use a personal access token if needed
3. Follow the interactive prompts

### SSH Key Not Found

The script looks for SSH keys in:
- `~/.ssh/id_ed25519`
- `~/.ssh/id_rsa`
- `~/.ssh/id_ed25519_infra`

You can specify a custom path when prompted.

## After Setup

Once setup is complete:

1. Add network to your server's `docker-compose.yaml`:
   ```yaml
   networks:
     your-app_default:
       external: true
   ```

2. Trigger deployment:
   ```bash
   git push origin main
   ```

3. Watch deployment:
   ```bash
   gh run watch
   ```

## Files

- `setup-github.sh` - Main setup script
- `README.md` - This file
