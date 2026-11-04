class PerfilCuenta {
  const PerfilCuenta({
    required this.id,
    required this.nombre,
    required this.rol,
  });

  final int id;
  final String nombre;
  final String rol;

  factory PerfilCuenta.fromJson(Map<String, dynamic> json) => PerfilCuenta(
    id: json['perfilId'] as int,
    nombre: (json['nombre'] as String?) ?? 'Sin nombre',
    rol: (json['rol'] as String?) ?? '',
  );
}
