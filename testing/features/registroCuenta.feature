# language: es
Característica: Registro de cuenta de usuario
  Como usuario nuevo de Finza
  Quiero registrarme ingresando mis datos personales
  Para crear una cuenta e ingresar a la plataforma

Antecedentes:
Dado que la API del backend está activa y lista para recibir peticiones

Escenario: Registro exitoso de un nuevo usuario
Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   | Juan          |
      | apellido | Perez         |
      | dni      | 30111222      |
      | email    | juan.perez@test.com |
      | password | Password123!  |
Entonces la respuesta debe tener un código de estado 201

Escenario: Intentar registrar un usuario con un email ya existente
Dado que existe un usuario registrado con el email "usuario.existente@test.com"
Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   | Carlos                      |
      | apellido | Gomez                       |
      | dni      | 30222333                    |
      | email    | usuario.existente@test.com  |
      | password | Password123!                |
Entonces la respuesta debe tener un código de estado 409
Y la respuesta debe contener el mensaje de error "El email ya está registrado"

Escenario: Intentar registrarse dejando campos obligatorios vacíos
Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   |                      |
      | apellido | Gomez                |
      | dni      | 30333444             |
      | email    | pedro.gomez@test.com |
      | password |                      |
Entonces la respuesta debe tener un código de estado 400
Y la respuesta debe indicar los campos faltantes requeridos

Escenario: Intento registrarme con una contraseña corta
Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   | Ana                   |
      | apellido | Martinez              |
      | dni      | 30444555              |
      | email    | ana.martinez@test.com |
      | password | 1234                  |
Entonces la respuesta debe tener un código de estado 400
Y la respuesta debe contener el mensaje de error de campo "password" "La contraseña debe tener al menos 8 caracteres"