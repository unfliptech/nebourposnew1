import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastType { success, error, info }

class _ToastController {
  OverlayEntry? entry;
  Timer? timer;

  void show(
    BuildContext context, {
    required String message,
    required AppToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    entry?.remove();
    timer?.cancel();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final colors = _toastColors(type);
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 24,
        bottom: 32,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                message,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry!);

    timer = Timer(duration, () {
      entry?.remove();
      entry = null;
      timer = null;
    });
  }

  void dispose() {
    timer?.cancel();
    entry?.remove();
    entry = null;
    timer = null;
  }
}

_ToastColors _toastColors(AppToastType type) {
  switch (type) {
    case AppToastType.success:
      return _ToastColors(
        background: const Color(0xFF1D8F4D),
        foreground: Colors.white,
      );
    case AppToastType.error:
      return _ToastColors(
        background: const Color(0xFFE53935),
        foreground: Colors.white,
      );
    case AppToastType.info:
      return _ToastColors(
        background: Colors.white,
        foreground: const Color(0xFF202124),
      );
  }
}

class _ToastColors {
  const _ToastColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

final _toastController = _ToastController();

void showAppToast(
  BuildContext context,
  String message,
  AppToastType type, {
  Duration duration = const Duration(seconds: 3),
}) {
  _toastController.show(
    context,
    message: message,
    type: type,
    duration: duration,
  );
}
