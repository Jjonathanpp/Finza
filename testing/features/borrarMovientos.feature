# language: es
Característica: Eliminacion de movimientos
  Como usuario registrado en Finza
  Quiero eliminar un movimiento de mi cuenta
  Para mantener mi historial financiero actualizado

  Antecedentes:
    Dado que la API del backend está activa y lista para recibir peticiones
    Y que el usuario " Juan Perez " está registrado y autenticado

  Escenario: Eliminación exitosa de un movimiento existente
    Dado que existe un movimiento registrado con ID "12345" para el usuario autenticado
    Cuando envío una solicitud DELETE a "/api/movimientos/12345"
    Entonces la respuesta debe tener un código de estado 200
    Y la respuesta debe contener el mensaje "Movimiento eliminado exitosamente"
    Y el movimiento con ID "12345" ya no debe existir en la base de datos

  Escenario: Intento de eliminar un movimiento que no existe
    Dado que no existe un movimiento con ID "67890" para el usuario autenticado
    Cuando envío una solicitud DELETE a "/api/movimientos/67890"
    Entonces la respuesta debe tener un código de estado 404
    Y la respuesta debe contener el mensaje de error "Movimiento no encontrado"
