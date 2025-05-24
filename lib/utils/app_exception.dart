class AppException implements Exception {
  final String message;
  final String? details;
  final AppExceptionType type;

  AppException(this.message, {this.details, this.type = AppExceptionType.unknown});

  @override
  String toString() => message;
}

enum AppExceptionType {
  network,
  server,
  validation,
  unknown,
} 