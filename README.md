# Fitness‑APP‑with‑Gemini 🧠🏋️‍♂️

> **A micro‑services fitness platform powered by Google Gemini AI.** Automatically analyses every workout, pushes personalised feedback through RabbitMQ, and exposes all services behind a Spring Cloud Gateway.


---

## 📜 Table of Contents

1. [Overview](#overview)
2. [Architecture](#highlevelarchitecture)
3. [Tech stack](#tech-stack)
4. [Code layout](#codelayout)
5. [Getting started](#gettingstarted)
6. [Front‑end dev](#frontenddev)
7. [Docker Compose](#dockercompose)
8. [Flow diagram](#flowdiagram)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)
11. [License](#license)

---

## Overview

`Fitness‑APP‑with‑Gemini` is a polyglot Spring Boot 3 project that ingests raw activity data (runs, cycles, gym logs etc.), sends it through **RabbitMQ**, and enriches it using **Google Gemini 1.5‑Pro**. The returned JSON recommendation is written back to the datastore and surfaced to the client app via REST behind **Spring Cloud Gateway**.

```
Client → Gateway → activity‑service → RabbitMQ → ai‑service → Gemini → activity‑service → Client
```

Key goals ✦ fast async processing, stateless services, centralised configuration, 100% automated local bootstrap with Docker Compose.

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

## Tech stack

| Layer     | Tech                                               |
| --------- | -------------------------------------------        |
| Language  | Java 21, React 18 (Vite 5)                         |
| Database  | Postgre(User), MongoDB(activities, recommendations)|
| Runtime   | Spring Boot 3.4.x, Spring Cloud 2025.0.x           |
| Reactive  | Spring WebFlux (WebClient)                         |
| Messaging | RabbitMQ 3.13 (AMQP‑0‑9‑1)                         |
| AI        | Google gemini-2.0-flash                            |
| Auth      | Keycloak 23 + JWT (via Gateway filter)             |
| Config    | Spring Cloud Config Server (native profile)        |
| Discovery | Netflix Eureka                                     |
| Build     | Maven Wrapper (mvnw)                               |
| DevOps    | Docker & Docker Compose                            |

---

## Code layout

```
fitness-app/
├── fitness-app-frontend/   # Vite + React SPA
├── gateway/               # Spring Cloud Gateway
├── eureka-server/         # Service Registry
├── config-server/         # Centralised config
├── userservice/           # User CRUD + JWT issuing
├── activity-service/      # REST + queue publisher
├── ai-service/            # Gemini consumer
├── config/                # *.yml shared configs loaded by config‑server
├── docker-compose.yml     # One‑shot local stack
└── README.md              # You are here
```

> **Database** – swap‑able: default profile uses in‑memory H2; prod profile points to Postgres.

---

## Getting started

### Prerequisites

- JDK 21+ & Maven 3.9+
- Node 20+ (front‑end)
- Docker Engine 20+
- Google AI Studio key (Gemini 2.0)

```bash
# 1 · clone
$ git clone https://github.com/tzttao/Fitness-APP-with-Gemini.git
$ cd Fitness-APP-with-Gemini

# 2 · build back‑end
$ ./mvnw -q clean package -DskipTests

# 3 · set env vars
echo "GEMINI_API_KEY=xxx" >> .env
```

### Spin up everything

```bash
$ docker compose up -d   # db, rabbit, config, eureka, gateway, userservice, activityservice, aiservice, frontend
```

Gateway → [http://localhost:8080](http://localhost:8080) • SPA → [http://localhost:5173](http://localhost:5173)

---

## Front‑end dev

```bash
$ cd fitness-app-frontend
$ pnpm i   # or npm install
$ pnpm dev # Vite hot‑reload (5173)
```

The Vite dev server proxies `/api` & `/auth` to `localhost:8080` so CORS is worry‑free.

---

## Docker

```bash
# install rabbitmq
$ docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:4-management

# install keycloak
$ docker run -p 127.0.0.1:8080:8080 -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:26.3.1 start-dev

```

---

## Flow diagram

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

| Symptom                                                 | Suggestion                                        |
| ------------------------------------------------------- | ------------------------------------------------- |
| `org.postgresql.util.PSQLException: Connection refused` | db container not healthy—`docker compose logs db` |
| `400 Bad Request` from Gemini                           | verify API key & request schema                   |
| `403` on API                                            | JWT missing/expired—re‑login                      |
| Queue hangs                                             | RabbitMQ down (5672) or cannot reach aiservice    |

---

## Contributing

1. Fork → branch → PR.
2. Commit style: `feat: …`, `fix: …`, `docs: …`.
3. `./mvnw verify` + `pnpm test` must pass.

---

## License

Released under the MIT License — add `LICENSE` file or run `pnpm dlx license mit` to generate.
