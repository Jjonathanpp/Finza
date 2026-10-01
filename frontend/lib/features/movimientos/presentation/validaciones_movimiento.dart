// Cada validación devuelve el error para mostrar debajo del campo, o null si está bien.

// La columna del monto es numeric(12,2): más grande que esto, el backend da 500.
const _montoMaximo = 9999999999.99;

// En el campo, el punto es de miles y la coma de centavos ("130.000,50").
// El backend solo entiende punto decimal y sin miles: pasa a "130000.50".
String normalizarMonto(String texto) => texto.trim().replaceAll('.', '').replaceAll(',', '.');

String? validarMonto(String? texto) {
  final monto = normalizarMonto(texto ?? '');
  if (monto.isEmpty) return 'Ingresá un monto';
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(monto)) return 'El monto no es válido';
  if (RegExp(r'\.\d{3,}$').hasMatch(monto)) return 'Máximo 2 decimales';
  final valor = double.parse(monto);
  if (valor <= 0) return 'El monto tiene que ser mayor a cero';
  if (valor > _montoMaximo) return 'El monto es demasiado grande';
  return null;
}

String? validarCategoria(String? categoria) =>
    categoria == null || categoria.isEmpty ? 'Elegí una categoría' : null;
