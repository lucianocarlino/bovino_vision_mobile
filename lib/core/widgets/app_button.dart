import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { md, lg }

/// Button with the web app's variants (`src/components/buttonStyles.ts`):
/// radius 10, semibold, 18 px icon, 45 % opacity when disabled.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expand;

  /// Shows a spinner in place of the icon and disables the button.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (variant) {
      AppButtonVariant.primary => (AppColors.green800, AppColors.white, null),
      AppButtonVariant.secondary => (AppColors.white, AppColors.neutral800, AppColors.neutral300),
      AppButtonVariant.ghost => (Colors.transparent, AppColors.neutral800, null),
      AppButtonVariant.danger => (AppColors.danger500, AppColors.white, null),
    };
    final isLarge = size == AppButtonSize.lg;
    final enabled = onPressed != null && !loading;
    final hasShadow = variant == AppButtonVariant.primary || variant == AppButtonVariant.danger;

    final leading = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : icon == null
            ? null
            : Icon(icon, size: 18, color: foreground);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: isLarge ? 14 : 13,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: isLarge ? 48 : 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.control),
          boxShadow: hasShadow && enabled ? AppShadows.sm : null,
        ),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isLarge ? 20 : 16),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
