#!/bin/bash
set -e

# Deployment script for a new company instance
# Usage: ./deploy-company.sh --company "Company Name" --subdomain companyname --admin admin@example.com

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
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Validate inputs
if [ -z "$COMPANY_NAME" ] || [ -z "$SUBDOMAIN" ] || [ -z "$ADMIN_EMAIL" ]; then
  echo "Error: Missing required parameters"
  echo "Usage: $0 --company 'Company Name' --subdomain companyname --admin admin@example.com"
  exit 1
fi

# Generate secure credentials
DB_PASSWORD=$(openssl rand -base64 16)
JWT_SECRET=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Create deployment directory
DEPLOY_DIR="/home/chris/realtor_pro/deployment/$SUBDOMAIN"
mkdir -p "$DEPLOY_DIR"

# Create environment file
cat > "$DEPLOY_DIR/.env" <<EOL
# $COMPANY_NAME Environment Configuration
NODE_ENV=production
PORT=3000

# Database (Supabase)
DB_NAME=postgres  # Default Supabase database
DB_USER=postgres  # Default Supabase user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=db.${SUBDOMAIN}.entorach.site  # Your Supabase project host
DB_PORT=5432

# Supabase Configuration
SUPABASE_URL=https://${SUBDOMAIN}.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# Connection String (for reference)
DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/postgres?sslmode=require

# Security
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=30d

# Admin User
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# CORS Configuration
CORS_ORIGINS=https://${SUBDOMAIN}.entorach.site
FRONTEND_URL=https://${SUBDOMAIN}.entorach.site
EOL

# Function to create Supabase project using Management API
create_supabase_project() {
    local access_token="$1"
    local project_name="$2"
    local db_password="$3"
    local organization_id="$4"
    
    echo "Creating Supabase project: $project_name"
    
    # Create project
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "'$project_name'",
            "organization_id": "'$organization_id'",
            "db_pass": "'$db_password'",
            "region": "us-east-1"
        }' \
        https://api.supabase.com/v1/projects)
    
    # Extract project ID
    local project_id=$(echo "$response" | jq -r '.id // empty')
    
    if [ -z "$project_id" ]; then
        echo "Error creating Supabase project:" >&2
        echo "$response" >&2
        return 1
    fi
    
    echo "Waiting for project to be ready..."
    local status=""
    local attempts=0
    
    # Wait for project to be ready
    while [ "$status" != "ACTIVE_HEALTHY" ] && [ $attempts -lt 30 ]; do
        sleep 10
        response=$(curl -s -H "Authorization: Bearer $access_token" \
            "https://api.supabase.com/v1/projects/$project_id")
        status=$(echo "$response" | jq -r '.status')
        echo "Project status: $status"
        attempts=$((attempts + 1))
    done
    
    if [ "$status" != "ACTIVE_HEALTHY" ]; then
        echo "Timed out waiting for project to be ready" >&2
        return 1
    fi
    
    # Get API keys
    local api_keys=$(curl -s -H "Authorization: Bearer $access_token" \
        "https://api.supabase.com/v1/projects/$project_id/api-keys")
    
    local anon_key=$(echo "$api_keys" | jq -r '.[] | select(.name == "anon") | .api_key')
    local service_key=$(echo "$api_keys" | jq -r '.[] | select(.name == "service_role") | .api_key')
    
    # Update .env file with Supabase details
    sed -i "s|SUPABASE_URL=.*|SUPABASE_URL=https://$project_id.supabase.co|" "$DEPLOY_DIR/.env"
    sed -i "s|SUPABASE_ANON_KEY=.*|SUPABASE_ANON_KEY=$anon_key|" "$DEPLOY_DIR/.env"
    sed -i "s|SUPABASE_SERVICE_ROLE_KEY=.*|SUPABASE_SERVICE_ROLE_KEY=$service_key|" "$DEPLOY_DIR/.env"
    
    echo "Supabase project created successfully!"
    echo "Project ID: $project_id"
    echo "Project URL: https://$project_id.supabase.co"
}

