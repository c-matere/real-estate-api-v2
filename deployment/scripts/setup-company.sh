#!/bin/bash
set -e

# Setup script for deploying a new company instance
# Usage: ./setup-company.sh --company "Company Name" --subdomain companyname

# Default values
COMPANY_NAME=""
SUBDOMAIN=""
ADMIN_EMAIL=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --company)
      COMPANY_NAME="$2"
      shift; shift
      ;;
    --subdomain)
      SUBDOMAIN="$2"
      shift; shift
      ;;
    --admin-email)
      ADMIN_EMAIL="$2"
      shift; shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Validate inputs
if [ -z "$COMPANY_NAME" ] || [ -z "$SUBDOMAIN" ] || [ -z "$ADMIN_EMAIL" ]; then
  echo "Error: Missing required parameters"
  echo "Usage: $0 --company 'Company Name' --subdomain companyname --admin-email admin@example.com"
  exit 1
fi

# Create company ID from name
COMPANY_ID=$(echo "$SUBDOMAIN" | tr -cd '[:alnum:]-')
echo "Setting up deployment for $COMPANY_NAME ($COMPANY_ID)"

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 16)
JWT_SECRET=$(openssl rand -base64 24)
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Create deployment directory
DEPLOY_DIR="/home/chris/realtor_pro/deployment/$COMPANY_ID"
mkdir -p "$DEPLOY_DIR"

# Create environment file
cat > "$DEPLOY_DIR/.env" <<EOL
# $COMPANY_NAME Environment Configuration
NODE_ENV=production
PORT=3000

# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=${COMPANY_ID}_db
DB_USER=postgres
DB_PASSWORD=$DB_PASSWORD

# Security
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=30d

# Admin User
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# CORS Configuration
CORS_ORIGINS=https://${COMPANY_ID}.alphask.entorach.site
FRONTEND_URL=https://${COMPANY_ID}.alphask.entorach.site
EOL

# Create Docker Compose file
cat > "$DEPLOY_DIR/docker-compose.yml" <<EOL
version: '3.8'

services:
  postgres:
    image: postgres:13-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: $DB_PASSWORD
      POSTGRES_DB: ${COMPANY_ID}_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:6-alpine
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    restart: unless-stopped

  api:
    build:
      context: ../../real-estate-api
      dockerfile: Dockerfile
    env_file: .env
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    
  dashboard:
    build:
      context: ../../real-estate-dashboard
      args:
        - REACT_APP_API_URL=https://api-${COMPANY_ID}.onrender.com
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
EOL

# Create Netlify configuration
mkdir -p "$DEPLOY_DIR/frontend"
cat > "$DEPLOY_DIR/frontend/netlify.toml" <<EOL
[build]
  command = "npm run build"
  publish = "build"

[context.production.environment]
  REACT_APP_API_URL = "https://api-${COMPANY_ID}.onrender.com"

[[headers]]
  for = "/*"
    [headers.values]
    Access-Control-Allow-Origin = "*"
    Access-Control-Allow-Methods = "GET, POST, PUT, DELETE, OPTIONS"
    Access-Control-Allow-Headers = "Origin, X-Requested-With, Content-Type, Accept, Authorization"
EOL

echo "Setup complete for $COMPANY_NAME"
echo "Environment files created in $DEPLOY_DIR"
echo "Next steps:"
echo "1. Deploy API to Render.com with the name: api-${COMPANY_ID}"
echo "2. Deploy frontend to Netlify with the name: ${COMPANY_ID}"
echo "3. Set up DNS records for ${COMPANY_ID}.alphask.entorach.site"
