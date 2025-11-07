#!/bin/bash

echo "============================================"
echo "🌐 DJANGO NT8 BROWSER TESTING - QUICK START"
echo "============================================"
echo ""

# Check if services are running
echo "📋 Checking service status..."
docker-compose ps --format "table {{.Name}}\t{{.Status}}" | grep -E "(nginx|web|db|redis)"

echo ""
echo "🔍 Service Health Check..."
NGINX_STATUS=$(docker-compose ps nginx --format "{{.Status}}" 2>/dev/null)
WEB_STATUS=$(docker-compose ps web --format "{{.Status}}" 2>/dev/null)

if [[ "$NGINX_STATUS" == *"Up"* ]] && [[ "$WEB_STATUS" == *"healthy"* ]]; then
    echo "✅ All services healthy!"
else
    echo "⚠️  Starting required services..."
    docker-compose up -d nginx web db redis
    sleep 5
fi

echo ""
echo "============================================"
echo "🎯 BROWSER TESTING READY!"
echo "============================================"
echo ""
echo "📱 Access URLs:"
echo "   Dashboard:  https://localhost/ninja/dashboard/"
echo "   Admin:      https://localhost/admin/"
echo ""
echo "🔑 Credentials:"
echo "   Username: admin"
echo "   Password: fks2025admin!"
echo ""
echo "📖 Full Testing Guide:"
echo "   File: docs/BROWSER_TESTING_GUIDE.md"
echo ""
echo "⚠️  SSL Warning:"
echo "   - Browser will show 'not private' warning"
echo "   - Click 'Advanced' → 'Proceed to localhost'"
echo "   - This is expected (self-signed certificate)"
echo ""
echo "============================================"
echo "🚀 READY TO TEST!"
echo "============================================"
echo ""
echo "Open your browser and visit:"
echo "👉 https://localhost/ninja/dashboard/"
echo ""
