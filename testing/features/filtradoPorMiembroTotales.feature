# language: es
Característica: Filtrado por miembro y recálculo de totales y balances
  Como usuario de una cuenta compartida
  Quiero filtrar los movimientos por integrante
  Para visualizar únicamente sus movimientos y comprobar que los totales se recalculan correctamente

  Antecedentes:
    Dado que el sistema está corriendo

  Escenario: Filtrar movimientos por miembro y validar totales y balances
    Dado que existe una cuenta compartida con dos integrantes
    Y que el integrante "A" registra movimientos de ingreso y egreso
    Y que el integrante "B" registra movimientos de ingreso y egreso
    Cuando solicito el listado de movimientos filtrando por el integrante "A"
    Entonces la respuesta debe tener código de estado 200
    Y solo deben aparecer movimientos del integrante "A"
    Y los totales y balances calculados deben ser correctos para el integrante "A"