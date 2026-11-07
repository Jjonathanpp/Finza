
import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';
import 'package:frontend/features/cuentas_compartidas/data/models/miembro.dart';
 
// Pantalla de miembros (t-11.3.2): la lista con el rol de cada uno y, si sos admin, el
// cambio de rol de los demás. Las reglas son las mismas que valida el backend
// (PerfilService.cambiarRol); acá solo sirven para no ofrecer lo que igual rechazaría.
class MiembrosViewModel extends ChangeNotifier {
  MiembrosViewModel(this._api, {required this.miPerfilId});
 
  final CuentaCompartidaApi _api;
  // Mi perfil en esta cuenta compartida (el de la cuenta activa).
  final int? miPerfilId;
 
  List<Miembro> _miembros = [];
  bool _cargando = false;
  String? _error;
  bool _cerrado = false;
  // Los perfiles a los que se les está cambiando el rol (para la ruedita de esa fila).
  final Set<int> _cambiando = {};
 
  List<Miembro> get miembros => _miembros;
  bool get cargando => _cargando;
  String? get error => _error;
 
  Miembro? get yo => _miembros.where((m) => m.perfilId == miPerfilId).firstOrNull;
 
  // Sale de la lista y no del rol guardado en la cuenta activa: si otro admin me cambió el
  // rol, acá se ve enseguida.
  bool get soyAdmin => yo?.esAdmin ?? false;
 
  int get cantidadAdmins => _miembros.where((m) => m.esAdmin).length;
  int get cantidadMiembros => _miembros.length - cantidadAdmins;
 
  bool esVos(Miembro m) => m.perfilId == miPerfilId;
  bool estaCambiando(Miembro m) => _cambiando.contains(m.perfilId);
 
  // Por qué no se puede cambiar el rol de alguien (para el tooltip); null si se puede.
  String? motivoNoEditable(Miembro m) {
    if (!soyAdmin) return 'Solo los administradores pueden cambiar roles';
    if (esVos(m)) return 'No podés cambiar tu propio rol';
    if (m.esCreador) return 'A quien creó la cuenta compartida no se le puede cambiar el rol';
    return null;
  }
 
  bool puedeCambiarRol(Miembro m) => motivoNoEditable(m) == null;
 
  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }
 
  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
 
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
 
    try {
      _miembros = await _api.listarMiembros();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudieron cargar los miembros';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
 
  // Devuelve el mensaje de error, o null si salió bien. La fila se actualiza en el lugar
  // (sin reordenar la lista, para que no salte mientras la estás mirando).
  Future<String?> cambiarRol(Miembro miembro, String nuevoRol) async {
    if (nuevoRol == miembro.rol || estaCambiando(miembro)) return null;
 
    _cambiando.add(miembro.perfilId);
    notifyListeners();
 
    try {
      await _api.cambiarRol(miembro.perfilId, nuevoRol);
      _miembros = [
        for (final m in _miembros) m.perfilId == miembro.perfilId ? m.conRol(nuevoRol) : m,
      ];
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'No se pudo cambiar el rol';
    } finally {
      _cambiando.remove(miembro.perfilId);
      notifyListeners();
    }
  }
}