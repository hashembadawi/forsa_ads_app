/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message${details != null ? '\nDetails: $details' : ''}';
}

/// Network related exceptions
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    this.statusCode,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException ($statusCode): $message';
}

/// Validation related exceptions
class ValidationException extends AppException {
  final String field;

  const ValidationException({
    required this.field,
    required super.message,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() => 'ValidationException [$field]: $message';
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() => 'AuthException: $message';
}

/// Storage related exceptions
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() => 'StorageException: $message';
}

/// General application errors
class GeneralException extends AppException {
  const GeneralException({
    required super.message,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() => 'GeneralException: $message';
}