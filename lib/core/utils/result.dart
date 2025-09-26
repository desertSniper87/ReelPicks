import '../error/failures.dart';

/// Result type for handling success and failure cases
abstract class Result<T> {
  const Result();
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;
  
  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as ResultFailure<T>).failure);
    }
  }
}

class Success<T> extends Result<T> {
  final T data;
  
  const Success(this.data);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class ResultFailure<T> extends Result<T> {
  final Failure failure;
  
  const ResultFailure(this.failure);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultFailure<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}