class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);
  
  @override
  String toString() => message;
}

class EmailConfirmationRequiredException implements Exception {
  final String email;
  final String message;
  const EmailConfirmationRequiredException(this.email, [this.message = 'Email confirmation required']);
  
  @override
  String toString() => message;
}
