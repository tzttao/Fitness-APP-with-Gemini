# Docker Deployment Guide

## Quick Start

1. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env and set your GEMINI_API_KEY
   ```

2. **Run the application:**
   ```bash
   ./start.sh
   ```

Or manually:

```bash
# Build backend
./mvnw clean package -DskipTests

# Start all services
docker compose up -d
```

## Services & Ports

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 5173 | React SPA |
| Gateway | 8080 | API Gateway & Auth |
| Eureka | 8761 | Service Registry |
| Config Server | 8888 | Configuration Server |
| User Service | 8081 | User Management & JWT |
| Activity Service | 8082 | Activity CRUD & Queue Publisher |
| AI Service | 8083 | Gemini Consumer & Recommendations |
| PostgreSQL | 5432 | User Database |
| MongoDB | 27017 | Activity & Recommendation Database |
| RabbitMQ | 5672 | Message Queue |
| RabbitMQ Management | 15672 | Management UI (guest/guest) |
| Keycloak | 8181 | OAuth2/JWT Provider (admin/admin) |

## Health Checks

All services include health checks and proper startup dependencies. Use:

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f [service-name]

# View all logs
docker compose logs -f
```

## Development

For frontend development with hot reload:

```bash
cd fitness-app-frontend
npm install
npm run dev
```

The Vite dev server will proxy API requests to the Gateway at `http://localhost:8080`.

## Stopping

```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: This will delete all data)
docker compose down -v
```

## Troubleshooting

1. **Services failing to start**: Check if all required ports are available
2. **Build failures**: Ensure Java 21+ is installed and accessible
3. **Database connection errors**: Wait for health checks to pass
4. **Gemini API errors**: Verify your `GEMINI_API_KEY` in `.env`

## Architecture

The deployment follows this startup sequence:

1. **Infrastructure**: PostgreSQL, MongoDB, RabbitMQ, Keycloak
2. **Core Services**: Eureka, Config Server
3. **Business Services**: User, Activity, AI Services
4. **Gateway**: API Gateway (depends on all services)
5. **Frontend**: React SPA (proxies to Gateway)

All services are connected via a custom Docker network for internal communication.