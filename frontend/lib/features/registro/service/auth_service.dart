import '../../../core/network/api_client.dart';
import '../models/registro_request.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<void> registrar(RegistroRequest datos) async {
    await _client.post('/api/auth/registro', datos.toJson());
  }
}
