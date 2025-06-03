#!/bin/bash
set -e

# Load configuration
source "$(dirname "$0")/config.sh"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to create Supabase project
setup_supabase() {
    echo -e "${YELLOW}Setting up Supabase project...${NC}"
    
    # Create deployment directory
    mkdir -p "$DEPLOY_DIR"
    
    # Create .env file
    cat > "${DEPLOY_DIR}/.env" <<EOL
# ${COMPANY_NAME} Environment Configuration
NODE_ENV=production

# Database (Supabase)
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=db.${SUBDOMAIN}.supabase.co
DB_PORT=5432

# Security
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRES_IN=30d

# Admin User
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# CORS Configuration
CORS_ORIGINS=${FRONTEND_URL}
FRONTEND_URL=${FRONTEND_URL}

# Supabase Configuration
SUPABASE_URL=https://${SUBDOMAIN}.supabase.co
EOL

    # Create Supabase project
    supabase projects create "${SUBDOMAIN}" \
        --db-password "${DB_PASSWORD}" \
        --region "${SUPABASE_REGION}" \
        --org-id "${SUPABASE_ORG_ID}" \
        --plan free

    echo -e "${GREEN}✓ Supabase project created successfully!${NC}"
}

# Function to deploy to Render
setup_render() {
    echo -e "${YELLOW}Setting up Render deployment...${NC}"
    
    # Create render.yaml
    cat > "${DEPLOY_DIR}/render.yaml" <<EOL
services:
  - type: web
    name: ${API_NAME}
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
        value: ${DB_PASSWORD}
      - key: JWT_SECRET
        value: ${JWT_SECRET}
      - key: ADMIN_EMAIL
        value: ${ADMIN_EMAIL}
      - key: ADMIN_PASSWORD
        value: ${ADMIN_PASSWORD}
      - key: CORS_ORIGINS
        value: ${FRONTEND_URL}
      - key: FRONTEND_URL
        value: ${FRONTEND_URL}
      - key: SUPABASE_URL
        value: https://${SUBDOMAIN}.supabase.co
EOL

    echo -e "${GREEN}✓ Render configuration created at ${DEPLOY_DIR}/render.yaml${NC}"
    echo -e "To deploy to Render, run: ${YELLOW}cd ${DEPLOY_DIR} && render services create${NC}"
}

# Function to deploy to Netlify
setup_netlify() {
    echo -e "${YELLOW}Setting up Netlify deployment...${NC}"
    
    # Create netlify.toml
    cat > "${DEPLOY_DIR}/netlify.toml" <<EOL
[build]
  command = "npm run build"
  publish = "build"

[build.environment]
  NODE_VERSION = "18"
  NPM_VERSION = "9"
  REACT_APP_API_URL = "${API_URL}"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOL

    echo -e "${GREEN}✓ Netlify configuration created at ${DEPLOY_DIR}/netlify.toml${NC}"
    echo -e "To deploy to Netlify, run: ${YELLOW}cd ${BASE_DIR}/real-estate-dashboard && netlify deploy --prod${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Starting deployment for ${COMPANY_NAME}...${NC}"
    
    # Setup Supabase
    setup_supabase
    
    # Setup Render
    setup_render
    
    # Setup Netlify
    setup_netlify
    
    # Output summary
    echo -e "\n${GREEN}✓ Deployment setup complete!${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Deploy backend to Render using the render.yaml configuration"
    echo "2. Deploy frontend to Netlify"
    echo "3. Set up DNS records for your custom domain"
    echo -e "\nAdmin credentials have been saved to ${DEPLOY_DIR}/.env"
}

# Run main function
main "$@"
