#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
COMPANY_NAME=""
SUBDOMAIN=""
ADMIN_EMAIL=""
GITHUB_REPO=""
NETLIFY_TOKEN="${NETLIFY_TOKEN:-}"
RENDER_TOKEN="${RENDER_TOKEN:-}"
# These should be set as environment variables or passed as parameters
SUPABASE_ORG_ID="${SUPABASE_ORG_ID:?Please set SUPABASE_ORG_ID environment variable}"
SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:?Please set SUPABASE_ACCESS_TOKEN environment variable}"

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
    --admin)
      ADMIN_EMAIL="$2"
      shift; shift
      ;;
    --github-repo)
      GITHUB_REPO="$2"
      shift; shift
      ;;
    --netlify-token)
      NETLIFY_TOKEN="$2"
      shift; shift
      ;;
    --render-token)
      RENDER_TOKEN="$2"
      shift; shift
      ;;
    *)
      shift
      ;;
  esac
done

# Validate required parameters
if [ -z "$COMPANY_NAME" ] || [ -z "$SUBDOMAIN" ] || [ -z "$ADMIN_EMAIL" ]; then
  echo -e "${RED}Error: Missing required parameters${NC}"
  echo "Usage: $0 --company 'Company Name' --subdomain companyname --admin admin@example.com"
  echo "Optional: --github-repo user/repo --netlify-token token --render-token token"
  exit 1
fi

# Generate secure credentials
echo -e "${YELLOW}Generating secure credentials...${NC}"
DB_PASSWORD=$(openssl rand -base64 16)
JWT_SECRET=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Create deployment directory
DEPLOY_DIR="/home/chris/realtor_pro/deployment/$SUBDOMAIN"
mkdir -p "$DEPLOY_DIR"

# Create .env file
echo -e "${YELLOW}Creating environment configuration...${NC}"
cat > "$DEPLOY_DIR/.env" <<EOL
# $COMPANY_NAME Environment Configuration
NODE_ENV=production
PORT=3000

# Database
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=$DB_PASSWORD
DB_HOST=db.$SUBDOMAIN.supabase.co
DB_PORT=5432

# Security
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=30d

# Admin User
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# CORS
CORS_ORIGINS=https://$SUBDOMAIN.entorach.site
FRONTEND_URL=https://$SUBDOMAIN.entorach.site

# Supabase Configuration (will be updated below)
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
EOL

echo -e "${GREEN}✓ Created configuration in $DEPLOY_DIR/.env${NC}"

# Function to setup Supabase
setup_supabase() {
  echo -e "\n${YELLOW}=== Setting up Supabase ===${NC}"
  
  # Use npx for Supabase CLI
  echo -e "${YELLOW}Using npx for Supabase CLI...${NC}"
  npx supabase login --token "$SUPABASE_ACCESS_TOKEN"
  
  # Create project
  echo -e "${YELLOW}Creating Supabase project: $SUBDOMAIN${NC}"
  npx supabase projects create "$SUBDOMAIN" \
    --db-password "$DB_PASSWORD" \
    --region us-east-1 \
    --org-id "$SUPABASE_ORG_ID" \
    --plan free
  
  # Wait for project to be ready
  echo -e "${YELLOW}Waiting for project to be ready...${NC}"
  sleep 30
  
  # Get project details using the correct output format
  echo -e "${YELLOW}Fetching project details...${NC}"
  PROJECT_INFO=$(npx supabase projects list -o json | jq -r ".[] | select(.name == \"$SUBDOMAIN\")")
  
  if [ -z "$PROJECT_INFO" ]; then
    echo -e "${YELLOW}Could not fetch project details. Please check in Supabase dashboard.${NC}"
    echo -e "${YELLOW}Project was created at: https://supabase.com/dashboard/project/$(echo $SUBDOMAIN | tr -d '.' | tr '[:upper:]' '[:lower:]')${NC}"
    return 1
  fi
  
  # Update .env with Supabase details
  SUPABASE_URL=$(echo "$PROJECT_INFO" | jq -r '.api.url')
  SUPABASE_ANON_KEY=$(echo "$PROJECT_INFO" | jq -r '.api.anon')
  SUPABASE_SERVICE_ROLE_KEY=$(echo "$PROJECT_INFO" | jq -r '.api.service_role')
  
  # Update .env file
  sed -i "s|SUPABASE_URL=.*|SUPABASE_URL=$SUPABASE_URL|" "$DEPLOY_DIR/.env"
  sed -i "s|SUPABASE_ANON_KEY=.*|SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY|" "$DEPLOY_DIR/.env"
  sed -i "s|SUPABASE_SERVICE_ROLE_KEY=.*|SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY|" "$DEPLOY_DIR/.env"
  
  echo -e "${GREEN}✓ Supabase project created successfully!${NC}"
  echo -e "${YELLOW}Supabase Dashboard: $SUPABASE_URL${NC}"
}

