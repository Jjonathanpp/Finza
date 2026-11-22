import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/l10n/idioma.dart';

class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.monto,
    this.descripcion,
    required this.fecha,
    required this.estado,
    required this.categoria,
    required this.perfilId,
    this.perfilNombre,
    required this.origen,
  });

  final int id;
  final String tipo;
  final double monto;
  final String? descripcion;
  final DateTime fecha;
  final String estado;
  final Categoria categoria;
  final int perfilId;
  final String? perfilNombre;
  final String origen;

  bool get esIngreso => tipo == 'ingreso';

  // Lo que se muestra en la fila. Si la IA falló (ERROR_IA), el backend guarda en la descripción el
  // error de Gemini tal cual ("429 ... on POST request for https://..."): eso no se le muestra a nadie.
  String? get descripcionVisible {
    final texto = descripcion;
    if (estado != 'ERROR_IA' || texto == null) return texto;
    final motivo = texto.replaceFirst('❌ Error de IA:', '').trim();
    final esTecnico = motivo.isEmpty || motivo.contains('request for') || motivo.contains('http') || RegExp(r'^\d{3}\b').hasMatch(motivo);
    return esTecnico ? tr('La IA no pudo analizar el audio. Tocalo para cargarlo a mano o eliminarlo.') : motivo;
  }

  factory Movimiento.fromJson(Map<String, dynamic> json) => Movimiento(
    id: json['id'],
    tipo: json['tipo'],
    monto: (json['monto'] as num).toDouble(),
    descripcion: json['descripcion'],
    fecha: _leerFecha(json['fecha']),
    estado: json['estado'],
    categoria: Categoria.fromJson(json['categoria']),
    perfilId: json['perfilId'],
    perfilNombre: json['perfilNombre'],
    origen: json['origen'] ?? 'MANUAL',
  );

  // El backend manda la fecha como dd-MM-yyyy (ej. 30-09-2026).
  static DateTime _leerFecha(String texto) {
    final partes = texto.split('-');
    return DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );
  }
}