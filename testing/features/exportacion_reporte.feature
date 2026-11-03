# language: es

Característica: Exportación de reporte PDF y restricciones de seguridad

  Antecedentes:
    Dado que tengo una cuenta nueva autenticada para probar la exportación

  Escenario: Exportar reporte con alcance solo_propios devuelve PDF
    Cuando solicito el reporte con alcance "solo_propios", fechaDesde "2026-07-01" y fechaHasta "2026-07-31"
    Entonces la respuesta de exportación debe tener un codigo de estado 200
    Y el Content-Type de la respuesta debe ser "application/pdf"

  Escenario: Exportar cuenta completa sin cuenta compartida es denegado
    Cuando solicito el reporte con alcance "cuenta_completa", fechaDesde "2026-07-01" y fechaHasta "2026-07-31"
    Entonces la respuesta de exportación debe tener un codigo de estado 400
    Y la respuesta debe contener el error "La cuenta no pertenece a una cuenta compartida"

  Escenario: Solicitar reporte sin token es no autorizado
    Cuando solicito el reporte sin token con alcance "solo_propios", fechaDesde "2026-07-01" y fechaHasta "2026-07-31"
    Entonces la respuesta de exportación debe tener un codigo de estado 401