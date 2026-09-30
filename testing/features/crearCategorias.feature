# language: es
Característica: Creación de categorías
  Como usuario registrado en Finza
  Quiero crear categorías propias de ingreso y egreso
  Para organizar mis movimientos a mi manera

  Antecedentes:
    Dado que tengo una cuenta nueva para probar categorías

  Escenario: Creación exitosa de una categoría
    Cuando creo una categoría con los siguientes datos:
      | nombre | Viajes  |
      | tipo   | EGRESO  |
      | color  | #3B82F6 |
    Entonces la categoría se responde con código 201
    Y el mensaje de la respuesta es "Categoría creada correctamente"
    Y la categoría creada es "Viajes" de tipo "EGRESO"

  Escenario: No se puede repetir el nombre dentro del mismo tipo
    Dado que ya creé la categoría "Viajes" de tipo "EGRESO"
    Cuando creo una categoría con los siguientes datos:
      | nombre | viajes |
      | tipo   | EGRESO |
    Entonces la categoría se responde con código 409
    Y el mensaje de la respuesta es "Ya existe una categoría con ese nombre para el tipo indicado"

  Escenario: No se puede repetir una categoría global del mismo tipo
    Cuando creo una categoría con los siguientes datos:
      | nombre | Comida |
      | tipo   | EGRESO |
    Entonces la categoría se responde con código 409

  Escenario: Se puede usar el nombre de una global si el tipo es distinto
    Cuando creo una categoría con los siguientes datos:
      | nombre | Alquiler |
      | tipo   | EGRESO   |
    Entonces la categoría se responde con código 201
    Y la categoría creada es "Alquiler" de tipo "EGRESO"

  Esquema del escenario: Creación fallida por datos incompletos
    Cuando creo una categoría con los siguientes datos:
      | nombre | <nombre> |
      | tipo   | <tipo>   |
    Entonces la categoría se responde con código 400
    Y el campo "<campo>" informa "<mensaje>"

    Ejemplos:
      | nombre | tipo   | campo  | mensaje                  |
      |        | EGRESO | nombre | El nombre es obligatorio |
      | Viajes |        | tipo   | El tipo es obligatorio   |

  Escenario: Creación fallida por cuenta inexistente
    Cuando creo una categoría en la cuenta 999999 con los siguientes datos:
      | nombre | Viajes |
      | tipo   | EGRESO |
    Entonces la categoría se responde con código 400
    Y el mensaje de la respuesta es "La cuenta indicada no existe"
