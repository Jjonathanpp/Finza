import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/session/sesion.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/lista-invitaciones/data/datasources/invitacion_api.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_recibida.dart';

// La pantalla que se abre desde el enlace de la invitación (t-11.2.2): carga los datos con el
// token, y acepta o rechaza. Sin sesión no se pide nada (un 401 mandaría al login y se perdería
// la invitación): la pantalla ofrece iniciar sesión y después vuelve sola.
class InvitacionViewModel extends ChangeNotifier {
  InvitacionViewModel(this._api, this.token, {TokenStorage? tokens})
      : _tokens = tokens ?? TokenStorage();

  final InvitacionApi _api;
  final TokenStorage _tokens;
  final String token;

  bool _cargando = true;
  bool _haySesion = true;
  bool _respondiendo = false;
  String? _error;
  InvitacionRecibida? _invitacion;
  bool _cerrado = false;

  bool get cargando => _cargando;
  bool get haySesion => _haySesion;
  bool get respondiendo => _respondiendo;
  String? get error => _error;
  InvitacionRecibida? get invitacion => _invitacion;

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
      _haySesion = tokenVigente(await _tokens.obtenerToken());
      if (!_haySesion) return;
      _invitacion = await _api.detalle(token);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar la invitación';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Devuelve la cuenta compartida a la que se entró, o null si falló (el motivo queda en error).
  Future<Map<String, dynamic>?> aceptar() => _responder(() => _api.aceptar(token));

  // true si se rechazó.
  Future<bool> rechazar() async => await _responder(() async {
        await _api.rechazar(token);
        return true;
      }) ??
      false;

  Future<T?> _responder<T>(Future<T> Function() pedido) async {
    if (_respondiendo) return null;
    _respondiendo = true;
    _error = null;
    notifyListeners();
    try {
      return await pedido();
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'No se pudo responder la invitación';
      return null;
    } finally {
      _respondiendo = false;
      notifyListeners();
    }
  }
}