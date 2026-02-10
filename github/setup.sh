#!/bin/bash
# Quick start script for GitHub Actions Runner with Akaunting

set -e

echo "═══════════════════════════════════════════════════════════"
echo "  GitHub Actions Runner Setup for Akaunting"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp .env.example .env
    echo ""
    echo "📝 Please edit the .env file with your configuration:"
    echo "   - REPO_URL: Your GitHub repository URL"
    echo "   - RUNNER_TOKEN: Your GitHub runner token"
    echo ""
    echo "To get your runner token:"
    echo "1. Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/actions/runners/new"
    echo "2. Copy the token provided"
    echo "3. Edit .env file: nano .env"
    echo ""
    read -p "Press Enter after updating .env file to continue..."
fi

# Source the .env file
source .env

# Validate required variables
if [ -z "$REPO_URL" ] || [ "$REPO_URL" = "https://github.com/YOUR_USERNAME/YOUR_REPO" ]; then
    echo "❌ Error: REPO_URL not configured in .env file"
    exit 1
fi

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "YOUR_RUNNER_TOKEN_HERE" ]; then
    echo "❌ Error: RUNNER_TOKEN not configured in .env file"
    exit 1
fi

echo "✅ Configuration validated"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Stop existing containers
echo "🛑 Stopping existing containers (if any)..."
docker-compose -f docker-compose-github.yml down 2>/dev/null || true
echo ""

# Build the containers
echo "🔨 Building Docker containers..."
echo "This may take several minutes on first run..."
docker-compose -f docker-compose-github.yml build
echo ""

# Start the containers
echo "🚀 Starting containers..."
docker-compose -f docker-compose-github.yml up -d
echo ""

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
timeout=60
counter=0
until docker exec github-mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    counter=$((counter+1))
    if [ $counter -gt $timeout ]; then
        echo "❌ MySQL failed to start within ${timeout} seconds"
        exit 1
    fi
    echo -n "."
    sleep 1
done
echo ""
echo "✅ MySQL is ready"
echo ""

# Check runner status
echo "🔍 Checking runner status..."
sleep 5
docker-compose -f docker-compose-github.yml ps
echo ""

# Show logs
echo "📋 Recent runner logs:"
echo "────────────────────────────────────────────────────────────"
docker-compose -f docker-compose-github.yml logs --tail=20 github-runner
echo "────────────────────────────────────────────────────────────"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  ✅ Setup Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📊 Monitoring URLs:"
echo "   - cAdvisor: http://localhost:9102"
echo ""
echo "💾 Database Access:"
echo "   - Host: localhost"
echo "   - Port: 3307"
echo "   - Database: akaunting"
echo "   - User: akaunting"
echo "   - Password: akaunting_password"
echo ""
echo "🔧 Useful Commands:"
echo "   - View logs: docker-compose -f docker-compose-github.yml logs -f"
echo "   - Stop runner: docker-compose -f docker-compose-github.yml down"
echo "   - Restart: docker-compose -f docker-compose-github.yml restart"
echo ""
echo "📚 Next Steps:"
echo "   1. Check GitHub repo settings → Actions → Runners"
echo "   2. Your runner should appear as 'Idle'"
echo "   3. Push code to trigger the pipeline"
echo "   4. Monitor pipeline in Actions tab"
echo ""
echo "═══════════════════════════════════════════════════════════"
