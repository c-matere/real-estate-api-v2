#!/bin/bash
set -e

# Configuration
SITE_NAME="demo.entorach.site"
GITHUB_REPO="chris-maina/real-estate-dashboard"
NETLIFY_AUTH_TOKEN="nfp_rXQ4AYLkFPa7LsWvwAz1LJaFPsjVi49B30bb"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Netlify Deployment${NC}"

# Get site ID
echo -e "${YELLOW}Getting site information...${NC}"
SITE_ID=$(curl -s -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
  "https://api.netlify.com/api/v1/sites/$SITE_NAME" | jq -r '.id' 2>/dev/null)

if [ -z "$SITE_ID" ] || [ "$SITE_ID" = "null" ]; then
  echo -e "❌ Could not find site: $SITE_NAME"
  exit 1
fi

echo -e "✅ Found site ID: $SITE_ID"

# Trigger a new deploy
echo -e "${YELLOW}Triggering new deployment...${NC}"
DEPLOY_RESULT=$(curl -s -X POST \
  -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"clear_cache":true}' \
  "https://api.netlify.com/api/v1/sites/$SITE_ID/builds")

if [ $? -ne 0 ]; then
  echo -e "❌ Failed to trigger deployment"
  exit 1
fi

echo -e "${GREEN}✅ Successfully triggered deployment!${NC}"
echo -e "\n${YELLOW}📊 Deployment Dashboard:${NC}"
echo -e "https://app.netlify.com/sites/$SITE_NAME/deploys"
echo -e "\n${YELLOW}🌐 Live Site:${NC}"
echo -e "https://$SITE_NAME"
echo -e "\n${GREEN}🚀 Deployment in progress! Check the dashboard for status.${NC}"
