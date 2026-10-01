import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/paleta_categorias.dart';

class NuevaCategoriaViewModel extends ChangeNotifier {
  // Desde Categorías arranca en egreso, que es para lo que más se crean categorías propias.
  // Desde "Nuevo movimiento" llega el tipo del movimiento.
  NuevaCategoriaViewModel(this._api, {this._esIngreso = false});

  final CategoriaApi _api;

  bool _esIngreso;
  String _color = paletaCategorias.first;
  bool _cerrado = false;
  bool _guardando = false;
  String? _error;
  String? _errorNombre;

  bool get esIngreso => _esIngreso;
  String get color => _color;
  bool get guardando => _guardando;
  String? get error => _error;
  String? get errorNombre => _errorNombre;

  // Si la pantalla se cerró mientras se esperaba al backend, no hay a quién avisar.
  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  void cambiarTipo(bool esIngreso) {
    _esIngreso = esIngreso;
    notifyListeners();
  }

  void elegirColor(String color) {
    _color = color;
    notifyListeners();
  }

  // Valida y guarda. Devuelve la categoría creada, o null si algo falló.
  Future<Categoria?> guardar(String nombre) async {
    // Vacío, el backend responde solo "Error de validación", sin decir qué campo.
    _errorNombre = nombre.trim().isEmpty ? 'Ingresá un nombre' : null;
    _error = null;
    if (_errorNombre != null) {
      notifyListeners();
      return null;
    }
    _guardando = true;
    notifyListeners();
    try {
      return await _api.crear(nombre: nombre, esIngreso: _esIngreso, color: _color);
    } on ApiException catch (e) {
      // 409 es el nombre repetido: el mensaje va abajo del campo, que es lo que hay que corregir.
      if (e.status == 409) {
        _errorNombre = e.message;
      } else {
        _error = e.message;
      }
      return null;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
