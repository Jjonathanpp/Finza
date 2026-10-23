# language: es
Característica: Cálculo porcentual de gastos por categoría (casos borde)
  Como usuario de Finza
  Quiero que el cálculo del porcentaje consumido sea preciso
  Para confiar en los valores mostrados en los presupuestos

  Antecedentes:
    Dado que tengo una cuenta nueva autenticada para probar presupuestos
    Y que tengo creadas las categorías de egreso "Comida", "Transporte" y "Salidas"
    Y tengo configurados los siguientes presupuestos para el mes 11 del año 2026:
      | categoria  | montoTope | mes | anio |
      | Comida     | 10000.00  | 11  | 2026 |
      | Transporte | 5000.00   | 11  | 2026 |
      | Salidas    | 4000.00   | 11  | 2026 |

  Escenario: Mes sin movimientos devuelve porcentaje cero
    Cuando consulto los presupuestos del mes 11 del año 2026
    Entonces la respuesta del cálculo debe tener codigo de estado 200
    Y para la categoría "Comida" el monto gastado del cálculo debe ser 0.00
    Y para la categoría "Comida" el porcentaje consumido del cálculo debe ser 0.0
    Y para la categoría "Comida" el estado del cálculo debe ser "OK"

  Escenario: Distribución entre varias categorías y total del período
    Dado que registro los siguientes movimientos en el mes 11 del año 2026:
      | tipo   | monto   | categoria  | descripcion | fecha      |
      | egreso | 2000.00 | Comida     | Super       | 02-11-2026 |
      | egreso | 1000.00 | Transporte | Nafta       | 08-11-2026 |
      | egreso | 500.00  | Salidas    | Cine        | 12-11-2026 |
    Cuando consulto los presupuestos del mes 11 del año 2026
    Entonces la respuesta del cálculo debe tener codigo de estado 200
    Y para la categoría "Comida" el monto gastado del cálculo debe ser 2000.00
    Y para la categoría "Comida" el porcentaje consumido del cálculo debe ser 20.0
    Y para la categoría "Transporte" el monto gastado del cálculo debe ser 1000.00
    Y para la categoría "Transporte" el porcentaje consumido del cálculo debe ser 20.0
    Y para la categoría "Salidas" el monto gastado del cálculo debe ser 500.00
    Y para la categoría "Salidas" el porcentaje consumido del cálculo debe ser 12.5