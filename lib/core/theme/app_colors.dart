import 'package:flutter/material.dart';

/// Color tokens of the BovinoVision design system, mirrored from the web app
/// (`bovino_vision_frontend/src/index.css`). Green is the action and brand
/// color; brown only describes the animal context (breed) and never an action.
abstract final class AppColors {
  static const green50 = Color(0xFFF1F7F3);
  static const green100 = Color(0xFFE3F0E8);
  static const green200 = Color(0xFFC2E0CD);
  static const green300 = Color(0xFF8CC7A0);
  static const green400 = Color(0xFF57A874);
  static const green500 = Color(0xFF2F8A52);
  static const green600 = Color(0xFF0E703F);
  static const green700 = Color(0xFF1D5738);
  static const green800 = Color(0xFF12452C);
  static const green900 = Color(0xFF0B3A24);

  static const brown100 = Color(0xFFF0E5D9);
  static const brown200 = Color(0xFFE0CBB6);
  static const brown300 = Color(0xFFC6A184);
  static const brown400 = Color(0xFFA87C57);
  static const brown500 = Color(0xFF8A5D3B);
  static const brown600 = Color(0xFF6F4A2C);
  static const brown700 = Color(0xFF563820);
  static const brown800 = Color(0xFF3E2A18);

  static const cream = Color(0xFFF4F3EE);
  static const creamDeep = Color(0xFFE8E6DC);

  static const terracotta100 = Color(0xFFF3E8E0);
  static const terracotta200 = Color(0xFFE0C6B6);
  static const terracotta500 = Color(0xFFAB6641);
  static const terracotta600 = Color(0xFF8F5334);

  static const neutral50 = Color(0xFFFAFAF8);
  static const neutral100 = Color(0xFFF1F1EC);
  static const neutral200 = Color(0xFFE2E2DB);
  static const neutral300 = Color(0xFFCBCBC2);
  static const neutral400 = Color(0xFFA3A39A);
  static const neutral500 = Color(0xFF7C7C73);
  static const neutral600 = Color(0xFF5C5C55);
  static const neutral700 = Color(0xFF42423D);
  static const neutral800 = Color(0xFF2B2B27);
  static const neutral900 = Color(0xFF1A1A17);

  static const success500 = Color(0xFF2F8A52);
  static const successBg = Color(0xFFE3F0E8);
  static const successText = Color(0xFF12452C);

  static const warning500 = Color(0xFFD9822B);
  static const warningBg = Color(0xFFFBEEDC);
  static const warningText = Color(0xFF6E3F0C);

  static const danger500 = Color(0xFFB3372A);
  static const dangerBg = Color(0xFFFBE7E3);
  static const dangerText = Color(0xFF712016);

  static const info500 = Color(0xFF2B6F86);
  static const infoBg = Color(0xFFE2EFF3);
  static const infoText = Color(0xFF113844);

  static const white = Color(0xFFFFFFFF);
}

/// Shadows are tinted with green-700 (`rgb(29, 87, 56)`), never black.
abstract final class AppShadows {
  static const xs = [
    BoxShadow(color: Color.fromRGBO(29, 87, 56, 0.06), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const sm = [
    BoxShadow(color: Color.fromRGBO(29, 87, 56, 0.08), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color.fromRGBO(29, 87, 56, 0.04), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const md = [
    BoxShadow(color: Color.fromRGBO(29, 87, 56, 0.10), offset: Offset(0, 4), blurRadius: 12),
  ];
  static const lg = [
    BoxShadow(color: Color.fromRGBO(29, 87, 56, 0.14), offset: Offset(0, 12), blurRadius: 28),
  ];
}

/// Corner radii used by the web app: controls, cards and list rows.
abstract final class AppRadius {
  static const control = 10.0;
  static const card = 14.0;
  static const row = 12.0;
}
