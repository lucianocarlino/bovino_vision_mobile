import 'package:flutter/material.dart';

class AppColors {
  // Paleta primaria agropecuaria y tecnológica
  static const Color primary = Color(0xFF1B5E20);        // Verde bosque profundo
  static const Color primaryLight = Color(0xFF4CAF50);   // Verde campo vibrante
  static const Color primaryDark = Color(0xFF0D3B13);    // Verde oscuro de contraste
  static const Color secondary = Color(0xFF00796B);      // Teal terroso complementario

  // Superficies y fondos optimizados para exterior / visibilidad rural
  static const Color background = Color(0xFFF7F9F7);     // Fondo gris verdoso muy suave
  static const Color surface = Colors.white;             // Fondo de tarjetas
  static const Color surfaceMuted = Color(0xFFEEF2EE);   // Fondos secundarios de chips
  static const Color border = Color(0xFFE0E5DF);         // Borde suave de separación

  // Textos con alto contraste para legibilidad en campo
  static const Color textPrimary = Color(0xFF1B241E);    // Casi negro con matiz verde
  static const Color textSecondary = Color(0xFF5A685E);  // Gris medio para etiquetas
  static const Color textMuted = Color(0xFF8B988F);      // Gris claro para metadatos

  // Estados Offline-First y Conectividad
  static const Color online = Color(0xFF2E7D32);         // Verde conexión activa
  static const Color onlineLight = Color(0xFFE8F5E9);    // Fondo verde claro estado
  static const Color offline = Color(0xFFE65100);        // Naranja alerta modo local
  static const Color offlineLight = Color(0xFFFFF3E0);   // Fondo naranja suave
  static const Color syncSuccess = Color(0xFF2E7D32);    // Sincronización al día
  static const Color syncPending = Color(0xFFF57C00);    // Pendiente de subida
}
