class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException([
    super.message = 'Invalid email or password. Please verify and try again.',
  ]);
}

class UserNotFoundException extends AppException {
  const UserNotFoundException([
    super.message = 'No account found with this email address.',
  ]);
}

class UserInactiveException extends AppException {
  const UserInactiveException([
    super.message = 'Your staff account is currently inactive. Please contact store admin.',
  ]);
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Unable to connect to server. Please check your internet connection.',
  ]);
}

class SessionExpiredException extends AppException {
  const SessionExpiredException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'An unexpected server error occurred. Please try again later.',
  ]);
}
