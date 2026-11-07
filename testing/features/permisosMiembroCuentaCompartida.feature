# language: es
Característica: Acciones de administrador restringidas para miembros de una cuenta compartida
  Como administrador de una cuenta compartida en Finza
  Quiero que los integrantes con rol MIEMBRO no puedan ejecutar acciones administrativas
  Para que solo el administrador controle quién entra y qué rol tiene cada uno

  Antecedentes:
    Dado que "admin" creó la cuenta compartida "Gastos de la casa"
    Y que "miembro" se unió a la cuenta compartida aceptando una invitación
    Y que "otro" se unió a la cuenta compartida aceptando una invitación
    Y que "externo" tiene una cuenta pero no pertenece a la cuenta compartida

  Escenario: Un miembro no puede invitar a otra persona
    Cuando "miembro" invita a "externo" a la cuenta compartida
    Entonces la acción se rechaza con código 403
    Y "externo" no tiene invitaciones pendientes en la cuenta compartida

  Escenario: Un miembro no puede ver las invitaciones de la cuenta compartida
    Cuando "miembro" consulta las invitaciones de la cuenta compartida
    Entonces la acción se rechaza con código 403

  Escenario: Un miembro no puede ascender a otro integrante a administrador
    Cuando "miembro" cambia el rol de "otro" a "ADMIN"
    Entonces la acción se rechaza con código 403
    Y el rol de "otro" en la cuenta compartida es "MIEMBRO"

  Escenario: Un miembro no puede quitarle el rol al administrador
    Cuando "miembro" cambia el rol de "admin" a "MIEMBRO"
    Entonces la acción se rechaza con código 403
    Y el rol de "admin" en la cuenta compartida es "ADMIN"

  Escenario: Un miembro no puede ascenderse a sí mismo
    Cuando "miembro" cambia el rol de "miembro" a "ADMIN"
    Entonces la acción se rechaza con código 403
    Y el rol de "miembro" en la cuenta compartida es "MIEMBRO"

  # Controles: las mismas acciones con el administrador sí funcionan,
  # así el 403 de arriba se debe al rol y no a un endpoint roto.

  Escenario: El administrador sí puede ver las invitaciones
    Cuando "admin" consulta las invitaciones de la cuenta compartida
    Entonces la acción se responde con código 200

  Escenario: El administrador sí puede cambiar el rol de un miembro
    Cuando "admin" cambia el rol de "otro" a "ADMIN"
    Entonces la acción se responde con código 200
    Y el rol de "otro" en la cuenta compartida es "ADMIN"
