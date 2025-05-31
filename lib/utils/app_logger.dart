// A simple logger utility to handle logging throughout the app
class AppLogger {
  // Log levels
  static const int _kLogLevelDebug = 0;
  static const int _kLogLevelInfo = 1;
  static const int _kLogLevelWarning = 2;
  static const int _kLogLevelError = 3;

  // Current minimum log level
  static int _currentLogLevel = _kLogLevelDebug;

  // Set the minimum log level
  static void setLogLevel(int level) {
    _currentLogLevel = level;
  }

  // Debug level logging
  static void debug(String message, [dynamic data, StackTrace? stackTrace]) {
    if (_currentLogLevel <= _kLogLevelDebug) {
      print('DEBUG: $message');
      if (data != null) print('DEBUG-DATA: $data');
      if (stackTrace != null) print('DEBUG-STACK: $stackTrace');
    }
  }

  // Info level logging
  static void info(String message, [dynamic data]) {
    if (_currentLogLevel <= _kLogLevelInfo) {
      print('INFO: $message');
      if (data != null) print('INFO-DATA: $data');
    }
  }

  // Warning level logging
  static void warning(String message, [dynamic data, StackTrace? stackTrace]) {
    if (_currentLogLevel <= _kLogLevelWarning) {
      print('WARNING: $message');
      if (data != null) print('WARNING-DATA: $data');
      if (stackTrace != null) print('WARNING-STACK: $stackTrace');
    }
  }

  // Error level logging
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_currentLogLevel <= _kLogLevelError) {
      print('ERROR: $message');
      if (error != null) print('ERROR-DATA: $error');
      if (stackTrace != null) print('ERROR-STACK: $stackTrace');
    }
  }
} 