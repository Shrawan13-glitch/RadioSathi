import 'package:flutter/foundation.dart';

class AppLog {
  static final List<String> _logs = [];
  static const int maxLogs = 500;

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    _logs.add(logEntry);
    
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
    
    debugPrint(logEntry);
  }

  static List<String> getLogs() {
    return List.from(_logs);
  }

  static void clear() {
    _logs.clear();
  }
}