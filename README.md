# Web App Deployment Template

🚀 **Ready-to-deploy web application template with automated CI/CD**

This template includes everything you need to deploy a web app to your infrastructure:
- ✅ Nginx-based web server
- ✅ Docker containerization
- ✅ Automated GitHub Actions deployment
- ✅ SSL/HTTPS via nginx-proxy-manager
- ✅ Health checks and monitoring

## 🎯 Quick Start

### 1. Use This Template

Click "Use this template" on GitHub or:

```bash
# Clone this template
git clone https://github.com/mkucharz/webapp-deploy-template.git my-new-app
cd my-new-app

# Remove template git history
rm -rf .git
git init
git add .
git commit -m "Initial commit from template"

# Create your GitHub repo and push
gh repo create mkucharz/my-new-app --public --source=. --remote=origin --push
```

### 2. Configure Your App

Edit `deploy-config.env`:

```bash
# Change these values for your app
APP_NAME=my-new-app
DOMAIN=my-new-app.kucharz.net
APP_PORT=8080
```

### 3. Add GitHub Secrets

**Option A: Automated (Recommended)**

Run the setup script from your project root:

```bash
./scripts/setup-github.sh
```

This will:
- Install GitHub CLI if needed (locally, no sudo required)
- Authenticate with GitHub
- Create repository if needed
- Add all secrets automatically

**Option B: Manual**

Go to: **Settings → Secrets and variables → Actions → New repository secret**

Add:
- `REGISTRY_USERNAME` - Your Docker registry username
- `REGISTRY_PASSWORD` - Your Docker registry password
- `DEPLOY_SSH_KEY` - SSH private key for deployment

### 4. Start Developing

```bash
# Run locally
docker-compose up

# Visit: http://localhost:8080
```

### 5. Deploy

```bash
# Just push to GitHub!
git add .
git commit -m "My changes"
git push origin main

# GitHub Actions will automatically:
# - Build Docker image
# - Push to registry
# - Deploy to your server
# - Run health checks
```

## 📁 Template Structure

```
.
├── public/                  # Your web content
│   └── index.html          # Entry point
├── scripts/                # Setup and automation scripts
│   ├── setup-github.sh     # Automated GitHub setup
│   └── README.md          # Scripts documentation
├── Dockerfile              # How to build
├── nginx.conf              # Nginx configuration
├── docker-compose.yml      # How to deploy
├── deploy-config.env       # Deployment settings
├── .env.example           # Environment variables template
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD automation
├── .gitignore
└── README.md              # This file
```

## 🎨 What's Included

- **Nginx web server**: Optimized for static files and SPAs
- **Multi-stage build**: Small production images
- **Auto-deployment**: Push to GitHub = Deploy to production
- **Health checks**: Automatic monitoring
- **SSL/HTTPS**: Automatic certificates via Let's Encrypt
- **Gzip compression**: Faster page loads
- **Security headers**: XSS protection, HTTPS enforcement

## 🔧 Customization

### Static Website

Already configured! Just add your HTML/CSS/JS to `public/`

### React/Vue/Angular SPA

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
```

### Backend API

```dockerfile
# For Python/Flask
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

Update `nginx.conf` to proxy to your backend or remove nginx entirely.

## 🚀 Deployment Targets

This template deploys to your infrastructure at:
- **Server**: Configured in `deploy-config.env`
- **Path**: `/home/{APP_NAME}/`
- **URL**: `https://{DOMAIN}`

## 📝 Environment Variables

Create `.env` file for local development (not committed):

```bash
# Copy from example
cp .env.example .env

# Edit with your values
nano .env
```

## 🔐 Security

- Secrets never committed to git
- SSH keys in GitHub Secrets only
- Non-root container user
- Security headers enabled
- Regular security updates

## 📊 Monitoring

Access logs and monitor your app:

```bash
# On your server
docker-compose -f /home/{APP_NAME}/docker-compose.yml logs -f
```

## ❓ Support

See deployment guides in infrastructure repo:
- `/home/AUTOMATED_DEPLOYMENT.md`
- `/home/ADD_NEW_APP.md`

## 📄 License

MIT License - Customize as needed
