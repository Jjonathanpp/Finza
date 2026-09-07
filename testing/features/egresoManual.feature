# language: es
Característica: Registro de egresos manualmente
  Como usuario Finza
  Quiero registrarme mis egresos de manera manual
  Para llevar un control de mis finanzas personales

  Antecedentes:
    Dado que la API del backend esta activa y lista para recibir peticiones
    Y que el usuario " Juan Perez " esta registrado y autenticado

  Escenario: Registro exitoso de un movimiento manual
    Dado que el usuario autenticado desea registrar un gasto manual
    Cuando envio una solicitud POST a "/api/movimientos" con los siguientes datos:
      | tipo  | monto     | categoria            | descripcion                         | fecha      |
      | gasto | 600000.00 | Vivienda             | Pago del alquiler mensual           | 10-05-2026 |
      | gasto |  28500.00 | Servicios publicos   | Factura de luz y gas                | 14-06-2026 |
      | gasto |  12400.00 | Mantenimiento        | Articulos de limpieza para el hogar | 02-07-2026 |
      | gasto | 100000.00 | Supermercado         | Compra general de provisiones       | 26-05-2026 |
      | gasto |  18500.00 | Restaurantes         | Cena de fin de semana               | 19-08-2026 |
      | gasto |   6500.00 | Transporte publico   | Recarga de tarjeta SUBE             | 03-01-2026 |
      | gasto |  42000.00 | Vehiculo particular  |                                     | 11-04-2026 |
      | gasto |   8200.00 | Plataformas de viaje |                                     | 15-09-2026 |
    Entonces la respuesta debe tener un codigo de estado 201
    Y la respuesta debe contener el mensaje "Movimiento registrado exitosamente"
    Y el movimiento debe estar presente en la base de datos con los datos proporcionados

  Escenario: Registro fallido de un movimiento manual debido a datos incompletos
    Dado que el usuario autenticado desea registrar un gasto manual
    Cuando envio una solicitud POST a "/api/movimientos" con los siguientes datos incompletos:
      | tipo  | monto    | categoria            | descripcion               | fecha      |
      | gasto |          | Vivienda             | Pago del alquiler mensual | 10-05-2026 |
      |       |    12000 | Plataformas de viaje | Viaje en uber hasta casa  | 20-12-2025 |
      | gasto | 18500.00 | Servicios publicos   | Factura de luz            |            |
    Entonces la respuesta debe tener un codigo de estado 400
    Y la respuesta debe contener el mensaje "Error: Falta informacion obligatoria"
    Y el movimiento no debe estar presente en la base de datos

  Escenario: Registro fallido de un movimiento manual debido a datos invalidos
    Dado que el usuario autenticado desea registrar un gasto manual
    Cuando envio una solicitud POST a "/api/movimientos" con los siguientes datos invalidos:
      | tipo  | monto     | categoria          | descripcion                         | fecha      |
      | gasto | -50000.00 | Vivienda           | Pago del alquiler mensual           | 10-05-2026 |
      | gasto |         0 | Servicios publicos | Factura de luz y gas                | 14-06-2026 |
      | gasto |           | Mantenimiento      | Articulos de limpieza para el hogar | 02-07-2026 |
    Entonces la respuesta debe tener un codigo de estado 400
    Y la respuesta debe contener el mensaje "Error: Datos invalidos"
