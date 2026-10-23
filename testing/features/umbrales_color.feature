# language: es
Característica: Umbrales de color del presupuesto (estados)
  Como usuario de Finza
  Quiero que el backend categorice el consumo según umbrales
  Para que la barra de progreso muestre el color correcto

  Antecedentes:
    Dado que tengo una cuenta nueva autenticada para probar presupuestos
    Y que tengo creadas las categorías de egreso "Comida", "Transporte" y "Salidas"
    Y tengo configurados los siguientes presupuestos para el mes 12 del año 2026:
      | categoria | montoTope | mes | anio |
      | Comida    | 10000.00  | 12  | 2026 |

  Escenario: Consumo normal (menos del 80 por ciento)
    Dado que registro los siguientes movimientos en el mes 12 del año 2026:
      | tipo   | monto   | categoria | descripcion | fecha      |
      | egreso | 5000.00 | Comida    | Super       | 05-12-2026 |
    Cuando consulto los presupuestos del mes 12 del año 2026
    Entonces el estado del umbral debe ser "OK"
    Y el porcentaje del umbral debe ser 50.0

  Escenario: Consumo cerca del tope (entre 80 y 99 por ciento)
    Dado que registro los siguientes movimientos en el mes 12 del año 2026:
      | tipo   | monto   | categoria | descripcion | fecha      |
      | egreso | 8500.00 | Comida    | Super       | 05-12-2026 |
    Cuando consulto los presupuestos del mes 12 del año 2026
    Entonces el estado del umbral debe ser "ALERTA"
    Y el porcentaje del umbral debe ser 85.0

  Escenario: Consumo superado (100 por ciento o más)
    Dado que registro los siguientes movimientos en el mes 12 del año 2026:
      | tipo   | monto    | categoria | descripcion | fecha      |
      | egreso | 12000.00 | Comida    | Super       | 05-12-2026 |
    Cuando consulto los presupuestos del mes 12 del año 2026
    Entonces el estado del umbral debe ser "EXCEDIDO"
    Y el porcentaje del umbral debe ser 120.0