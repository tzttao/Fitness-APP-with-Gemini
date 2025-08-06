# Fitness‑APP‑with‑Gemini 🧠🏋️‍♂️

> **A micro‑services fitness platform powered by Google Gemini AI.** Automatically analyses every workout, pushes personalised feedback through RabbitMQ, and exposes all services behind a Spring Cloud Gateway.


---

## 📜 Table of Contents

1. [Overview](#overview)
2. [Architecture](#high-level-architecture)
3. [Tech stack](#tech-stack)
4. [Code layout](#code-layout)
5. [Getting started](#getting-started)
6. [Front‑end dev](#front-end-dev)
7. [Docker Deployment](#docker-deployment)
8. [Flow diagram](#flow-diagram)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)
11. [License](#license)

---

## Overview

`Fitness‑APP‑with‑Gemini` is a polyglot Spring Boot 3 project that ingests raw activity data (runs, cycles, gym logs etc.), sends it through **RabbitMQ**, and enriches it using **Google Gemini 2.0‑Flash**. The returned JSON recommendation is written back to the datastore and surfaced to the client app via REST behind **Spring Cloud Gateway**.

```
Client → Gateway → activity‑service → RabbitMQ → ai‑service → Gemini → activity‑service → Client
```

Key goals ✦ fast async processing, stateless services, centralised configuration, **100% automated local bootstrap with Docker Compose**.

---

## High‑level architecture

```text
                         ┌─────────────────────────────┐
                         │  Config‑Server (Git‑backed) │
                         └────────────┬────────────────┘
                                      │
                  ┌───────────────────▼────────────────────┐
                  │        Eureka Service Registry         │
                  └───────────────────┬────────────────────┘
                                      │
        ┌─────────────────────────────┴────────────────────────────┐
        │                Spring  Cloud  Gateway                    │
        └───────────┬──────────────────┬────────────────────┬──────┘
                    │                  │                    │
        ┌─────────▼────────┐ ┌─────────▼────────┐  ┌────────▼─────────┐
        │   user‑service   │ │    ai‑service    │  │ activity‑service │
        └─────────┬────────┘ └───────┬──────────┘  └────────┬─────────┘
                  │                  │                      │ 
            JWT(Keycloak)     WebClient (Gemini)      RabbitMQ queue
```

* **user-service** – Manages user registration, login, profile CRUD and issues JWTs consumed by Gateway.
* **activity‑service** – REST CRUD for activities, publishes each new activity to the queue and persists AI feedback.
* **ai‑service** – Listens to `activity.queue`, calls Gemini with a structured prompt, returns JSON recommendation.
* **gateway** – Routes `/api/**` to downstream services, performs JWT auth.
* **config‑server** – Centralised Spring Cloud Config backed by the `/config` folder.
* **eureka‑server** – Service discovery.

---

## Tech stack

| Layer     | Tech                                               |
| --------- | -------------------------------------------        |
| Language  | Java 21, React 18 (Vite 5)                         |
| Database  | PostgreSQL (User), MongoDB (activities, recommendations)|
| Runtime   | Spring Boot 3.4.x, Spring Cloud 2025.0.x           |
| Reactive  | Spring WebFlux (WebClient)                         |
| Messaging | RabbitMQ 4 (AMQP‑0‑9‑1)                         |
| AI        | Google gemini-2.0-flash-exp                            |
| Auth      | Keycloak 26 + JWT (via Gateway filter)             |
| Config    | Spring Cloud Config Server (native profile)        |
| Discovery | Netflix Eureka                                     |
| Build     | Maven Wrapper (mvnw)                               |
| DevOps    | Docker & Docker Compose                            |

---

## Code layout

```
fitness-app/
├── fitness-app-frontend/   # Vite + React SPA
├── gateway/               # Spring Cloud Gateway
├── eureka/                # Service Registry
├── configserver/          # Centralised config
├── userservice/           # User CRUD + JWT issuing
├── activityservice/       # REST + queue publisher
├── aiservice/             # Gemini consumer
├── config/                # *.yml shared configs loaded by config‑server
├── docker-compose.yml     # One‑click deployment stack
├── start.sh               # Deployment script
├── .env.example           # Environment template
├── pom.xml                # Root Maven aggregator
└── README.md              # You are here
```

> **Database** – PostgreSQL for Users, MongoDB for Activities and AI recommendations.

---

## Getting started

### Prerequisites

- Docker Engine 20+
- Docker Compose
- Google AI Studio key (Gemini 2.0)

### Quick Start (One-Click Deployment)

```bash
# 1 · clone
$ git clone https://github.com/tzttao/Fitness-APP-with-Gemini.git
$ cd Fitness-APP-with-Gemini

# 2 · set up environment
$ cp .env.example .env
# Edit .env and set your GEMINI_API_KEY

# 3 · start everything with one command
$ ./start.sh
```

**Alternative manual deployment:**

```bash
$ ./mvnw clean package -DskipTests
$ docker compose up -d
```

**Services will be available at:**
- **Frontend SPA**: [http://localhost:5173](http://localhost:5173)
- **API Gateway**: [http://localhost:8080](http://localhost:8080)
- **Eureka Dashboard**: [http://localhost:8761](http://localhost:8761)
- **Keycloak Admin**: [http://localhost:8181](http://localhost:8181) (admin/admin)
- **RabbitMQ Management**: [http://localhost:15672](http://localhost:15672) (guest/guest)

---

## Front‑end dev

For development with hot-reload:

```bash
$ cd fitness-app-frontend
$ npm install
$ npm run dev # Vite hot‑reload (5173)
```

The Vite dev server proxies `/api` & `/auth` to `localhost:8080` so CORS is worry‑free.

---

## Docker Deployment

The application is fully containerized with Docker Compose. All infrastructure dependencies (PostgreSQL, MongoDB, RabbitMQ, Keycloak) are automatically provisioned.

### Service Architecture

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
| RabbitMQ | 5672/15672 | Message Queue & Management UI |
| Keycloak | 8181 | OAuth2/JWT Provider |

### Management Commands

```bash
# View service status
$ docker compose ps

# View logs
$ docker compose logs -f [service-name]

# Stop all services
$ docker compose down

# Stop and remove all data (WARNING: destructive)
$ docker compose down -v
```

For detailed deployment information, see [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md).

---

## Flow diagram

| Step | Path / queue               | Action                                |
| ---- | -------------------------- | ------------------------------------- |
| 1    | `POST /auth/register`      | userservice creates user              |
| 2    | `POST /auth/login`         | returns JWT + refresh                 |
| 3    | `POST /api/activities`     | activityservice saves & publishes msg |
| 4    | `activity.queue`           | aiservice consumes, calls Gemini      |
| 5    | `activities + activity_ai` | AI JSON merged & saved                |
| 6    | `GET /api/activities/{id}` | SPA fetches personalised advice       |

---

## Troubleshooting

| Symptom | Suggestion |
|---------|------------|
| `org.postgresql.util.PSQLException: Connection refused` | Wait for PostgreSQL health check: `docker compose logs postgres` |
| `400 Bad Request` from Gemini | Verify `GEMINI_API_KEY` in `.env` file |
| `403` on API endpoints | JWT missing/expired—check Keycloak configuration |
| Services failing to start | Check port availability and Docker resources |
| Queue processing hangs | Verify RabbitMQ is healthy: `docker compose logs rabbitmq` |
| Build failures | Ensure Docker has sufficient memory (4GB+ recommended) |

**Health Checks**: All services include health checks and proper startup dependencies. Use `docker compose ps` to verify service status.

---

## Contributing

1. Fork → branch → PR.
2. Commit style: `feat: …`, `fix: …`, `docs: …`.
3. All services must build successfully: `./mvnw clean package -DskipTests`
4. Frontend tests must pass: `cd fitness-app-frontend && npm test`
5. Docker deployment must work: `./start.sh`

---

## License

Released under the MIT License — add `LICENSE` file or run `pnpm dlx license mit` to generate.