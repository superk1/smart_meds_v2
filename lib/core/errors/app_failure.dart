class AppFailure {
  final String message;

  const AppFailure(this.message);

  @override
  String toString() => 'AppFailure: $message';
}
