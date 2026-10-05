// Dónde está el backend. Si no se pasa nada, es esta misma PC (flutter run -d linux).
const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');
