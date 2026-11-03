# language: es

Característica: Aceptar invitación de cuenta compartida

  Escenario: Usuario registrado acepta invitación válida y se asocia a la cuenta compartida
    Dado existe un usuario registrado con email único para invitación
    Y existe una cuenta compartida llamada "Casa invitacion"
    Y existe una invitación pendiente para el email del usuario en la cuenta compartida "Casa invitacion"
    Cuando el usuario acepta la invitación enviando su token en el body
    Entonces recibo una respuesta de invitación con código 200
    Y el usuario es miembro de la cuenta compartida "Casa invitacion"

  Escenario: Token inválido no asocia al usuario
    Cuando envío una petición POST a "/api/cuentas-compartidas/invitaciones/aceptar" con token "token_invalido"
    Entonces recibo una respuesta de invitación con código 401