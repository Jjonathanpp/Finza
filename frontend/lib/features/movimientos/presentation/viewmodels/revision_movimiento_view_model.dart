import 'package:flutter/material.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/validaciones_movimiento.dart';

class RevisionMovimientoViewModel extends ChangeNotifier {
  RevisionMovimientoViewModel(this.movimiento, this._categoriaApi, this._movimientoApi) {
    esIngreso = movimiento.esIngreso;
    fecha = movimiento.fecha;
    categoria = movimiento.categoria.nombre;
  }

  final Movimiento movimiento;
  final CategoriaApi _categoriaApi;
  final MovimientoApi _movimientoApi;

  bool cargando = false;
  String? error;
  String? errorMonto;
  String? errorCategoria;

  late bool esIngreso;
  late DateTime fecha;
  String? categoria;
  List<Categoria> categorias = [];

  List<Categoria> get categoriasDelTipo =>
      categorias.where((c) => c.tipo == (esIngreso ? 'INGRESO' : 'EGRESO')).toList();

  Future<void> cargarCategorias() async {
    try {
      categorias = await _categoriaApi.listar();
      notifyListeners();
    } catch (e) {
      error = 'No se pudieron cargar las categorías';
      notifyListeners();
    }
  }

  void cambiarTipo(bool ingreso) {
    if (esIngreso == ingreso) return;
    esIngreso = ingreso;
    categoria = null; // Reseteamos porque el tipo cambió
    notifyListeners();
  }

  void elegirCategoria(String nombre) {
    categoria = nombre;
    errorCategoria = null;
    notifyListeners();
  }

  void cambiarFecha(DateTime nueva) {
    fecha = nueva;
    notifyListeners();
  }

  Future<bool> descartar() async {
    cargando = true;
    notifyListeners();
    try {
      await _movimientoApi.eliminar(movimiento.id);
      return true;
    } catch (e) {
      error = 'Error al descartar el movimiento';
      cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmar({required String monto, required String descripcion}) async {
    errorMonto = validarMonto(monto);
    errorCategoria = validarCategoria(categoria);

    if (errorMonto != null || errorCategoria != null) {
      notifyListeners();
      return false;
    }

    cargando = true;
    error = null;
    notifyListeners();

    try {
      // 1. Actualizamos los datos modificados
      await _movimientoApi.actualizar(
        id: movimiento.id,
        esIngreso: esIngreso,
        monto: normalizarMonto(monto),
        categoria: categoria!,
        descripcion: descripcion.trim().isEmpty ? null : descripcion.trim(),
        fecha: fecha,
        origen: movimiento.origen,
      );

      // 2. Cambiamos el estado a APROBADO
      await _movimientoApi.cambiarEstado(movimiento.id, 'APROBADO');
      return true;
    } catch (e) {
      error = 'No se pudo confirmar el movimiento. Revisá tu conexión.';
      cargando = false;
      notifyListeners();
      return false;
    }
  }
}