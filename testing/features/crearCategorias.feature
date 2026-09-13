# language: es
Característica: Creación de categorías
  Como usuario registrado en Finza
  Quiero crear nuevas categorías para mis movimientos
  Para organizar mejor mis gastos e ingresos

  Antecedentes:
    Dado que la API del backend esta activa y lista para recibir peticiones
    Y que el usuario " Juan Perez " esta registrado y autenticado

  Escenario: Creación exitosa de una categoría
    Dado que el usuario autenticado desea crear una nueva categoría con los siguientes datos:
      | nombre             |
      | Entretenimiento    |
      | Salidas con amigos |
      | Viajes             |
      | Juegos de steam    |
    Cuando envio una solicitud POST a "/api/categorias" con esos datos
    Entonces la respuesta debe tener un codigo de estado 201
    Y la respuesta debe contener un mensaje de éxito indicando que la categoría fue creada correctamente
    Y la nueva categoría debe estar presente en la base de datos

  Escenario: Creación fallida de una categoría debido a datos incompletos
    Dado que el usuario autenticado desea crear una nueva categoría con los siguientes datos incompletos:
      | nombre |
      |        |
    Cuando envio una solicitud POST a "/api/categorias" con esos datos incompletos
    Entonces la respuesta debe tener un codigo de estado 400
    Y la respuesta debe contener un mensaje de error indicando que falta información obligatoria