# Create Supabase setup script
cat > "$DEPLOY_DIR/setup-supabase.sh" <<EOL
#!/bin/bash
set -e

# Load environment variables
source "$DEPLOY_DIR/.env"

echo "Setting up Supabase for $COMPANY_NAME..."

# Check if Supabase access token is set
if [ -z "\$SUPABASE_ACCESS_TOKEN" ]; then
    echo "Error: SUPABASE_ACCESS_TOKEN environment variable is not set"
    echo "Please get your access token from: https://app.supabase.com/account/tokens"
    echo "Then run: export SUPABASE_ACCESS_TOKEN=your_token_here"
    exit 1
fi

# Check if organization ID is set
if [ -z "\$SUPABASE_ORGANIZATION_ID" ]; then
    echo "Error: SUPABASE_ORGANIZATION_ID environment variable is not set"
    echo "Please get your organization ID from: https://app.supabase.com/account/organizations"
    echo "Then run: export SUPABASE_ORGANIZATION_ID=your_org_id_here"
    exit 1
fi

# Install jq if not installed
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Create project
create_supabase_project "\$SUPABASE_ACCESS_TOKEN" "$SUBDOMAIN" "$DB_PASSWORD" "\$SUPABASE_ORGANIZATION_ID"

echo "Supabase setup complete!"
EOL

# Make the setup script executable
chmod +x "$DEPLOY_DIR/setup-supabase.sh"

# Create database initialization script
cat > "$DEPLOY_DIR/init-db.sh" <<EOL
#!/bin/bash
set -e

# Load environment variables
source "$DEPLOY_DIR/.env"

echo "Initializing database for $COMPANY_NAME..."

# Install psql client if not installed
if ! command -v psql &> /dev/null; then
  echo "Installing PostgreSQL client..."
  sudo apt-get update && sudo apt-get install -y postgresql-client
fi

# Run migrations
echo "Running database migrations..."
cd /path/to/real-estate-api
npx sequelize-cli db:migrate

# Seed admin user
echo "Creating admin user..."
ADMIN_EMAIL="$ADMIN_EMAIL" ADMIN_PASSWORD="$ADMIN_PASSWORD" node scripts/seed-admin.js

echo "Database initialization complete!"
EOL

# Make the init script executable
chmod +x "$DEPLOY_DIR/init-db.sh"

echo ""
echo "=============================================="
echo "  $COMPANY_NAME Deployment Setup Complete!"
echo "=============================================="
echo ""
echo "Admin credentials have been generated:"
echo "  Email: $ADMIN_EMAIL"
echo "  Password: $ADMIN_PASSWORD"
echo ""
echo "Next steps:"
echo ""
echo "1. Set up Supabase:"
echo "   - Run: $DEPLOY_DIR/setup-supabase.sh"
echo "   - Update the .env file with your Supabase credentials"
echo ""
echo "2. Deploy backend to Render.com:"
echo "   - Project name: api-$SUBDOMAIN"
echo "   - Environment: Node"
echo "   - Build Command: npm install"
echo "   - Start Command: node src/app.js"
echo "   - Add all variables from $DEPLOY_DIR/.env"
echo ""
echo "3. Deploy frontend to Netlify:"
echo "   - Site name: $SUBDOMAIN"
echo "   - Build command: npm run build"
echo "   - Publish directory: build"
echo "   - Environment variables:"
echo "     - REACT_APP_API_URL: https://api-${SUBDOMAIN}.onrender.com"
echo ""
echo "4. Set up DNS records:"
echo "   - CNAME: ${SUBDOMAIN}.entorach.site -> ${SUBDOMAIN}.netlify.app"
echo "   - CNAME: api-${SUBDOMAIN}.entorach.site -> api-${SUBDOMAIN}.onrender.com"
echo ""
echo "5. Initialize the database:"
echo "   - Run: $DEPLOY_DIR/init-db.sh"
echo ""
echo "Access your application at: https://${SUBDOMAIN}.entorach.site"
echo "Admin dashboard: https://${SUBDOMAIN}.entorach.site/admin"
echo ""
echo "Note: Make sure to change the default admin password after first login!"
