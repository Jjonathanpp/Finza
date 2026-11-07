// Un integrante de la cuenta compartida (GET /api/cuentas-compartidas/miembros, t-11.3.2).
// rol: 'ADMIN' o 'MIEMBRO'. esCreador: a quien creó la cuenta no se le puede cambiar el rol.
class Miembro {
  const Miembro({
    required this.perfilId,
    this.usuarioId,
    required this.nombre,
    required this.rol,
    this.esCreador = false,
  });
 
  final int perfilId;
  final int? usuarioId;
  final String nombre;
  final String rol;
  final bool esCreador;
 
  bool get esAdmin => rol == 'ADMIN';
 
  Miembro conRol(String nuevoRol) => Miembro(
        perfilId: perfilId,
        usuarioId: usuarioId,
        nombre: nombre,
        rol: nuevoRol,
        esCreador: esCreador,
      );
 
  factory Miembro.fromJson(Map<String, dynamic> json) {
    final nombre = json['nombre']?.toString().trim() ?? '';
    return Miembro(
      perfilId: json['perfilId'] as int,
      usuarioId: json['usuarioId'] as int?,
      nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
      rol: json['rol']?.toString() ?? 'MIEMBRO',
      esCreador: json['esCreador'] as bool? ?? false,
    );
  }
}