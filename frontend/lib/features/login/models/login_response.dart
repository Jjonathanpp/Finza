class LoginResponse {
  final String token;
  final String refreshToken;
  final String email;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      email: json['email'] as String,
    );
  }
}
