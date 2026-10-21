# language: es
Característica: Reportes del Panel Financiero y Rango de Fechas
  Como usuario de Finza
  Quiero filtrar los informes de mi panel por un rango de fechas específico
  Para ver el consolidado de mis ingresos, egresos y gastos por categoría en ese período

  Antecedentes:
    Dado que tengo una cuenta nueva autenticada para probar los reportes
    Y existen los siguientes movimientos registrados en la cuenta:
      | tipo    | monto | categoria | descripcion | fecha      |
      | ingreso | 15000 | Sueldo    | Salario     | 08-07-2026 |
      | egreso  | 3000  | Comida    | Super       | 09-07-2026 |
      | egreso  | 2000  | Ropa      | Remera      | 10-07-2026 |
      | egreso  | 8000  | Comida    | Cena        | 05-08-2026 |

  Escenario: Resumen consolidado con rango de fechas válido
    Cuando solicito el resumen del panel con startDate "2026-07-01" y endDate "2026-07-31"
    Entonces la respuesta debe tener un codigo de estado 200
    Y el total de ingresos del período debe ser 15000
    Y el total de egresos del período debe ser 5000
    Y el saldo del período debe ser 10000

  Escenario: Incoherencia temporal en el rango de fechas
    Cuando solicito el resumen del panel con startDate "2026-07-31" y endDate "2026-07-01"
    Entonces la respuesta debe tener un codigo de estado 400
    Y la respuesta debe contener el error "La fecha de inicio (startDate) no puede ser posterior a la fecha de fin (endDate)"

  Escenario: Gastos agrupados por categoría filtrados por fecha exacta
    Cuando solicito los gastos por categoría con startDate "2026-07-01" y endDate "2026-07-31"
    Entonces la respuesta debe tener un codigo de estado 200
    Y la categoría "Comida" debe tener un gasto total de 3000
    Y la categoría "Ropa" debe tener un gasto total de 2000