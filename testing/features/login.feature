# language: es

Característica: Login
  Como usuario
  Quiero iniciar sesión en la aplicación
  Para poder acceder a mis datos

  Antecedentes:
    Dado existe un usuario con email "PruebaLogin@ejemplo.com" y contraseña "123456789"

  Escenario: Inicio de sesión exitoso
    Cuando envío una petición POST a "/api/auth/login" con email "PruebaLogin@ejemplo.com" y contraseña "123456789"
    Entonces recibo una respuesta con código 200

  Escenario: Inicio de sesión fallido por credenciales incorrectas
    Cuando envío una petición POST a "/api/auth/login" con email "PruebaLogin@ejemplo.com" y contraseña "wrongpassword"
    Entonces recibo una respuesta con código 401