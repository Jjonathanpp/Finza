# Finza - Backend (Spring Boot)

API REST para Finza. El backend maneja autenticación, movimientos, categorías, presupuestos y conexión con Mercado Pago.

## Requisitos

- Java 17
- Maven (incluido con `./mvnw`)
- PostgreSQL (corriendo en Docker o local)

## Arrancar el proyecto

```bash
# Con Docker (levanta backend + PostgreSQL)
docker compose up -d --build

# Sin Docker (necesitás PostgreSQL corriendo aparte)
cd backend
./mvnw spring-boot:run
```

El backend arranca en `http://localhost:8080`. La configuración de la base de datos está en `application-docker.properties` para Docker y en `application.properties` para desarrollo local.

## Estructura del proyecto

```
src/main/java/com/finza/backend/
├── BackendApplication.java    # Entry point de la app
├── config/                    # Configuración de Spring Security, CORS, JWT
├── controller/                # Endpoints REST
├── dto/                       # Request y Response DTOs
├── exception/                 # Excepciones y handler global
├── model/                     # Entidades JPA
├── repository/                # Interfaces JpaRepository
└── service/                   # Lógica de negocio
    └── impl/                  # Implementaciones concretas
```

Cada paquete tiene un `.gitkeep` para que git lo conserve. Los archivos van a medida que se implementan las funcionalidades.

## Qué va en cada paquete

### `config/`

Configuración de la app que no es de negocio. Va todo lo que Spring necesita para funcionar: Security (quién puede acceder a qué), CORS (desde dónde se conecta el frontend), filtros JWT, y demás configuraciones globales.

`SecurityConfig.java` es el que define las reglas de acceso a los endpoints. Ahora mismo permite todo (sin auth), pero va a crecer cuando se implemente JWT.

### `controller/`

Los endpoints REST. Cada controller recibe una request HTTP, validá los datos, llamá al service correspondiente y devolvé una response. No tiene lógica de negocio: si un controller tiene más de 3-4 líneas de lógica, esa lógica debería estar en el service.

Naming: `AuthController`, `MovimientoController`, `CategoriaController`. Un controller por recurso.

### `service/`

La lógica de negocio. Acá se procesan las reglas: validar que un movimiento no supere el presupuesto, calcular balances, generar reportes. Los services no saben de HTTP ni de JPA: reciben datos, los procesan y devuelven resultados.

`service/` tiene las interfaces. `service/impl/` tiene las implementaciones. Esta separación existe para poder testear con mocks y para mantener el desacoplamiento entre capas.

Ej: `MovimientoService` (interfaz) → `MovimientoServiceImpl` (implementación).

### `repository/`

Interfaces JPA. Acceso a datos. Cada repository es una interfaz que extiende `JpaRepository<Entity, Id>` y Spring genera la implementación automáticamente con queries derivadas del nombre de los métodos.

Ej: `UsuarioRepository` con `findByEmail(String email)` busca un usuario por email. No hay que escribir SQL.

### `model/`

Entidades JPA. Mapean las tablas de la base de datos. Cada entity tiene anotaciones `@Entity`, `@Table`, `@Id`, `@Column`, y relaciones (`@OneToMany`, `@ManyToOne`, etc.). Se usa Lombok para evitar boilerplate (`@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`).

Entidades: `Usuario`, `Categoria`, `Movimiento`, `Presupuesto`, `ConexionMercadoPago`, `TokenRecuperacion`, `HistorialMovimiento`.

### `dto/`

Data Transfer Objects. Objetos que se usan para intercambiar datos entre capas. Los DTOs de request representan lo que el frontend envía. Los DTOs de response representan lo que el backend devuelve. Las entidades JPA no se exponen directamente al controller.

Ej: `LoginRequest` (email + contraseña), `MovimientoDTO` (datos de un movimiento para la API).

### `exception/`

Excepciones personalizadas y el handler global. `GlobalExceptionHandler` captura las excepciones y devuelve respuestas JSON con el formato correcto (status code, mensaje de error). Así no hay `try/catch` esparcidos por los controllers.

Ej: `ResourceNotFoundException` cuando no se encuentra algo, `GlobalExceptionHandler` que la convierte en una respuesta 404.

## Regla para decidir dónde poner algo

1. ¿Es configuración de Spring (Security, CORS, beans)? → `config/`
2. ¿Es un endpoint REST? → `controller/`
3. ¿Es lógica de negocio? → `service/`
4. ¿Es acceso a datos (queries, JPA)? → `repository/`
5. ¿Mapea una tabla de la BD? → `model/`
6. ¿Es un request o response de la API? → `dto/`
7. ¿Es manejo de errores? → `exception/`

## Testing

Los tests BDD van en la carpeta `testing/` del repo raíz, usando Cucumber.js con Gherkin. El servicio `test` en `docker-compose.yml` se encarga de levantar el contenedor Node.js y correr los feature files.

```bash
# Correr tests cucumber
docker compose run --rm test


