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

  // El backend no guarda íconos: hasta que se puedan elegir (T-4.2.2), sale del nombre.
  String get emoji => _emojis[nombre.toLowerCase()] ?? '🏷️';

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        nombre: json['nombre'],
        color: json['color'],
        tipo: json['tipo'],
        esPredefinida: json['esPredefinida'],
      );
}

const _emojis = {
  'sueldo': '💼',
  'freelance': '💻',
  'alquiler': '🏠',
  'inversiones': '📈',
  'otros': '📦',
  'comida': '🍔',
  'transporte': '🚗',
  'servicios': '💡',
  'mascotas': '🐾',
  'suscripciones': '📺',
};
