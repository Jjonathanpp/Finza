# language: es
Característica: Aislamiento de datos en movimientos (Scoping por usuario)
  Como usuario del sistema Finza
  Quiero que mis datos financieros estén completamente aislados
  Para que ningún otro usuario pueda ver, alterar o borrar mis movimientos

  Antecedentes:
    Dado que el sistema está corriendo

  Escenario: Listar movimientos aísla correctamente los datos del usuario
    Dado que la "Cuenta 1" crea un movimiento de "ingreso"
    Y que la "Cuenta 2" crea un movimiento de "egreso"
    Cuando la "Cuenta 1" solicita su listado de movimientos
    Entonces la respuesta debe tener código de estado 200
    Y solo debe ver sus movimientos de tipo "ingreso"

  Escenario: Intento de eliminación de un movimiento de otra cuenta
    Dado que la "Cuenta 2" crea un movimiento de "egreso"
    Cuando la "Cuenta 1" intenta eliminar ese movimiento ajeno
    Entonces la respuesta debe tener código de estado 403
    Y el mensaje de la respuesta es "No tenés permiso para operar sobre este movimiento"

  Escenario: Intento de modificación de un movimiento de otra cuenta
    Dado que la "Cuenta 2" crea un movimiento de "egreso"
    Cuando la "Cuenta 1" intenta modificar ese movimiento ajeno con monto "9999"
    Entonces la respuesta debe tener código de estado 403
    Y el mensaje de la respuesta es "No tenés permiso para operar sobre este movimiento"