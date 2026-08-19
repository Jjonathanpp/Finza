# Guía de Desarrollo en Equipo - Finza

> **Arquitectura**: Backend (Spring Boot) + BD (PostgreSQL) en Docker | Frontend (Flutter) en local

---

## 🏗️ Estructura del Proyecto

```
Finza/
├── backend/                 # Spring Boot 4.1 (Java 17, Maven)
│   ├── Dockerfile          # Multi-stage build
│   ├── pom.xml
│   └── src/
├── frontend/               # Flutter 3.x
│   ├── pubspec.yaml
│   └── lib/
├── docker-compose.yml      # Orquesta backend + postgres
├── .env.example            # Variables de entorno (copiar a .env)
└── README.md
```

---

## 🚀 Primer Setup (una sola vez por persona)

```bash
# 1. Clonar repo
git clone <url-del-repo>
cd Finza

# 2. Configurar variables (opcional, usa defaults si no existe)
cp .env.example .env
# Editar .env si querés cambiar puertos/passwords

# 3. Levantar backend + base de datos
docker compose up -d --build

# 4. Verificar que todo esté healthy
docker compose ps
# Debería mostrar: finza-db (healthy)  |  finza-app (running)

# 5. Frontend - cada uno en su máquina
cd frontend
flutter pub get
flutter run -d chrome   # o android/ios/device
```

---

## 🔄 Flujo Diario de Desarrollo

### Backend (cambios en Java)

```bash
# 1. Hacés tus cambios en backend/src/...

# 2. Rebuild y test local (compila incremental ~15-30s)
docker compose up -d --build app

# 3. Ver logs si algo falla
docker compose logs -f app

# 4. Testear endpoints (curl, Postman, o frontend local)
curl http://localhost:8080/api/tu-endpoint

# 5. Cuando funciona → commit + push
git add .
git commit -m "tipo: descripción corta"
git push origin main
```

### Frontend (cambios en Dart)

```bash
cd frontend
flutter run -d chrome   # Hot reload automático al guardar
# No necesita Docker, corre nativo
```

---

## 📥 Cuando un alguien Pushea Cambios

```bash
# 1. Actualizar código
git pull origin main

# 2. Si hubo cambios en backend → rebuild
docker compose up -d --build app

# 3. Si hubo cambios en frontend
cd frontend && flutter pub get

# 4. Continuar trabajando
```

---

## 🛠️ Comandos Útiles

| Acción | Comando |
|--------|---------|
| Ver estado contenedores | `docker compose ps` |
| Logs backend (follow) | `docker compose logs -f app` |
| Logs base de datos | `docker compose logs -f db` |
| Parar todo (mantiene BD) | `docker compose down` |
| **Parar y BORRAR BD** | `docker compose down -v` |
| Rebuild solo backend | `docker compose up -d --build app` |
| Entrar al contenedor backend | `docker exec -it finza-app sh` |
| Entrar a PostgreSQL | `docker exec -it finza-db psql -U finza -d finza` |
| Ver puertos en uso | `docker compose port app 8080` |

---

## 🔐 Variables de Entorno (.env)

```bash
# Copiar y editar si necesitás puertos distintos
cp .env.example .env
```

```env
# .env.example
DB_HOST=db
DB_PORT=5432
DB_NAME=finza
DB_USER=finza
DB_PASS=finza
APP_PORT=8080
```

> **Nota**: El `docker-compose.yml` usa estos valores con defaults. Si no existe `.env`, usa los defaults.

---

## 🗄️ Base de Datos

- **Persistencia**: Volumen `postgres_data` (sobrevive a `docker compose down`)
- **Resetear BD completa**: `docker compose down -v && docker compose up -d --build`
- **Conexión externa** (DBeaver, DataGrip): `localhost:5432` | user: `finza` | pass: `finza` | db: `finza`
- **Migraciones**: Hibernate `ddl-auto=update` (crea/actualiza tablas al arrancar)

---

## 🧪 Testing Backend

```bash
# Tests unitarios (dentro del contenedor)
docker compose run --rm app ./mvnw test

# O local (si tenés Java/Maven instalado)
cd backend && ./mvnw test
```

---

## ❓ Troubleshooting Común

| Problema | Solución |
|----------|----------|
| Puerto 8080/5432 ocupado | Cambiar `APP_PORT`/`DB_PORT` en `.env` |
| App no arranca (DB not ready) | `docker compose logs app` → esperar healthcheck |
| Cambios en Java no se ven | `docker compose up -d --build app` (rebuild obligatorio) |
| Error de dependencias Maven | `docker compose run --rm app ./mvnw clean install -DskipTests` |
| Frontend no conecta a API | Verificar que backend esté en `http://localhost:8080` |
| `git pull` tira conflictos | Resolver conflictos → `docker compose up -d --build app` |

---

## 📋 Checklist para Nuevos Integrantes

- [ ] Docker + Docker Compose instalados
- [ ] Git configurado (user.name, user.email)
- [ ] Clonado repo y `docker compose up -d --build` levanta sin errores
- [ ] `docker compose ps` muestra ambos healthy
- [ ] Frontend: `flutter doctor` OK, `flutter run` abre la app
- [ ] Puede ver logs con `docker compose logs -f app`
- [ ] Entiende: código → `git push` → compañeros `git pull` → `docker compose up -d --build app`

---

## 🎯 Reglas de Oro 

1. **Nunca** commiteen `target/`, `*.jar`, `.class`, `build/` (ya está en `.gitignore`)
2. **Siempre** testeen local con `docker compose up -d --build app` antes de pushear
3. **Pull antes de push** → evita conflictos
4. **Commits pequeños y descriptivos**: `feat: login jwt`, `fix: validación email`
5. **Backend en Docker siempre** → mismo entorno para todos
6. **Frontend en local** → hot reload rápido, sin overhead

---

## 🔗 Referencias Rápidas

- **API Base URL**: `http://localhost:8080`
- **Actuator Health**: `http://localhost:8080/actuator/health`
- **Swagger/OpenAPI** (si está configurado): `http://localhost:8080/swagger-ui.html`
- **PostgreSQL**: `jdbc:postgresql://localhost:5432/finza` (desde host) / `jdbc:postgresql://db:5432/finza` (desde contenedor)

---

## 📝 Notas para Futuro

- [ ] Agregar GitHub Actions CI (build + test en PR)
- [ ] Configurar `spring-boot-devtools` para hot reload en Docker (opcional)
- [ ] Docker multi-arch para Apple Silicon / ARM
- [ ] Staging environment con `docker-compose.staging.yml`

---

*Última actualización: 2026-08-19*