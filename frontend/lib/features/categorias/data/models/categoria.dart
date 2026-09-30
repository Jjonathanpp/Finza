class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    this.color,
    required this.tipo,
    required this.esPredefinida,
  });

  final int id;
  final String nombre;
  final String? color;
  final String tipo;
  final bool esPredefinida;

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        nombre: json['nombre'],
        color: json['color'],
        tipo: json['tipo'],
        esPredefinida: json['esPredefinida'],
      );
}
