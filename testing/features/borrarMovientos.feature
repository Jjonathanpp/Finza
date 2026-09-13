# language: es
Característica: Eliminacion de movimientos
  Como usuario registrado en Finza
  Quiero eliminar un movimiento de mi cuenta
  Para mantener mi historial financiero actualizado

  Antecedentes:
    Dado que la API del backend esta activa y lista para recibir peticiones
    Y que el usuario " Juan Perez " esta registrado y autenticado

  Escenario: Eliminacion exitosa de un movimiento
    Dado que el usuario autenticado tiene un movimiento registrado con los siguientes datos:
      | tipo  | monto    | categoria | descripcion      | fecha      |
      | gasto | 15000.00 | Comida    | Almuerzo laboral | 10-05-2026 |
    Cuando envio una solicitud DELETE a "/api/movimientos" para ese movimiento
    Entonces la respuesta debe tener un codigo de estado 200
    Y la respuesta debe contener el mensaje "Movimiento eliminado exitosamente"

  Escenario: Intento de eliminar un movimiento que no existe
    Dado que el usuario autenticado intenta eliminar un movimiento inexistente
    Cuando envio una solicitud DELETE a "/api/movimientos/999999"
    Entonces la respuesta debe tener un codigo de estado 404
    Y la respuesta debe contener el mensaje "Movimiento no encontrado"
