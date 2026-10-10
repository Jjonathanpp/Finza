Característica: Resumen del panel financiero (Balance y Scoping)
  Como usuario del sistema Finza
  Quiero ver un resumen preciso de mi balance mensual
  Para conocer mi estado financiero, aislar mis datos y solo contabilizar plata real

  Antecedentes:
    Dado que el sistema está corriendo

  Escenario: La matemática maneja decimales y aísla datos de otros usuarios
    Cuando la "Cuenta 1" solicita su resumen financiero
    Y guardamos sus totales actuales en memoria
    # Cargamos montos con decimales para probar la precisión de BigDecimal
    Y que la "Cuenta 1" registra un "ingreso" de "5000.75" para el balance
    Y que la "Cuenta 1" registra un "egreso" de "1500.50" para el balance
    Y que la "Cuenta 2" registra un "ingreso" de "99999.99" para el balance
    Cuando la "Cuenta 1" solicita su resumen financiero nuevamente
    Entonces la respuesta debe tener código de estado 200
    Y sus ingresos deben haber aumentado en "5000.75"
    Y sus egresos deben haber aumentado en "1500.50"
    Y su saldo debe haber aumentado en "3500.25"

  Escenario: El balance ignora movimientos fuera del rango actual
    Cuando la "Cuenta 1" solicita su resumen financiero
    Y guardamos sus totales actuales en memoria
    # Este movimiento es de 2022, el mes actual (Octubre 2026) no debería verlo
    Y que la "Cuenta 1" registra un "ingreso" de "50000.00" con fecha "15-05-2022" y estado "APROBADO"
    # Este sí es del mes en curso
    Y que la "Cuenta 1" registra un "ingreso" de "1000.00" con fecha "hoy" y estado "APROBADO"
    Cuando la "Cuenta 1" solicita su resumen financiero nuevamente
    Entonces sus ingresos deben haber aumentado en "1000.00"
    Y su saldo debe haber aumentado en "1000.00"

  Escenario: El balance ignora movimientos que no están aprobados
    Cuando la "Cuenta 1" solicita su resumen financiero
    Y guardamos sus totales actuales en memoria
    # Un cheque pendiente o un audio procesando no es plata en el bolsillo
    Y que la "Cuenta 1" registra un "ingreso" de "8000.00" con fecha "hoy" y estado "PENDIENTE"
    Y que la "Cuenta 1" registra un "egreso" de "2000.00" con fecha "hoy" y estado "ERROR_IA"
    # Sumamos uno real para que haya diferencia
    Y que la "Cuenta 1" registra un "ingreso" de "500.00" con fecha "hoy" y estado "APROBADO"
    Cuando la "Cuenta 1" solicita su resumen financiero nuevamente
    Entonces sus ingresos deben haber aumentado en "500.00"
    Y sus egresos deben haber aumentado en "0.00"
    Y su saldo debe haber aumentado en "500.00"