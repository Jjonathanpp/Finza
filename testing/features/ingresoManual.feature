# language: es
  Característica: Registro de ingresos manualmente
  Como usuario Finza
  Quiero registrarme mis ingresos de manera manual
  Para llevar un control de mis finanzas personales

  Antecedentes:
    Dado que la API del backend esta activa y lista para recibir peticiones
    Y que el usuario " Juan Perez " esta registrado y autenticado

  Escenario: Registro exitoso de un ingreso manual
    Dado que el usuario autenticado desea registrar un ingreso manual
    Cuando envio una solicitud POST a "/api/movimientos" con los siguientes datos:
      | tipo    | monto     | categoria          | descripcion                        | fecha      |
      | ingreso | 600000.00 | Sueldo             | Pago de salario mensual            | 10-05-2026 |
      | ingreso |  28500.00 | Freelance          | Proyecto de diseno web             | 14-06-2026 |
      | ingreso |  12400.00 | Venta de productos | Venta de articulos en linea        | 02-07-2026 |
      | ingreso | 100000.00 | Inversiones        | Ganancias de inversion en acciones | 26-05-2026 |
      | ingreso |  18500.00 | Bonos              | Bonificacion por desempeno laboral | 19-08-2026 |
      | ingreso |   6500.00 | Reembolsos         | Reembolso de gastos de viaje       | 03-01-2026 |
      | ingreso |  42000.00 | Alquiler           | Ingreso por alquiler de propiedad  | 11-04-2026 |
      | ingreso |   8200.00 | Otros              |                                    | 15-09-2026 |
    Entonces la respuesta debe tener un codigo de estado 201
    Y la respuesta debe contener el mensaje "Movimiento registrado exitosamente"
    Y el movimiento debe estar presente en la base de datos con los datos proporcionados

  Escenario: Registro fallido de un ingreso manual debido a datos incompletos
    Dado que el usuario autenticado desea registrar un ingreso manual
    Cuando envio una solicitud POST a "/api/movimientos" con los siguientes datos incompletos:
      | tipo    | monto    | categoria | descripcion                       | fecha      |
      | ingreso |          | Sueldo    | Pago de salario mensual           | 10-05-2026 |
      |         |    12000 | Otros     | Ingreso adicional no especificado | 20-12-2025 |
      | ingreso | 18500.00 | Freelance | Proyecto de diseno web            |            |
    Entonces la respuesta debe tener un codigo de estado 400
    Y la respuesta debe contener el mensaje "Error: Falta informacion obligatoria"
    Y el movimiento no debe estar presente en la base de datos

  Escenario: Registro fallido de un ingreso manual debido a datos invalidos
    Dado que el usuario autenticado desea registrar un ingreso manual
    Cuando envio una solicitud POST a "/api/movimientos" con los siguientes datos invalidos:
      | tipo    | monto     | categoria          | descripcion                 | fecha      |
      | ingreso | -50000.00 | Sueldo             | Pago de salario mensual     | 10-05-2026 |
      | ingreso |         0 | Freelance          | Proyecto de diseno web      | 14-06-2026 |
      | ingreso |           | Venta de productos | Venta de articulos en linea | 02-07-2026 |
    Entonces la respuesta debe tener un codigo de estado 400
    Y la respuesta debe contener el mensaje "Error: Datos invalidos"