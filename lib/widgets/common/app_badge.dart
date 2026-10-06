import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Clean Pill Badge Chip for statuses, categories, and tags
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  factory AppBadge.stock({
    required int stockQuantity,
    int lowStockAlert = 3,
  }) {
    if (stockQuantity <= 0) {
      return const AppBadge(
        label: 'Out of Stock',
        color: AppColors.error,
        icon: Icons.cancel_outlined,
      );
    } else if (stockQuantity <= lowStockAlert) {
      return AppBadge(
        label: 'Low ($stockQuantity)',
        color: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return AppBadge(
        label: 'In Stock ($stockQuantity)',
        color: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }

  factory AppBadge.role(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const AppBadge(
          label: 'ADMIN',
          color: AppColors.secondary,
          icon: Icons.admin_panel_settings_rounded,
        );
      case 'manager':
        return const AppBadge(
          label: 'MANAGER',
          color: AppColors.accent,
          icon: Icons.supervisor_account_rounded,
        );
      case 'cashier':
      default:
        return const AppBadge(
          label: 'CASHIER',
          color: AppColors.primary,
          icon: Icons.badge_rounded,
        );
    }
  }

  factory AppBadge.gender(String gender) {
    Color c;
    IconData ic;
    switch (gender.toLowerCase()) {
      case 'boy':
        c = const Color(0xFF2563EB); // Blue
        ic = Icons.boy_rounded;
        break;
      case 'girl':
        c = const Color(0xFFDB2777); // Pink
        ic = Icons.girl_rounded;
        break;
      case 'infant':
        c = const Color(0xFF7C3AED); // Purple
        ic = Icons.child_care_rounded;
        break;
      default:
        c = const Color(0xFF0D9488); // Teal
        ic = Icons.people_outline_rounded;
    }
    return AppBadge(
      label: gender,
      color: c,
      icon: ic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
