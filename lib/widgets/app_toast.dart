import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum ToastType { error, success, info }

class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: duration,
        padding: EdgeInsets.zero,
        content: _ToastContent(message: message, type: type),
      ),
    );
  }
}

class _ToastContent extends StatelessWidget {
  final String message;
  final ToastType type;

  const _ToastContent({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      ToastType.error => (AppColors.neonPink, Icons.error_outline_rounded),
      ToastType.success => (
        AppColors.neonCyan,
        Icons.check_circle_outline_rounded,
      ),
      ToastType.info => (AppColors.neonBlue, Icons.info_outline_rounded),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Glowing icon ──────────────────────────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              // ── Message text ──────────────────────────────────────────
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
