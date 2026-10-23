# language: es
Característica: Eliminación de cuenta de usuario
  Como usuario registrado en Finza
  Quiero poder eliminar mi cuenta de forma segura ingresando mi contraseña actual
  Para asegurar que nadie más pueda borrar mi cuenta y revocar mis datos del sistema

  Antecedentes:
    Dado que el usuario "juan@example.com" con contraseña "Password123" se encuentra registrado en el sistema
    Y el usuario ha iniciado sesión y cuenta con un token de autenticación válido

  Escenario: Eliminación exitosa de cuenta con contraseña correcta
    Dado que el usuario se encuentra en la pantalla de configuración de su perfil
    Cuando solicita eliminar su cuenta ingresando su contraseña actual "Password123"
    Y confirma la acción de eliminación definitiva
    Entonces el sistema valida que la contraseña es correcta
    Y elimina la cuenta del usuario de la base de datos
    Y el sistema responde con un estado HTTP 200 y un mensaje de éxito
    Y la sesión del usuario queda invalidada

  Escenario: Intento fallido de eliminación con contraseña incorrecta
    Dado que el usuario se encuentra en la pantalla de configuración de su perfil
    Cuando solicita eliminar su cuenta ingresando una contraseña incorrecta "WrongPassword"
    Y confirma la acción de eliminación definitiva
    Entonces el sistema detecta que la contraseña no coincide con el registro
    Y la cuenta del usuario no es eliminada de la base de datos
    Y el sistema responde con un estado HTTP 400 y un mensaje de error de credenciales

  Escenario: Intento de eliminación sin autenticación previa
    Dado que un usuario no autenticado intenta enviar una solicitud de eliminación de cuenta
    Cuando envía la petición al endpoint de eliminación con la contraseña "Password123"
    Entonces el sistema rechaza la solicitud respondiendo con un estado HTTP 401 o 403
    Y la cuenta del usuario permanece activa en el sistema