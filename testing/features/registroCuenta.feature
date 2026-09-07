# language: es
Característica: Registro de cuenta de usuario
  Como usuario nuevo de Finza
  Quiero registrarme ingresando mis datos personales
  Para crear una cuenta e ingresar a la plataforma

  Antecedentes:
    Dado que la API del backend está activa y lista para recibir peticiones

  Escenario: Registro exitoso de un nuevo usuario
    Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   | Juan Perez          |
      | email    | juan.perez@test.com |
      | password | Password123!        |
    Entonces la respuesta debe tener un código de estado 201
    Y la respuesta debe contener un token de autenticación
    Y el usuario debe quedar registrado en la base de datos

  Escenario: Intentar registrar un usuario con un email ya existente
    Dado que existe un usuario registrado con el email "usuario.existente@test.com"
    Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   | Carlos Gomez               |
      | email    | usuario.existente@test.com |
      | password | Password123!               |
    Entonces la respuesta debe tener un código de estado 400
    Y la respuesta debe contener el mensaje de error "El correo electrónico ya está en uso"

  Escenario: Intentar registrarse dejando campos obligatorios vacíos
    Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   |                      |
      | email    | pedro.gomez@test.com |
      | password |                      |
    Entonces la respuesta debe tener un código de estado 400
    Y la respuesta debe indicar los campos faltantes requeridos

  Escenario: Intento registrarme con una contraseña débil
    Cuando envío una solicitud POST a "/api/auth/registro" con los siguientes datos:
      | nombre   | Ana Martinez          |
      | email    | ana.martinez@test.com |
      | password |                  1234 |
    Entonces la respuesta debe tener un código de estado 400
    Y la respuesta debe contener el mensaje de error "La contraseña no cumple con los requisitos de seguridad"
