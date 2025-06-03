#!/bin/bash

# Exit on error
set -e

# Check if .env file exists
if [ ! -f .env ]; then
  echo "Creating .env file..."
  cat > .env <<EOL
# Grafana
GRAFANA_ADMIN_PASSWORD=admin123

# Prometheus
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
NODE_EXPORTER_PORT=9100
CADVISOR_PORT=8080
BLACKBOX_PORT=9115

# Add any additional environment variables here
EOL
  echo "Created .env file. Please update the default passwords and ports if needed."
  chmod 600 .env
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

# Create required directories
mkdir -p prometheus_data grafana_data

# Set permissions
chmod -R 777 prometheus_data grafana_data

# Start the stack
echo "Starting monitoring stack..."
docker-compose up -d

echo ""
echo "========================================"
echo "Monitoring stack started successfully!"
echo ""
echo "Grafana:     http://localhost:3000"
echo "  - Username: admin"
echo "  - Password: $GRAFANA_ADMIN_PASSWORD"
echo ""
echo "Prometheus:  http://localhost:9090"
echo "Node Exporter: http://localhost:9100"
echo "cAdvisor:    http://localhost:8080"
echo "Blackbox:    http://localhost:9115"
echo ""
echo "To stop the stack, run: docker-compose down"
echo "To view logs, run: docker-compose logs -f"
echo "========================================"
echo ""
