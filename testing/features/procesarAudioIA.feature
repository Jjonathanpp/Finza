# language: es
Característica: Procesamiento de audio con IA y manejo de errores (Parser)
  Como usuario de Finza
  Quiero procesar un audio para extraer los datos de un movimiento
  Para registrar ingresos o egresos rápidamente y saber si la red falla

  Antecedentes:
    Dado que el backend está corriendo
    Y que tengo un archivo de audio de prueba de extensión ".mp3"

  Escenario: Extracción exitosa de datos y test del parser
    Cuando envío una petición POST a la IA en "/api/movimientos/procesar-audio" con el archivo de audio
    Entonces la respuesta de la IA tiene código de estado 200
    Y el mensaje de la IA es "Audio procesado con éxito"
    Y los datos extraídos contienen los campos "tipo", "monto", "categoria", "descripcion" y "fecha"

  Escenario: Manejo de error simulando falta de conexión o saturación (Timeout/503)
    Dado que el servicio de IA de Google está caído o no hay internet
    Cuando envío una petición POST a la IA en "/api/movimientos/procesar-audio" con el archivo de audio
    Entonces la respuesta de la IA tiene código de estado 500
    Y la respuesta debe contener un mensaje de error indicando saturación o falta de conexión