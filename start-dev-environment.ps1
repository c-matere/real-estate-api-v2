# Script to start the development environment for the Real Estate Dashboard application
# This script will start both the backend API and the frontend React application

# Set working directories
$apiDir = ".\real-estate-api"
$dashboardDir = ".\real-estate-dashboard"

# Function to check if Docker is running
function Check-Docker {
    try {
        $dockerStatus = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
            return $false
        }
        return $true
    }
    catch {
        Write-Host "Docker is not installed or not in PATH. Please install Docker Desktop first." -ForegroundColor Red
        Write-Host "You can run the install-docker.ps1 script in the real-estate-api directory." -ForegroundColor Yellow
        return $false
    }
}

# Function to check if PostgreSQL container is running
function Check-PostgreSQL {
    try {
        $container = docker ps --filter "name=real-estate-postgres" --format "{{.Names}}"
        if ($container -ne "real-estate-postgres") {
            Write-Host "PostgreSQL container is not running. Starting it now..." -ForegroundColor Yellow
            
            # Change to API directory and start Docker Compose
            Push-Location $apiDir
            docker-compose up -d
            Pop-Location
            
            # Wait for PostgreSQL to be ready (increased wait time)
            Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
            Start-Sleep -Seconds 15
            
            # Test the database connection
            Push-Location $apiDir
            Write-Host "Testing database connection..." -ForegroundColor Yellow
            docker exec real-estate-postgres pg_isready -U postgres
            Pop-Location
        }
        else {
            Write-Host "PostgreSQL container is already running." -ForegroundColor Green
        }
        return $true
    }
    catch {
        Write-Host "Error checking PostgreSQL container: $_" -ForegroundColor Red
        return $false
    }
}

# Function to install dependencies
function Install-Dependencies {
    # Install API dependencies
    Write-Host "Installing API dependencies..." -ForegroundColor Yellow
    Push-Location $apiDir
    npm install
    Pop-Location
    
    # Install Dashboard dependencies
    Write-Host "Installing Dashboard dependencies..." -ForegroundColor Yellow
    Push-Location $dashboardDir
    npm install
    Pop-Location
}

# Function to seed the database
function Seed-Database {
    Write-Host "Seeding the database..." -ForegroundColor Yellow
    Push-Location $apiDir
    npm run seed
    Pop-Location
}

# Function to start the backend API
function Start-Backend {
    Write-Host "Starting the backend API..." -ForegroundColor Yellow
    Push-Location $apiDir
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev"
    Pop-Location
}

# Function to start the frontend dashboard
function Start-Frontend {
    Write-Host "Starting the frontend dashboard..." -ForegroundColor Yellow
    Push-Location $dashboardDir
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start"
    Pop-Location
}

# Main script execution
Write-Host "Starting Real Estate Dashboard Development Environment" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Check Docker and PostgreSQL
if (-not (Check-Docker)) {
    exit 1
}

if (-not (Check-PostgreSQL)) {
    exit 1
}

# Ask if user wants to install dependencies
$installDeps = Read-Host "Do you want to install dependencies? (y/n)"
if ($installDeps -eq "y") {
    Install-Dependencies
}

# Ask if user wants to seed the database
$seedDb = Read-Host "Do you want to seed the database? (y/n)"
if ($seedDb -eq "y") {
    Seed-Database
}

# Start the backend and frontend
Start-Backend
Start-Frontend

Write-Host "Development environment is now running!" -ForegroundColor Green
Write-Host "Backend API: http://localhost:5000" -ForegroundColor Cyan
Write-Host "Frontend Dashboard: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C in each terminal window to stop the services." -ForegroundColor Yellow
