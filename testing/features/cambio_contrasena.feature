# language: es

Característica: como usuario quiero cambiar mi contraseña para mantener la seguridad de mi cuenta

  Escenario: Cambio de contraseña exitoso
    Dado que hay un usuario registrado y autenticado con la contraseña "contraseña_vieja"
    Cuando envío una petición POST a "/api/auth/cambio-contrasena" con el body:
      """
      {
        "contraseña_actual": "contraseña_vieja",
        "nueva_contraseña": "contraseña_nueva"
      }
      """
    Entonces recibo una respuesta con código 200
    Y el body tiene los campos status, message y data
    Y el campo status es 200
    Y el mensaje indica que la contraseña ha sido cambiada exitosamente
    Y puedo iniciar sesión con la contraseña "contraseña_nueva"
    Y no puedo iniciar sesión con la contraseña "contraseña_vieja"

  Escenario: Cambio de contraseña fallido por contraseña actual incorrecta
    Dado que hay un usuario registrado y autenticado con la contraseña "contraseña_vieja"
    Cuando envío una petición POST a "/api/auth/cambio-contrasena" con el body:
      """
      {
        "contraseña_actual": "contraseña_incorrecta",
        "nueva_contraseña": "contraseña_nueva"
      }
      """
    Entonces recibo una respuesta con código 400
    Y el body tiene los campos status, message y data
    Y el campo status es 400
    Y el mensaje indica que la contraseña actual es incorrecta
    Y puedo iniciar sesión con la contraseña "contraseña_vieja"

  Escenario: Cambio de contraseña fallido por nueva contraseña demasiado corta
    Dado que hay un usuario registrado y autenticado con la contraseña "contraseña_vieja"
    Cuando envío una petición POST a "/api/auth/cambio-contrasena" con el body:
      """
      {
        "contraseña_actual": "contraseña_vieja",
        "nueva_contraseña": "corta"
      }
      """
    Entonces recibo una respuesta con código 400
    Y el body tiene los campos status, message y data
    Y el campo status es 400
    Y el detalle indica que la contraseña debe tener al menos 8 caracteres