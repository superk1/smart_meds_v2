class AuthSession {
  final String userId;
  final String email;
  final String token;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'token': token,
    };
  }

  factory AuthSession.fromMap(Map<String, dynamic> map) {
    return AuthSession(
      userId: map['userId'] as String,
      email: map['email'] as String,
      token: map['token'] as String,
    );
  }
}
