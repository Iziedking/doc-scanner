/// A small typed result so service calls report success or failure without
/// throwing across layers. The UI matches on it and shows the right state.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.message, {this.cause});
  final String message;
  final Object? cause;
}
