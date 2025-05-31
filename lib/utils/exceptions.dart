// Custom exception types for better error handling and user feedback
enum AppExceptionType {
  network,  // Network related errors (no internet, timeouts)
  server,   // Server errors (500, 404, etc)
  auth,     // Authentication errors (401, 403)
  validation, // Data validation errors (400 with field errors)
  unknown   // Unexpected errors
}

// Custom exception class with user-friendly messaging
class AppException implements Exception {
  final String message;
  final String details;
  final AppExceptionType type;

  AppException(
    this.message, {
    this.details = '',
    this.type = AppExceptionType.unknown,
  });

  @override
  String toString() {
    return '$message${details.isNotEmpty ? ' ($details)' : ''}';
  }

  // Returns a user-friendly message based on the exception type
  String getUserFriendlyMessage() {
    switch (type) {
      case AppExceptionType.network:
        return 'Please check your internet connection and try again.';
      case AppExceptionType.server:
        return 'We\'re having trouble reaching our servers. Please try again later.';
      case AppExceptionType.auth:
        return 'You need to sign in or your session has expired. Please sign in again.';
      case AppExceptionType.validation:
        return 'There was a problem with the information provided. Please check and try again.';
      case AppExceptionType.unknown:
      default:
        return 'Something went wrong. Please try again later.';
    }
  }
} 