#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.env"

echo -e "${YELLOW}Setting up Supabase for ${COMPANY_NAME:-Test Company}...${NC}"

# Function to create Supabase project
create_supabase_project() {
    local access_token="$1"
    local project_name="$2"
    local db_password="$3"
    local org_id="$4"
    
    echo -e "${YELLOW}Creating Supabase project: ${project_name}${NC}"
    
    # Create project using Supabase CLI
    npx supabase projects create "${project_name}" \
        --db-password "${db_password}" \
        --region us-east-1 \
        --org-id "${org_id}" \
        --plan free
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create Supabase project${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Supabase project created successfully!${NC}"
    
    # Get project details
    echo -e "${YELLOW}Fetching project details...${NC}"
    local project_info=$(npx supabase projects list --json | jq -r ".[] | select(.name == \"${project_name}\")")
    
    if [ -z "$project_info" ]; then
        echo -e "${YELLOW}Could not fetch project details. Please check in Supabase dashboard.${NC}"
        return 1
    fi
    
    # Update .env with Supabase details
    local api_url=$(echo "$project_info" | jq -r '.api.url')
    local anon_key=$(echo "$project_info" | jq -r '.api.anon')
    local service_key=$(echo "$project_info" | jq -r '.api.service_role')
    
    # Update .env file
    sed -i "s|# Supabase Configuration|# Supabase Configuration\nSUPABASE_URL=${api_url}\nSUPABASE_ANON_KEY=${anon_key}\nSUPABASE_SERVICE_ROLE_KEY=${service_key}|" "${SCRIPT_DIR}/.env"
    
    echo -e "${GREEN}✓ Project details updated in .env file${NC}"
    echo -e "${YELLOW}Supabase Dashboard: ${api_url}${NC}"
}

# Check if Supabase CLI is installed
if ! command -v npx &> /dev/null; then
    echo -e "${RED}Error: npx is required but not installed. Please install Node.js and npm.${NC}"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Installing jq...${NC}"
    sudo apt-get update && sudo apt-get install -y jq
fi

# Check if Supabase access token is set
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo -e "${RED}Error: SUPABASE_ACCESS_TOKEN environment variable is not set${NC}"
    echo "Please get your access token from: https://app.supabase.com/account/tokens"
    echo "Then run: export SUPABASE_ACCESS_TOKEN=your_token_here"
    exit 1
fi

# Check if organization ID is set
if [ -z "$SUPABASE_ORGANIZATION_ID" ]; then
    echo -e "${RED}Error: SUPABASE_ORGANIZATION_ID environment variable is not set${NC}"
    echo "Please get your organization ID from: https://app.supabase.com/account/organizations"
    echo "Then run: export SUPABASE_ORGANIZATION_ID=your_org_id_here"
    exit 1
fi

# Login to Supabase if not already logged in
if ! npx supabase status &> /dev/null; then
    echo -e "${YELLOW}Logging in to Supabase...${NC}"
    npx supabase login --access-token "$SUPABASE_ACCESS_TOKEN"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to login to Supabase. Please check your access token.${NC}"
        exit 1
    fi
fi

# Create project
create_supabase_project "$SUPABASE_ACCESS_TOKEN" "testco" "FatEvXdvv+L0vY2V6KDCdg==" "$SUPABASE_ORGANIZATION_ID"

echo -e "${GREEN}✓ Supabase setup complete!${NC}"
