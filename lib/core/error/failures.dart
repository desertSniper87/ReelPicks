/// Failure classes for error handling
abstract class Failure {
  final String message;
  final String? code;
  
  const Failure(this.message, [this.code]);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class ApiFailure extends Failure {
  const ApiFailure(super.message, [super.code]);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure(super.message, [super.code]);
}

class DataFailure extends Failure {
  const DataFailure(super.message, [super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}