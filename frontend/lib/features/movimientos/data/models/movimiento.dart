
import 'package:frontend/features/categorias/data/models/categoria.dart';
 
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
    this.cuentaCompartidaId,
    this.cuentaCompartidaNombre,
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
  // De qué cuenta es el perfil que lo cargó: null = el perfil personal.
  final int? cuentaCompartidaId;
  final String? cuentaCompartidaNombre;
  final String origen;
 
  bool get esIngreso => tipo == 'ingreso';
  bool get esPersonal => cuentaCompartidaId == null;
 
  // Para el badge de la vista consolidada: "Personal" o el nombre de la cuenta compartida.
  String get contexto => cuentaCompartidaNombre ?? 'Personal';
 
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
    cuentaCompartidaId: json['cuentaCompartidaId'],
    cuentaCompartidaNombre: json['cuentaCompartidaNombre'],
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