# Function to setup Render
setup_render() {
  if [ -z "$RENDER_TOKEN" ]; then
    echo -e "${YELLOW}Skipping Render setup: RENDER_TOKEN not provided${NC}"
    return
  fi
  
  echo -e "\n${YELLOW}=== Setting up Render ===${NC}"
  
  # Create render.yaml
  cat > "$DEPLOY_DIR/render.yaml" <<EOL
services:
  - type: web
    name: api-$SUBDOMAIN
    env: node
    region: oregon
    buildCommand: npm install
    startCommand: node src/app.js
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 10000
      - key: DB_NAME
        value: postgres
      - key: DB_USER
        value: postgres
      - key: DB_PASSWORD
        value: $DB_PASSWORD
      - key: JWT_SECRET
        value: $JWT_SECRET
      - key: ADMIN_EMAIL
        value: $ADMIN_EMAIL
      - key: ADMIN_PASSWORD
        value: $ADMIN_PASSWORD
      - key: CORS_ORIGINS
        value: https://$SUBDOMAIN.entorach.site
      - key: FRONTEND_URL
        value: https://$SUBDOMAIN.entorach.site
      - key: SUPABASE_URL
        value: $SUPABASE_URL
      - key: SUPABASE_ANON_KEY
        value: $SUPABASE_ANON_KEY
      - key: SUPABASE_SERVICE_ROLE_KEY
        value: $SUPABASE_SERVICE_ROLE_KEY

databases:
  - name: db-$SUBDOMAIN
    databaseName: postgres
    user: postgres
    plan: free
EOL

  echo -e "${GREEN}✓ Render configuration created at $DEPLOY_DIR/render.yaml${NC}"
  echo -e "${YELLOW}To deploy to Render, run:${NC}"
  echo "cd $DEPLOY_DIR && render services create"
}

# Function to setup Netlify
setup_netlify() {
  if [ -z "$NETLIFY_TOKEN" ] || [ -z "$GITHUB_REPO" ]; then
    echo -e "${YELLOW}Skipping Netlify setup: NETLIFY_TOKEN or GITHUB_REPO not provided${NC}"
    return
  fi
  
  echo -e "\n${YELLOW}=== Setting up Netlify ===${NC}"
  
  # Create netlify.toml
  cat > "$DEPLOY_DIR/netlify.toml" <<EOL
[build]
  command = "npm run build"
  publish = "build"

[build.environment]
  NODE_VERSION = "18"
  NPM_VERSION = "9"
  REACT_APP_API_URL = "https://api-$SUBDOMAIN.onrender.com"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOL

  echo -e "${GREEN}✓ Netlify configuration created at $DEPLOY_DIR/netlify.toml${NC}"
  echo -e "${YELLOW}To deploy to Netlify, run:${NC}"
  echo "cd /home/chris/realtor_pro/real-estate-dashboard && netlify deploy --prod"
}

# Main execution
main() {
  echo -e "\n${YELLOW}🚀 Starting deployment for $COMPANY_NAME${NC}"
  
  # Setup Supabase
  setup_supabase
  
  # Setup Render
  setup_render
  
  # Setup Netlify
  setup_netlify
  
  # Output summary
  echo -e "\n${GREEN}✅ Deployment setup complete!${NC}"
  echo -e "\n${YELLOW}🔑 Admin credentials:${NC}"
  echo "Email: $ADMIN_EMAIL"
  echo "Password: $ADMIN_PASSWORD"
  
  echo -e "\n${YELLOW}🌐 Next steps:${NC}"
  echo "1. Deploy backend to Render using the render.yaml configuration"
  echo "2. Deploy frontend to Netlify"
  echo "3. Set up DNS records for your domain"
  echo -e "\n${YELLOW}📝 Environment variables are saved in: $DEPLOY_DIR/.env${NC}"
}

# Run main function
main "$@"

echo -e "\n${GREEN}✨ Deployment script completed!${NC}"
