import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'Montserrat';

  static ThemeData get lightTheme {
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control));
    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: color, width: width),
        );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green800,
        primary: AppColors.green800,
        onPrimary: AppColors.white,
        secondary: AppColors.green600,
        surface: AppColors.white,
        onSurface: AppColors.neutral800,
        error: AppColors.danger500,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.neutral800,
        displayColor: AppColors.neutral800,
      ),
      dividerColor: AppColors.neutral200,
      dividerTheme: const DividerThemeData(color: AppColors.neutral200, thickness: 1, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.neutral800,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.neutral400, fontSize: 14),
        border: inputBorder(AppColors.neutral600),
        enabledBorder: inputBorder(AppColors.neutral600),
        focusedBorder: inputBorder(AppColors.green600, 2),
        errorBorder: inputBorder(AppColors.danger500),
        focusedErrorBorder: inputBorder(AppColors.danger500, 2),
        disabledBorder: inputBorder(AppColors.neutral300),
        errorStyle: const TextStyle(color: AppColors.danger500, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.green600),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral900,
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 13, color: AppColors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green800,
          shape: controlShape,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
