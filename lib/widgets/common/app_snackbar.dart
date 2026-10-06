import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Standard Material 3 Floating Snackbar Helper
class AppSnackbar {
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.primary,
      icon: Icons.info_outline_rounded,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
