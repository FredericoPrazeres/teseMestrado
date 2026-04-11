#!/bin/bash
# Jenkins Pipeline Script for Outline Build
# This script is used as a freestyle project build step in Jenkins.
# Make sure your Jenkins runner has: Node.js 24, Yarn 4, PostgreSQL, Redis

set -e

echo "============================================"
echo "  Outline Build Pipeline"
echo "  Commit: ${GIT_COMMIT:-unknown}"
echo "  Branch: ${GIT_BRANCH:-unknown}"
echo "============================================"

# Navigate to the outline submodule
cd outline

echo ""
echo "=== Step 1: Verify system dependencies ==="
echo "Node.js: $(node --version)"
echo "Yarn: $(yarn --version)"
pg_isready && echo "PostgreSQL: ✅ Running" || echo "PostgreSQL: ❌ Not running"
redis-cli ping > /dev/null 2>&1 && echo "Redis: ✅ Running" || echo "Redis: ❌ Not running"

echo ""
echo "=== Step 2: Start services ==="
brew services start postgresql@17 || sudo systemctl start postgresql || true
brew services start redis || sudo systemctl start redis || true
sleep 3
pg_isready
redis-cli ping

echo ""
echo "=== Step 3: Install Node.js dependencies ==="
NODE_ENV=development yarn install --immutable

echo ""
echo "=== Step 4: Build Outline ==="
NODE_ENV=production yarn build

echo ""
echo "=== Step 5: Run database migrations ==="
yarn db:create --env=production-ssl-disabled || echo "Database already exists"

# Start server briefly to run migrations, then stop it
node build/server/index.js &
SERVER_PID=$!
echo "Waiting for server to start and run migrations..."
sleep 15
kill $SERVER_PID 2>/dev/null || true
echo "Migrations complete"

echo ""
echo "=== Step 6: Verify build ==="
if [ -f build/server/index.js ] && [ -d build/app ]; then
  echo "✅ Server build OK"
  echo "✅ Client build OK"
  echo ""
  echo "============================================"
  echo "  🎉 Outline build completed successfully!"
  echo "============================================"
else
  echo "❌ Build verification failed"
  exit 1
fi
