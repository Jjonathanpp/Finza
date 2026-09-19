# language: es
Característica: Paginación y filtrado de movimientos financieros
  Como usuario de FinanzaApp
  Quiero poder listar mis movimientos con paginación y aplicar filtros
  Para poder analizar mis finanzas de forma ordenada y no sobrecargar el sistema

  Escenario: Listar movimientos con paginación por defecto
    Dado que el sistema está corriendo
    Cuando solicito el listado de movimientos sin filtros
    Entonces la respuesta debe tener código de estado 200
    Y la respuesta debe contener una lista paginada
    Y el tamaño de la página debe ser como máximo 20

  Escenario: Filtrar movimientos solo por ingresos
    Dado que el sistema está corriendo
    Cuando solicito el listado de movimientos con el filtro "esIngreso" en "true"
    Entonces la respuesta debe tener código de estado 200
    Y todos los movimientos devueltos deben tener el tipo "ingreso"

  Escenario: Filtrar movimientos por rango de fechas
    Dado que el sistema está corriendo
    Cuando solicito el listado de movimientos desde "2026-09-01" hasta "2026-09-30"
    Entonces la respuesta debe tener código de estado 200
    Y la fecha de los movimientos devueltos debe estar dentro de ese rango