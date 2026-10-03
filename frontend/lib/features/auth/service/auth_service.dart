import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_client.dart';
import '../../login/models/login_request.dart';
import '../../login/models/login_response.dart';
import '../../registro/models/registro_request.dart';

class AuthService {
  final ApiClient _client = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<void> registrar(RegistroRequest datos) async {
    await _client.post('/api/auth/registro', datos.toJson());
  }

  Future<void> login(LoginRequest datos) async {
    final respuesta = await _client.post('/api/auth/login', datos.toJson());
    final loginResponse = LoginResponse.fromJson(respuesta);
    await _tokenStorage.guardar(
      token: loginResponse.token,
      refreshToken: loginResponse.refreshToken,
      email: loginResponse.email,
    );
  }
}
