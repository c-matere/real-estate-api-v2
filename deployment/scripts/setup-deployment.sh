#!/bin/bash
set -e

echo "Setting up deployment environment..."

# Install required tools
echo "Installing required tools..."
sudo apt-get update
sudo apt-get install -y jq curl git

# Install Node.js if not installed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install Netlify CLI
echo "Installing Netlify CLI..."
sudo npm install -g netlify-cli

# Install Render CLI
echo "Installing Render CLI..."
curl -sL https://cli.render.com/install.sh | sudo sh

echo "Environment setup complete!"
