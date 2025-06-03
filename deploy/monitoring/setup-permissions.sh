#!/bin/bash

# Create necessary directories if they don't exist
mkdir -p prometheus_data grafana_data

# Set permissions
chmod -R 777 prometheus_data grafana_data

echo "✅ Permissions set up successfully"
