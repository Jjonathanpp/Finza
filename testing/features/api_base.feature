Característica: Endpoint base de la API

  Escenario: Happy path del endpoint health
    Dado que el backend está corriendo
    Cuando envío una petición GET a "/api/health"
    Entonces recibo una respuesta con código 200
    Y el body tiene los campos status, message y data
    Y el campo status es 200