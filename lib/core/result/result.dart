class Result<T> {
  final T? _value;
  final Exception? _error;

  const Result.success(this._value) : _error = null;
  const Result.failure(this._error) : _value = null;

  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;

  T get value => _value!;
  Exception get error => _error!;
}
