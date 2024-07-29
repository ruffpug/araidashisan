import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 本アプリのLogger
Logger get logger => _logger;

Logger _logger = Logger(level: Level.off);

/// Loggerを初期化する。
Future<void> initializeLogger() async {
  _logger = Logger(
    printer: SimplePrinter(printTime: true, colors: true),
    output: ConsoleOutput(),
    level: kDebugMode ? Level.all : Level.off,
  );
  await logger.init;
}
