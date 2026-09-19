# language: es
Característica: Edición y eliminación de categorías
  Como usuario de Finza
  Quiero editar y eliminar mis categorías personalizadas
  Para mantener mi organización financiera actualizada y limpia

  Antecedentes:
    Dado que tengo una cuenta nueva para probar categorías

  Escenario: Edición exitosa de una categoría propia
    Dado que ya creé la categoría "Tecnología" de tipo "EGRESO"
    Cuando envío una solicitud PUT para actualizar la categoría con los siguientes datos:
      | nombre | Electrónica |
      | color  | #EF4444     |
    Entonces la categoría se responde con código 200
    Y el mensaje de la respuesta es "Categoría actualizada correctamente"
    Y la categoría actualizada tiene el nombre "Electrónica" y color "#EF4444"

  Escenario: Eliminación exitosa de una categoría sin movimientos
    Dado que ya creé la categoría "Viajes de trabajo" de tipo "EGRESO"
    Cuando envío una solicitud DELETE para eliminar esa categoría
    Entonces la categoría se responde con código 200
    Y el mensaje de la respuesta es "Categoría eliminada correctamente"

 Escenario: No se puede eliminar una categoría si tiene movimientos asociados
    Dado que ya creé la categoría "Inversiones Unicas" de tipo "INGRESO"
    Y la categoría tiene un movimiento registrado asociado
    Cuando envío una solicitud DELETE para eliminar esa categoría
    Entonces la categoría se responde con código 500
    Y la respuesta debe contener el mensaje de error de movimientos asociados