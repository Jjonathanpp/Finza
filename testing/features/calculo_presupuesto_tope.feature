# language: es
Característica: Cálculo de acumulado mensual contra el tope presupuestado
  Como usuario de Finza
  Quiero consultar el acumulado de mis gastos frente al tope establecido
  Para controlar si estoy por debajo, en el límite o si superé el presupuesto

  Antecedentes:
    Dado que tengo una cuenta nueva autenticada para probar presupuestos
    Y que tengo creadas las categorías de egreso "Comida", "Transporte" y "Salidas"
    Y tengo configurados los siguientes presupuestos para el mes 10 del año 2026:
      | categoria  | montoTope | mes | anio |
      | Comida     | 10000.00  | 10  | 2026 |
      | Transporte | 5000.00   | 10  | 2026 |
      | Salidas    | 4000.00   | 10  | 2026 |

  Escenario: Gastos por debajo del tope fijado
    Dado que registro los siguientes movimientos en el mes 10 del año 2026:
      | tipo   | monto   | categoria | descripcion | fecha      |
      | egreso | 6000.00 | Comida    | Supermercado| 10-10-2026 |
    Cuando consulto los presupuestos del mes 10 del año 2026
    Entonces la respuesta debe tener un codigo de estado 200
    Y para la categoría "Comida" el monto gastado debe ser 6000.00
    Y para la categoría "Comida" el porcentaje consumido debe ser 60.0

  Escenario: Gastos que alcanzan exactamente el límite del presupuesto
    Dado que registro los siguientes movimientos en el mes 10 del año 2026:
      | tipo   | monto   | categoria  | descripcion  | fecha      |
      | egreso | 3000.00 | Transporte | Combustible  | 05-10-2026 |
      | egreso | 2000.00 | Transporte | Mantenimiento| 15-10-2026 |
    Cuando consulto los presupuestos del mes 10 del año 2026
    Entonces la respuesta debe tener un codigo de estado 200
    Y para la categoría "Transporte" el monto gastado debe ser 5000.00
    Y para la categoría "Transporte" el porcentaje consumido debe ser 100.0

  Escenario: Gastos que superan el presupuesto asignado
    Dado que registro los siguientes movimientos en el mes 10 del año 2026:
      | tipo   | monto   | categoria | descripcion | fecha      |
      | egreso | 6000.00 | Salidas   | Concierto   | 20-10-2026 |
    Cuando consulto los presupuestos del mes 10 del año 2026
    Entonces la respuesta debe tener un codigo de estado 200
    Y para la categoría "Salidas" el monto gastado debe ser 6000.00
    Y para la categoría "Salidas" el porcentaje consumido debe ser 150.0