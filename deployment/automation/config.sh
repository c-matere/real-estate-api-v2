#!/bin/bash

# Deployment Configuration
COMPANY_NAME="${COMPANY_NAME:-Test Company}"
SUBDOMAIN="${SUBDOMAIN:-testco}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"

# Supabase Configuration
SUPABASE_ORG_ID="eupwtyvfsnwzdsmlcunm"
SUPABASE_ACCESS_TOKEN="sbp_f773f2c1120392d9113b3a1a50f3723b303f758b"
SUPABASE_REGION="us-east-1"

# Generate secure credentials
JWT_SECRET=$(openssl rand -base64 32)
DB_PASSWORD=$(openssl rand -base64 16)
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Deployment directories
BASE_DIR="/home/chris/realtor_pro"
DEPLOY_DIR="${BASE_DIR}/deployment/${SUBDOMAIN}"

# API Configuration
API_NAME="api-${SUBDOMAIN}"
FRONTEND_NAME="${SUBDOMAIN}"

# URLs
API_URL="https://${API_NAME}.onrender.com"
FRONTEND_URL="https://${FRONTEND_NAME}.netlify.app"
