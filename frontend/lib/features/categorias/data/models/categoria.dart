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

  // El backend no guarda íconos: solo las predefinidas tienen uno, según su nombre.
  String? get emoji => esPredefinida ? _emojis[nombre.toLowerCase()] : null;

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        nombre: json['nombre'],
        color: json['color'],
        tipo: json['tipo'],
        esPredefinida: json['esPredefinida'],
      );
}

// Las del catálogo de catalogo.sql (t-4.1.3). "Otros" hay de ingreso y de egreso: comparten el emoji.
const _emojis = {
  'sueldo': '💼',
  'inversiones': '📈',
  'otros': '📦',
  'comida': '🍔',
  'transporte': '🚗',
  'servicios': '💡',
  'supermercado': '🛒',
  'alquiler': '🏠',
  'salud': '💊',
  'educación': '📚',
  'entretenimiento': '🎬',
  'ropa': '👕',
};
