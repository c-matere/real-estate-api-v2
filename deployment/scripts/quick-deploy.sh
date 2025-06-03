#!/bin/bash
set -e

# Quick deployment script
# Usage: ./quick-deploy.sh --company "Company Name" --subdomain companyname --admin admin@example.com

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
      shift
      ;;
  esac
done

# Validate required parameters
if [ -z "$COMPANY_NAME" ] || [ -z "$SUBDOMAIN" ] || [ -z "$ADMIN_EMAIL" ]; then
  echo "Error: Missing required parameters"
  echo "Usage: $0 --company 'Company Name' --subdomain companyname --admin admin@example.com"
  exit 1
fi

# Generate secure credentials
echo "Generating secure credentials..."
DB_PASSWORD=$(openssl rand -base64 16)
JWT_SECRET=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Create deployment directory
DEPLOY_DIR="/home/chris/realtor_pro/deployment/$SUBDOMAIN"
mkdir -p "$DEPLOY_DIR"

# Create .env file
echo "Creating environment configuration..."
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
EOL

echo "✅ Created configuration in $DEPLOY_DIR/.env"
echo ""
echo "🚀 Deploying to Supabase..."

# Deploy to Supabase using npx
cd "$DEPLOY_DIR"

echo "Initializing Supabase project..."
npx supabase init 2>/dev/null || echo "Supabase already initialized"

echo "Creating new Supabase project: $SUBDOMAIN"
npx supabase projects create "$SUBDOMAIN" \
  --db-password "$DB_PASSWORD" \
  --region us-east-1 \
  --plan free

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Admin credentials:"
echo "Email: $ADMIN_EMAIL"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "Next steps:"
echo "1. Update your DNS records"
echo "2. Run database migrations"
echo "3. Deploy your frontend"
