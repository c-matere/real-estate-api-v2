#!/bin/bash

# Exit on error
set -e

# Load configuration
CONFIG_FILE="./deploy/config/monitoring.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Monitoring config not found"
  exit 1
fi

# Install yq if not present
if ! command -v yq &> /dev/null; then
  echo "📦 Installing yq for YAML parsing..."
  sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  sudo chmod +x /usr/local/bin/yq
fi

# Function to send alerts
alert() {
  local entity=$1
  local service=$2
  local status=$3
  local details=$4
  
  local subject=$(yq e '.templates.alert_subject' "$CONFIG_FILE" | \
    ENTITY="$entity" ALERT_TYPE="$status" envsubst)
  
  local message=$(yq e '.templates.alert_message' "$CONFIG_FILE" | \
    ENTITY="$entity" SERVICE="$service" STATUS="$status" \
    DETAILS="$details" TIME="$(date)" \
    DASHBOARD_URL="https://render.com/dashboard" envsubst)
  
  # Send to Slack if webhook is configured
  local slack_webhook=$(yq e '.global.slack_webhook' "$CONFIG_FILE")
  if [ "$slack_webhook" != "null" ] && [ -n "${!slack_webhook}" ]; then
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"*${subject}*\n${message//"/\\\"}\"}" \
      "${!slack_webhook}" || true
  fi
  
  # Send email if email is configured
  local alert_email=$(yq e '.global.alert_email' "$CONFIG_FILE")
  if [ "$alert_email" != "null" ] && [ -n "$alert_email" ]; then
    echo -e "Subject: $subject\n\n$message" | sendmail "$alert_email" || true
  fi
}

# Function to check service health
check_service() {
  local entity=$1
  local service=$2
  local url=$3
  local config_path=$4
  
  echo "🔍 Checking $service at $url"
  
  # Get check configuration
  local path=$(yq e ".health_checks.$service.path" "$CONFIG_FILE")
  local expected_status=$(yq e ".health_checks.$service.expected_status" "$CONFIG_FILE")
  local timeout=$(yq e ".health_checks.$service.timeout" "$CONFIG_FILE")
  
  # Perform health check
  local start_time=$(date +%s%3N)
  local response
  
  set +e
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time $timeout \
    "$url$path" 2>/dev/null)
  local exit_code=$?
  set -e
  
  local end_time=$(date +%s%3N)
  local response_time=$((end_time - start_time))
  
  # Check response
  if [ $exit_code -ne 0 ] || [ "$response" != "$expected_status" ]; then
    echo "❌ $service is DOWN (Status: ${response:-timeout}, Time: ${response_time}ms)"
    alert "$entity" "$service" "CRITICAL" "Service is down. Status: ${response:-timeout}, Time: ${response_time}ms"
    return 1
  else
    echo "✅ $service is HEALTHY (Status: $response, Time: ${response_time}ms)"
    
    # Check if response time is within threshold
    local threshold=$(yq e '.alert_thresholds.response_time' "$CONFIG_FILE")
    if [ $response_time -gt $threshold ]; then
      echo "⚠️  $service response time ${response_time}ms exceeds threshold ${threshold}ms"
      alert "$entity" "$service" "WARNING" "High response time: ${response_time}ms (threshold: ${threshold}ms)"
    fi
    
    return 0
  fi
}

# Main execution
if [ -z "$1" ]; then
  echo "Usage: $0 <entity>"
  echo "Available entities:"
  ls -1 deploy/config/ | grep -v monitoring.yaml | sed 's/\.yaml$//'
  exit 1
fi

ENTITY=$1
ENTITY_CONFIG="./deploy/config/${ENTITY}.yaml"

if [ ! -f "$ENTITY_CONFIG" ]; then
  echo "❌ Config not found for entity: $ENTITY"
  exit 1
fi

# Get service URLs from entity config
FRONTEND_URL=$(yq e '.frontend.environment.REACT_APP_API_URL' "$ENTITY_CONFIG" | sed 's|/api$||')
API_URL=$(yq e '.frontend.environment.REACT_APP_API_URL' "$ENTITY_CONFIG" | sed 's|/api$||')

# Run health checks
check_service "$ENTITY" "frontend" "$FRONTEND_URL" "$ENTITY_CONFIG" || true
check_service "$ENTITY" "api" "$API_URL" "$ENTITY_CONFIG" || true

echo "✅ Monitoring completed for $ENTITY"
