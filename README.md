# Finza - Docker Setup

## Prerequisites
- Docker & Docker Compose installed
- Ports 8080 (app) and 5432 (db) available

## Quick Start
```bash
git clone <repo-url>
cd Finza
docker compose up --build
```

## Access
- **API**: http://localhost:8080
- **PostgreSQL**: `localhost:5432` (user: `finza`, pass: `finza`, db: `finza`)

## Useful Commands
```bash
# Run in background
docker compose up -d --build

# View logs
docker compose logs -f app
docker compose logs -f db

# Stop & remove containers (keeps DB data)
docker compose down

# Stop & remove everything (including DB volume)
docker compose down -v

# Rebuild only app after code changes
docker compose up -d --build app
```

## Environment Variables (Optional Override)
Create `.env` in root:
```env
DB_HOST=db
DB_PORT=5432
DB_NAME=finza
DB_USER=finza
DB_PASS=finza
```

## Project Structure
```
Finza/
├── backend/              # Spring Boot app
│   ├── Dockerfile
│   └── src/main/resources/
│       ├── application.properties
│       └── application-docker.properties
├── docker-compose.yml
└── README.md
```

## Troubleshooting
- **App fails to start**: Check `docker compose logs app` — usually DB not ready yet (healthcheck handles this)
- **Port conflicts**: Change ports in `docker-compose.yml`
- **DB connection refused**: Ensure `db` service is healthy (`docker compose ps`)