#!/bin/bash

# Exit on error
set -e

# Check if entity name is provided
if [ -z "$1" ]; then
  echo "❌ Error: Entity name is required"
  echo "Usage: $0 <entity>"
  exit 1
fi

# Load configuration
CONFIG_FILE="./deploy/config/$1.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found for $1"
  exit 1
fi

# Install yq if not present
if ! command -v yq &> /dev/null; then
  echo "📦 Installing yq for YAML parsing..."
  sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  sudo chmod +x /usr/local/bin/yq
fi

# Parse configuration
ENTITY=$(yq e '.entity' "$CONFIG_FILE")
ENVIRONMENT=$(yq e '.environment' "$CONFIG_FILE")

echo "🚀 Deploying $ENTITY ($ENVIRONMENT)"

# Deploy Frontend
if [ "$(yq e '.frontend.enabled // true' "$CONFIG_FILE")" = "true" ]; then
  echo "🌐 Deploying frontend for $ENTITY..."
  
  # Set environment variables
  while IFS="=" read -r key value; do
    if [ -n "$key" ]; then
      export "$key"="$value"
    fi
  done < <(yq e '.frontend.environment | to_entries | .[] | .key + "=" + .value' "$CONFIG_FILE")

  # Navigate to frontend directory (adjust path if needed)
  cd frontend || { echo "❌ Frontend directory not found"; exit 1; }
  
  # Install dependencies and build
  echo "🔧 Installing dependencies..."
  npm ci
  
  echo "🏗️  Building frontend..."
  npm run build
  
  # Deploy to Netlify
  echo "🚀 Deploying to Netlify..."
  npx netlify deploy \
    --prod \
    --dir=build \
    --site="$(yq e '.frontend.site_id' "$CONFIG_FILE")" \
    --auth="$NETLIFY_AUTH_TOKEN"
    
  cd ..
  echo "✅ Frontend deployment completed for $ENTITY"
fi

# Deploy API
if [ "$(yq e '.api.enabled // true' "$CONFIG_FILE")" = "true" ]; then
  echo "🔧 Updating API for $ENTITY..."
  
  # Update environment variables in Render
  ENV_VARS=()
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      ENV_VARS+=("$line")
    fi
  done < <(yq e '.api.environment | to_entries | .[] | .key + "=" + .value' "$CONFIG_FILE")
  
  # Join array with spaces for the command
  ENV_VARS_STR="${ENV_VARS[*]}"
  
  echo "🔄 Updating Render service..."
  render services update \
    "$(yq e '.api.service_id' "$CONFIG_FILE")" \
    --env-vars "$ENV_VARS_STR" \
    --auto-deploy
    
  echo "✅ API update initiated for $ENTITY"
  echo "ℹ️  Check Render dashboard for deployment progress"
fi

echo "✨ Deployment process completed for $ENTITY"
