#!/bin/bash
set -e

# Configuration - Update these values
SITE_NAME="demo.entorach.site"
GITHUB_REPO="chris-maina/real-estate-dashboard"  # GitHub username/repo
NETLIFY_AUTH_TOKEN="nfp_rXQ4AYLkFPa7LsWvwAz1LJaFPsjVi49B30bb"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Netlify Auto Setup${NC}"

# Create a new site
echo -e "${YELLOW}Creating new Netlify site...${NC}"
SITE_ID=$(curl -s -X POST "https://api.netlify.com/api/v1/sites" \
  -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$SITE_NAME\"}" | jq -r '.site_id' 2>/dev/null)

if [ -z "$SITE_ID" ] || [ "$SITE_ID" = "null" ]; then
  echo -e "⚠️  Could not create site. It might already exist. Trying to get site ID..."
  SITE_ID=$(curl -s -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
    "https://api.netlify.com/api/v1/sites/$SITE_NAME.netlify.app" | jq -r '.id' 2>/dev/null)
  
  if [ -z "$SITE_ID" ] || [ "$SITE_ID" = "null" ]; then
    echo -e "❌ Failed to create or find site. Please check your Netlify dashboard."
    exit 1
  fi
  echo -e "✅ Found existing site with ID: $SITE_ID"
else
  echo -e "✅ Created new site with ID: $SITE_ID"
fi

# Get site URL
SITE_URL=$(curl -s -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
  "https://api.netlify.com/api/v1/sites/$SITE_ID" | jq -r '.url')

echo -e "\n${GREEN}🎉 Netlify Site Created Successfully!${NC}"
echo -e "Site URL: ${YELLOW}https://$SITE_URL${NC}"

echo -e "\n${YELLOW}📝 Manual Steps Required:${NC}"
echo "1. Go to: https://app.netlify.com/sites/$SITE_ID/settings/deploys#continuous-deployment"
echo "2. Click 'Link to Git provider' and authorize Netlify"
   echo "3. Select your repository: $GITHUB_REPO"
echo "4. Configure build settings:"
echo "   - Build command: npm run build"
echo "   - Publish directory: dist"
echo "5. Add any required environment variables"
echo "6. Click 'Deploy site'"

echo -e "\n${YELLOW}🔗 Site Dashboard:${NC} https://app.netlify.com/sites/$SITE_ID"
echo -e "${YELLOW}🌐 Live URL:${NC} https://$SITE_URL"

echo -e "\n${GREEN}✅ Setup complete! Follow the instructions above to complete the GitHub connection.${NC}"
