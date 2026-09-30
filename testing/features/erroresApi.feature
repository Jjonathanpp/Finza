# language: es

Característica: Manejo de errores de la API
  Como equipo de desarrollo
  Quiero que la API responda los errores con el formato común
  Para que el frontend los muestre siempre de la misma forma

  Escenario: Endpoint inexistente
    Dado que el backend está corriendo
    Cuando envío una petición GET a "/api/no-existe"
    Entonces recibo una respuesta con código 404
    Y el body tiene los campos status, message y data
    Y el campo status es 404

  # @pendiente hasta que exista el login con JWT (t-1.4.1): hoy SecurityConfig deja pasar todo.
  @pendiente
  Escenario: Pedido sin token a un endpoint protegido
    Dado que el backend está corriendo
    Cuando envío una petición GET a "/api/categorias?cuentaId=1"
    Entonces recibo una respuesta con código 401
    Y el body tiene los campos status, message y data
    Y el mensaje de la respuesta es "No autorizado"

  @pendiente
  Escenario: Pedido con token a una cuenta ajena
    Dado que inicié sesión con una cuenta nueva
    Y existe otra cuenta registrada
    Cuando pido las categorías de la otra cuenta con mi token
    Entonces recibo una respuesta con código 403
    Y el body tiene los campos status, message y data
