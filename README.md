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

## Publicar una versión de la app (APK)

La APK la arma y la publica GitHub, firmada siempre con la misma clave (si cambiara la firma, Android no instala la versión nueva encima de la vieja). La clave está en los secrets del repo: no hace falta tenerla en la compu de nadie.

1. **Subir la versión** en `frontend/pubspec.yaml` (por ejemplo `version: 1.1.0+5` → `version: 1.1.1+6`): el número de antes del `+` es el que ve la gente; el de después, uno más que el anterior. Ese cambio va en un PR, como cualquier otro, y se mergea a `main`.
2. **Probar:** GitHub → **Actions** → **Publicar APK** → **Run workflow** (sobre `main`), con **"Solo probar"** marcado. Si todo pasa, la APK queda para bajar en la corrida (sección *Artifacts*).
3. **Publicar:** lo mismo, con **"Solo probar"** desmarcado. Crea el tag `v1.1.1` y la release con `finza-1.1.1.apk`, marcada como la última. La app avisa sola a quien tenga una versión anterior.

El workflow frena si la versión ya está publicada o no es mayor que la última, si fallan `flutter analyze` o `flutter test`, o si la APK no salió firmada con la clave de Finza. Siempre apunta al backend de producción.