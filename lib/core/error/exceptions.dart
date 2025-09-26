/// Custom exceptions for the movie recommendation app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class ApiException extends AppException {
  const ApiException(super.message, [super.code]);
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}

class CacheException extends AppException {
  const CacheException(super.message, [super.code]);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

class UserFriendlyException extends AppException {
  const UserFriendlyException(super.message, [super.code]);
}

class LocalStorageException extends AppException {
  const LocalStorageException(super.message, [super.code]);
}