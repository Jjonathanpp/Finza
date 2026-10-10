# language: es
Característica: Listas de movimientos recientes en el Panel
  Como usuario del sistema Finza
  Quiero que mi resumen incluya mis últimos movimientos categorizados
  Para tener un vistazo rápido sin recargar toda la base de datos

  Antecedentes:
    Dado que el sistema está corriendo

  Escenario: El panel devuelve las listas separadas respetando el límite por defecto
    # Generamos un volumen de datos mayor al límite (que es 5)
    Dado que la "Cuenta 1" genera "6" registros de "ingreso" en lote
    Y que la "Cuenta 1" genera "6" registros de "egreso" en lote
    Cuando la "Cuenta 1" solicita su resumen financiero
    Entonces la lista de "ultimosMovimientos" debe tener como máximo "5" elementos
    Y la lista de "ultimosIngresos" debe tener como máximo "5" elementos
    Y la lista de "ultimosEgresos" debe tener como máximo "5" elementos
    Y todos los elementos de "ultimosIngresos" deben tener esIngreso en "true"
    Y todos los elementos de "ultimosEgresos" deben tener esIngreso en "false"