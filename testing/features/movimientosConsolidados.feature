# language: es
Característica: Listado consolidado de movimientos de la cuenta
  Como usuario de Finza con un perfil personal y perfiles en cuentas compartidas
  Quiero ver en un solo listado los movimientos de todos mis perfiles
  Para tener una visión completa de mis finanzas

  Antecedentes:
    Dado que tengo una cuenta nueva para probar el consolidado
    Y que creé la cuenta compartida "Gastos de la casa"

  Escenario: Incluye los movimientos de todos mis perfiles indicando de dónde es cada uno
    Dado que registré en mi perfil personal los movimientos:
      | tipo   | monto | categoria | descripcion | fecha      |
      | egreso | 1500  | Comida    | Almuerzo    | 03-11-2026 |
    Y que registré en la cuenta compartida "Gastos de la casa" los movimientos:
      | tipo   | monto | categoria | descripcion  | fecha      |
      | egreso | 32000 | Comida    | Supermercado | 04-11-2026 |
    Cuando consulto mis movimientos consolidados
    Entonces el consolidado responde con código 200
    Y el mensaje del consolidado es "Movimientos consolidados obtenidos"
    Y el consolidado tiene en total 2 movimientos
    Y el movimiento "Almuerzo" figura como del perfil personal
    Y el movimiento "Supermercado" figura como de la cuenta compartida "Gastos de la casa"

  Escenario: No incluye movimientos de otras cuentas aunque se pida otra cuenta por URL
    Dado que registré en mi perfil personal los movimientos:
      | tipo   | monto | categoria | descripcion | fecha      |
      | egreso | 1500  | Comida    | Almuerzo    | 03-11-2026 |
    Y que otro usuario registró el movimiento "Gasto ajeno" en su perfil personal
    Cuando consulto mis movimientos consolidados indicando la cuenta del otro usuario en la URL
    Entonces el consolidado responde con código 200
    Y el consolidado tiene en total 1 movimiento
    Y el movimiento "Gasto ajeno" no figura en el consolidado

  Escenario: El perfil activo no cambia el resultado
    Dado que registré en mi perfil personal los movimientos:
      | tipo   | monto | categoria | descripcion | fecha      |
      | egreso | 1500  | Comida    | Almuerzo    | 03-11-2026 |
    Y que registré en la cuenta compartida "Gastos de la casa" los movimientos:
      | tipo   | monto | categoria | descripcion  | fecha      |
      | egreso | 32000 | Comida    | Supermercado | 04-11-2026 |
    Cuando consulto mis movimientos consolidados parado en la cuenta compartida "Gastos de la casa"
    Entonces el consolidado responde con código 200
    Y el consolidado tiene en total 2 movimientos

  Escenario: Ordena del más nuevo al más viejo e ignora otro orden pedido por URL
    Dado que registré en mi perfil personal los movimientos:
      | tipo   | monto | categoria | descripcion | fecha      |
      | egreso | 100   | Comida    | Viejo       | 01-11-2026 |
      | egreso | 200   | Comida    | Mismo dia A | 05-11-2026 |
    Y que registré en la cuenta compartida "Gastos de la casa" los movimientos:
      | tipo   | monto | categoria | descripcion | fecha      |
      | egreso | 300   | Comida    | Mismo dia B | 05-11-2026 |
    Cuando consulto mis movimientos consolidados con "sort=monto,asc"
    Entonces el consolidado responde con código 200
    Y los movimientos vienen en este orden:
      | Mismo dia B |
      | Mismo dia A |
      | Viejo       |

  Escenario: Pagina los resultados
    Dado que registré en mi perfil personal los movimientos:
      | tipo   | monto | categoria | descripcion | fecha      |
      | egreso | 100   | Comida    | Uno         | 01-11-2026 |
      | egreso | 200   | Comida    | Dos         | 02-11-2026 |
      | egreso | 300   | Comida    | Tres        | 03-11-2026 |
    Cuando consulto mis movimientos consolidados con "page=0&size=2"
    Entonces el consolidado responde con código 200
    Y la página trae 2 movimientos
    Y el consolidado tiene en total 3 movimientos en 2 páginas
    Cuando consulto mis movimientos consolidados con "page=1&size=2"
    Entonces la página trae 1 movimiento
    Y los movimientos vienen en este orden:
      | Uno |

  Esquema del escenario: Aplica los filtros sobre todos los perfiles
    Dado que registré en mi perfil personal los movimientos:
      | tipo    | monto  | categoria | descripcion | fecha      |
      | ingreso | 900000 | Sueldo    | Sueldo      | 01-11-2026 |
      | egreso  | 1500   | Comida    | Almuerzo    | 03-11-2026 |
    Y que registré en la cuenta compartida "Gastos de la casa" los movimientos:
      | tipo   | monto | categoria | descripcion  | fecha      |
      | egreso | 32000 | Comida    | Supermercado | 04-11-2026 |
    Cuando consulto mis movimientos consolidados con "<filtros>"
    Entonces el consolidado responde con código 200
    Y el consolidado tiene en total <cantidad> movimientos

    Ejemplos:
      | filtros                                   | cantidad |
      | esIngreso=true                            | 1        |
      | esIngreso=false                           | 2        |
      | fechaInicio=2026-11-04                    | 1        |
      | fechaInicio=2026-11-02&fechaFin=2026-11-03 | 1        |
      | estado=APROBADO                           | 3        |
      | estado=PENDIENTE                          | 0        |

  Esquema del escenario: Rechaza filtros inválidos
    Cuando consulto mis movimientos consolidados con "<filtros>"
    Entonces el consolidado responde con código 400
    Y el mensaje del consolidado es "<mensaje>"

    Ejemplos:
      | filtros                                   | mensaje                                                      |
      | fechaInicio=2026-11-10&fechaFin=2026-11-01 | La fecha de inicio no puede ser posterior a la fecha de fin |
      | estado=INVENTADO                          | Estado inválido: INVENTADO                                   |

  Escenario: Sin token no se puede consultar
    Cuando consulto los movimientos consolidados sin token
    Entonces el consolidado responde con código 401
