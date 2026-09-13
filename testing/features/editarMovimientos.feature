# language: es
Característica: Edición de movimientos
  Como usuario registrado en Finza
  Quiero modificar un movimiento existente en mi cuenta
  Para corregir errores o actualizar los detalles de mis transacciones

  Antecedentes:
    Dado que la API del backend esta activa y lista para recibir peticiones
    Y que el usuario " Juan Perez " esta registrado y autenticado

  Escenario: Modificación exitosa de un movimiento existente
    Dado que el usuario autenticado tiene un movimiento registrado con los siguientes datos:
      | tipo  | monto    | categoria | descripcion      | fecha      |
      | gasto | 15000.00 | Comida    | Almuerzo laboral | 10-05-2026 |
    Cuando envio una solicitud PUT a "/api/movimientos" para ese movimiento con los siguientes datos:
      | tipo  | monto    | categoria | descripcion          | fecha      |
      | gasto | 18500.00 | Comida    | Almuerzo de negocios | 10-05-2026 |
    Entonces la respuesta debe tener un codigo de estado 200
    Y la respuesta debe contener el mensaje "Movimiento actualizado exitosamente"
    Y el movimiento editado debe reflejar los nuevos datos en la base de datos

  Escenario: Modificación fallida por datos inválidos
    Dado que el usuario autenticado tiene un movimiento registrado con los siguientes datos:
      | tipo  | monto    | categoria | descripcion      | fecha      |
      | gasto | 15000.00 | Comida    | Almuerzo laboral | 10-05-2026 |
    Cuando envio una solicitud PUT a "/api/movimientos" para ese movimiento con los siguientes datos invalidos:
      | tipo  | monto     | categoria | descripcion | fecha      |
      | gasto | -20000.00 | Comida    | Invalido    | 10-05-2026 |
    Entonces la respuesta debe tener un codigo de estado 400
    Y la respuesta debe contener el mensaje "Error: Datos invalidos"

  Escenario: Intento de modificar un movimiento inexistente
    Cuando envio una solicitud PUT a "/api/movimientos/999999" con los siguientes datos:
      | tipo  | monto    | categoria | descripcion | fecha      |
      | gasto | 10000.00 | Servicios | Internet    | 12-05-2026 |
    Entonces la respuesta debe tener un codigo de estado 404
    Y la respuesta debe contener el mensaje "Movimiento no encontrado"

  Escenario: Intento de modificación sin autorización
    Dado que un usuario no autenticado intenta modificar un movimiento
    Cuando envio una solicitud PUT a "/api/movimientos/1" sin token de autenticacion con los siguientes datos:
      | tipo  | monto    | categoria | descripcion | fecha      |
      | gasto | 10000.00 | Servicios | Internet    | 12-05-2026 |
    Entonces la respuesta debe tener un codigo de estado 401
    Y la respuesta debe contener el mensaje "No autorizado"