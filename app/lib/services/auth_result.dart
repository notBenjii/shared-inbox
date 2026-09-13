class AuthResult {
  final String token;
  final String username;

  AuthResult(this.token, this.username);

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      json['token'] as String,
      json['username'] as String,
    );
  }
}