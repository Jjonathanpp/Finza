# Finza - Frontend (Flutter)

Proyecto Flutter para Finza. La estructura base está lista para arrancar con funcionalidades.

## Requisitos

- Flutter 3.x con Dart 3.x
- El backend corriendo (Spring Boot en Docker) para consumir la API

## Arrancar el proyecto

```bash
flutter pub get
flutter run -d chrome
```

El backend está en `http://localhost:8080` cuando se levanta con Docker. Esa dirección se usa como base para las llamadas a la API.

## Getting Started

Recursos:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

Para ayuda con el desarrollo en general, la [documentación online de Flutter](https://docs.flutter.dev/) incluye tutoriales, muestras y guía para apps móviles y API de referencia.

---

## Estructura de archivos

El código fuente vive en `lib/`. Cada carpeta tiene un `.gitkeep` para que git la conserve aunque todavía no tenga archivos.

```
lib/
├── main.dart
├── app.dart
│
├── config/
│   ├── theme/
│   ├── routes/
│   └── constants/
│
├── core/
│   ├── network/
│   ├── errors/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   └── auth/
│       ├── data/
│       │   ├── models/
│       │   ├── datasources/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── bloc/
│           ├── screens/
│           ├── widgets/
│           └── pages/
│
├── shared/
│   ├── widgets/
│   └── utils/
│
└── tests/
    ├── mocks/
    └── helpers/
```

Cada feature sigue esta misma indentación: `data/`, `domain/`, `presentation/` y sus subcarpetas. Para crear una feature nueva, se copia esa estructura como subcarpeta dentro de `features/`.

### Archivos raíz

`main.dart` es el entry point: inicializa servicios (dotenv, base de datos, inyección de dependencias) y lanza la app con `runApp()`. `app.dart` define el `MaterialApp` con tema, rutas y pantalla inicial. Se separan para que `main.dart` no tenga lógica de UI y para poder testear la app con configuraciones distintas.

### `config/` — Configuración global

Cosas que afectan a toda la app y no dependen de ninguna feature en particular.

`config/theme/` centraliza colores, tipografías y el tema de Material (light/dark). Si cambia un color, se cambia acá y se refleja en todos lados. `config/routes/` define toda la navegación en un solo archivo, evitando `Navigator.push(...)` esparcidos por el código. `config/constants/` tiene la URL base de la API, tiempos de timeout y demás valores fijos.

### `core/` — Infraestructura técnica compartida

Cosas técnicas que todas las features usan pero que no son de negocio. Esta carpeta no debería depender de ninguna feature.

`core/network/` tiene el cliente HTTP (Dio), interceptors para el token JWT y constantes de endpoints. Todas las features van a necesitar hacer llamadas a la API, así que el cliente se centraliza acá y no se duplica. `core/errors/` tiene clases base de error (`Failure`, `Exception`) para manejar fallos de forma uniforme en toda la app. `core/storage/` accede a SharedPreferences o cualquier almacenamiento local, útil para guardar el token de sesión u otros datos persistentes. `core/utils/` tiene funciones genéricas que varias features van a usar: formateo de fechas, validadores, helpers. `core/widgets/` tiene widgets reutilizables de infraestructura visual: loading spinner, error message, empty state. No van en `shared/` porque son componentes de UI genéricos, no de negocio.

### `features/` — Módulos de funcionalidad

Cada feature es un módulo autocontenido. Una feature nueva se crea como subcarpeta dentro de `features/`, con todo lo que necesita para funcionar sin depender de otras features (salvo lo que esté en `core/` o `shared/`).

Dentro de cada feature hay tres capas:

#### `features/<nombre>/data/` — Capa de datos

Se comunica con las fuentes de datos (API, base de datos local). No tiene lógica de negocio, solo sabe cómo obtener y guardar datos.

`data/models/` tiene los modelos que mapean el JSON de la API. Ej: `UserModel` con `fromJson()` y `toJson()`. Viven en data porque son parte de la comunicación con los datos, no de la lógica de negocio. `data/datasources/` tiene las clases que hacen las llamadas HTTP o leen la base de datos local. Ej: `AuthRemoteDatasource` con métodos como `login()` que hacen `dio.post(...)`. Separa el "cómo obtengo los datos" de "qué hago con ellos". `data/repositories/` implementa las interfaces que definieron en `domain/`. Ej: para el login, se llama a RemoteDatasource, y si falla se devuelve un error.

#### `features/<nombre>/domain/` — Capa de negocio

La capa pura de reglas. No sabe de dónde vienen los datos ni cómo se muestra la UI.

`domain/entities/` tiene entidades puras: objetos de negocio sin dependencias de JSON ni HTTP. Ej: `User` con `id`, `name`, `email`. Sin `fromJson()` ni nada técnico. `domain/repositories/` tiene interfaces (abstract classes) que definen qué operaciones existen. Ej: `AuthRepository` define `login()`, `register()`, `logout()`. La capa domain no sabe cómo se implementa, solo dice qué necesita. `domain/usecases/` tiene casos de uso, uno por cada acción concreta de negocio. Ej: `LoginUseCase` recibe email y contraseña, llama al repository. Facilita testear la lógica por separado.

#### `features/<nombre>/presentation/` — Capa de presentación

La interfaz de usuario: pantallas, widgets y su lógica de estado.

`presentation/bloc/` tiene el BLoC (o Cubit) que maneja el estado de la pantalla. Recibe eventos, ejecuta lógica, emite estados. Separa la lógica de UI de los widgets: un BLoC no sabe qué widget muestra, solo dice "estoy cargando" o "hubo un error". `presentation/screens/` tiene las pantallas completas: Scaffold con su contenido. Cada screen usa el BLoC para manejar el estado y los widgets para componer la UI. `presentation/widgets/` tiene widgets específicos de esta feature, no reutilizables. Ej: un card de usuario, un item de lista de transacciones. Si solo lo usa una feature, va acá. Si lo usa otra también, va a `shared/widgets/`. `presentation/pages/` son contenedores que agrupan screens, útiles cuando una pantalla tiene partes que se navegan internamente (tabs, stepper, etc.).

### `shared/` — Componentes compartidos entre features

Cosas que varias features usan y que no son de infraestructura (eso va en `core/`).

`shared/widgets/` tiene botones custom, inputs, cards que usa más de una feature. Ej: un `CustomButton` que se usa en login y también en registro. Si solo lo usa una feature, no va acá. `shared/utils/` tiene validadores, helpers, formatters que varias features necesitan. Ej: un validador de email que usan login y registro.

### `tests/` — Utilidades de testing

`tests/mocks/` tiene dobles de prueba (mocks, fakes, stubs). Cuando testeás un BLoC, necesitás un repository falso, y esos mocks van acá para reusarlos. `tests/helpers/` tiene funciones auxiliares para tests: crear instancias de prueba, configurar BLoCs. Ej: una función `createTestUser()` que devuelve un User con datos por defecto.

---

## Regla para decidir dónde poner algo

1. ¿Es infraestructura técnica (HTTP, errores, storage)? → `core/`
2. ¿Lo usa más de una feature? → `shared/`
3. ¿Lo usa solo una feature? → dentro de esa feature
4. ¿Es lógica de negocio pura (sin saber de dónde vienen los datos)? → `domain/`
5. ¿Es UI o manejo de estado de pantalla? → `presentation/`
6. ¿Es acceso a datos (API, BD local)? → `data/`
