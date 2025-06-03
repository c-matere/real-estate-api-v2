#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SITE_NAME="demo.entorach.site"
REPO_URL="https://github.com/yourusername/real-estate-dashboard.git"  # Update with your GitHub repo
NETLIFY_AUTH_TOKEN="nfp_rXQ4AYLkFPa7LsWvwAz1LJaFPsjVi49B30bb"

# Create a new site
create_netlify_site() {
  echo -e "${YELLOW}Creating Netlify site...${NC}"
  
  RESPONSE=$(curl -s -X POST "https://api.netlify.com/api/v1/sites" \
    -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "name": "$SITE_NAME",
  "custom_domain": "$SITE_NAME"
}
EOF
  )
  
  SITE_ID=$(echo $RESPONSE | jq -r '.site_id // empty')
  
  if [ -z "$SITE_ID" ]; then
    echo -e "${RED}Failed to create Netlify site. Response:${NC}"
    echo $RESPONSE | jq
    exit 1
  fi
  
  echo -e "${GREEN}✓ Created Netlify site with ID: $SITE_ID${NC}"
  echo $SITE_ID > netlify_site_id.txt
  echo $SITE_ID
}

# Configure build settings
configure_build_settings() {
  local SITE_ID=$1
  
  echo -e "${YELLOW}Configuring build settings...${NC}"
  
  curl -s -X PATCH "https://api.netlify.com/api/v1/sites/$SITE_ID" \
    -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "build_settings": {
    "repo_path": "real-estate-dashboard",
    "repo_branch": "main",
    "repo_url": "$REPO_URL",
    "dir": "dist",
    "cmd": "npm install && npm run build"
  },
  "build_image": "ubuntu20.04",
  "managed_dns": true
}
EOF
  
  echo -e "${GREEN}✓ Build settings configured${NC}"
}

# Connect to GitHub
connect_to_github() {
  local SITE_ID=$1
  
  echo -e "${YELLOW}Connecting to GitHub...${NC}"
  
  # This is a simplified version - in a real scenario, you'd need to handle GitHub OAuth
  echo -e "${YELLOW}Please manually connect to GitHub in the Netlify UI for now${NC}"
  echo -e "Go to: https://app.netlify.com/sites/$SITE_ID/settings/deploys#continuous-deployment"
}

# Main execution
main() {
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed. Please install jq first.${NC}"
    exit 1
  fi
  
  # Create site
  SITE_ID=$(create_netlify_site)
  
  # Configure build settings
  configure_build_settings "$SITE_ID"
  
  # Connect to GitHub
  connect_to_github "$SITE_ID"
  
  echo -e "\n${GREEN}✅ Netlify setup complete!${NC}"
  echo -e "${YELLOW}Next steps:${NC}"
  echo "1. Go to Netlify and connect your GitHub repository"
  echo "2. Set up environment variables in the Netlify UI"
  echo "3. Trigger a new deployment"
  echo -e "\nSite URL: https://$SITE_NAME"
}

# Run main function
main "$@"
