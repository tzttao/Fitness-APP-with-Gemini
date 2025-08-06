#!/bin/bash

echo "🏋️‍♂️ Fitness App with Gemini - Docker Deployment"
echo "================================================"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  Warning: .env file not found!"
    echo "Please create a .env file based on .env.example and set your GEMINI_API_KEY"
    echo ""
    echo "Example:"
    echo "cp .env.example .env"
    echo "# Then edit .env and set your GEMINI_API_KEY"
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "🔧 Building backend services..."
./mvnw clean package -DskipTests -q

if [ $? -eq 0 ]; then
    echo "✅ Backend build completed successfully"
else
    echo "❌ Backend build failed"
    exit 1
fi

echo ""
echo "🐳 Starting Docker containers..."
docker compose up -d

echo ""
echo "🌐 Services will be available at:"
echo "  • Gateway/API: http://localhost:8080"
echo "  • Frontend: http://localhost:5173"
echo "  • Eureka Dashboard: http://localhost:8761"
echo "  • Keycloak Admin: http://localhost:8181 (admin/admin)"
echo "  • RabbitMQ Management: http://localhost:15672 (guest/guest)"
echo ""
echo "📊 Monitor logs with: docker compose logs -f [service-name]"
echo "🛑 Stop all services with: docker compose down"