# language: es
Característica: Flujo de vida de movimientos pendientes
  Como usuario de Finza
  Quiero registrar movimientos pendientes y luego confirmarlos o descartarlos
  Para llevar un control preciso de transacciones no consolidadas

  Antecedentes:
    Dado que tengo un perfil nuevo para probar pendientes

  Escenario: Creación y listado de un movimiento pendiente
    Cuando registro un movimiento de tipo "egreso" por "10000" con estado "PENDIENTE"
    Entonces la respuesta HTTP es 201
    Y al consultar los movimientos con estado "PENDIENTE", el listado trae "1" resultados

  Escenario: Descarte (eliminación) de un movimiento pendiente
    Dado que tengo un movimiento pendiente registrado
    Cuando elimino ese movimiento
    Entonces la respuesta HTTP es 200
    Y al consultar los movimientos con estado "PENDIENTE", el listado trae "0" resultados

  Escenario: Confirmación de un movimiento pendiente a aprobado
    Dado que tengo un movimiento pendiente registrado
    Cuando confirmo el movimiento pasándolo a estado "APROBADO"
    Entonces la respuesta HTTP es 200
    Y al consultar los movimientos con estado "PENDIENTE", el listado trae "0" resultados
    Y al consultar los movimientos con estado "APROBADO", el listado trae "1" resultados