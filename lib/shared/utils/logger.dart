import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Logger {
  const Logger._();

  static void debug(
    String message, {
    ProviderBase<Object?>? provider,
    Object? value,
    Object? previousValue,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final providerName = provider?.name ?? provider?.runtimeType.toString();
    final values = <String>[
      if (providerName != null) 'provider=$providerName',
      if (value != null) 'value=$value',
      if (previousValue != null) 'previous=$previousValue',
      if (error != null) 'error=$error',
    ].join(' ');

    developer.log(
      values.isEmpty ? message : '$message: $values',
      name: 'app',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'app',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
