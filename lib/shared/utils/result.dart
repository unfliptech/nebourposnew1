sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Object error, StackTrace? stackTrace) onFailure,
  ) {
    final self = this;
    if (self is Success<T>) {
      return onSuccess(self.value);
    }
    final failure = self as Failure<T>;
    return onFailure(failure.error, failure.stackTrace);
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}
