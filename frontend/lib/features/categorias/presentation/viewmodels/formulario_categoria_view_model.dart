import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/paleta_categorias.dart';

class FormularioCategoriaViewModel extends ChangeNotifier {
  // Para crear: desde Categorías arranca en egreso, que es para lo que más se crean categorías
  // propias; desde "Nuevo movimiento" llega el tipo del movimiento.
  // Para editar: llega la categoría, y arranca con su color (el tipo no se puede cambiar).
  FormularioCategoriaViewModel(this._api, {this._esIngreso = false, this.editando})
      : _color = editando?.color ?? paletaCategorias.first;

  final CategoriaApi _api;
  final Categoria? editando;

  bool _esIngreso;
  String _color;
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

  // Valida y guarda. Devuelve la categoría creada o editada, o null si algo falló.
  Future<Categoria?> guardar(String nombre) async {
    // Al editar, el backend no valida el nombre ni le saca los espacios: lo hacemos acá.
    nombre = nombre.trim();
    _errorNombre = nombre.isEmpty ? 'Ingresá un nombre' : null;
    _error = null;
    if (_errorNombre != null) {
      notifyListeners();
      return null;
    }
    _guardando = true;
    notifyListeners();
    try {
      final editando = this.editando;
      if (editando == null) {
        return await _api.crear(nombre: nombre, esIngreso: _esIngreso, color: _color);
      }
      await _api.editar(editando, nombre: nombre, color: _color);
      return Categoria(id: editando.id, nombre: nombre, color: _color, tipo: editando.tipo, esPredefinida: false);
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
