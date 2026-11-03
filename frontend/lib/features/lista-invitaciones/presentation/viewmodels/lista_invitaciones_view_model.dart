import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/lista-invitaciones/data/datasources/invitacion_api.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_enviada.dart';

class ListaInvitacionesViewModel extends ChangeNotifier {
  ListaInvitacionesViewModel(this._api, this._cuentaCompartidaId);

  final InvitacionApi _api;
  final int _cuentaCompartidaId;

  bool _cargando = false;
  String? _error;
  List<InvitacionEnviada> _invitaciones = [];
  bool _cerrado = false;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  bool get cargando => _cargando;
  String? get error => _error;
  List<InvitacionEnviada> get invitaciones => _invitaciones;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _invitaciones = await _api.listar(_cuentaCompartidaId);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
