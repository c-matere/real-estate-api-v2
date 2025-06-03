#!/bin/bash
set -e

# Load environment variables
source "/home/chris/realtor_pro/deployment/testco/.env"

echo "Initializing database for Test Company..."

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
ADMIN_EMAIL="admin@testco.com" ADMIN_PASSWORD="Fkcu+P9JQ9XsOMio" node scripts/seed-admin.js

echo "Database initialization complete!"
