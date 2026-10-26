import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../network/connectivity_service.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';

/// Padding of every screen body: 16 px sides, 24 px top, room at the bottom.
const pagePadding = EdgeInsets.fromLTRB(16, 24, 16, 32);

/// Emblem plus the "Bovino" (brown) "Vision" (green) wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 32, this.fontSize = 18});

  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo-mark.png', width: size, height: size),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            children: const [
              TextSpan(text: 'Bovino', style: TextStyle(color: AppColors.brown600)),
              TextSpan(text: 'Vision', style: TextStyle(color: AppColors.green500)),
            ],
          ),
        ),
      ],
    );
  }
}

/// "En línea" / "Sin conexión" pill driven by [ConnectivityService].
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityService>().isOnline;
    return online
        ? const AppBadge(label: 'En línea', tone: BadgeTone.brand, icon: Icons.wifi)
        : const AppBadge(label: 'Sin conexión', tone: BadgeTone.warning, icon: Icons.wifi_off);
  }
}
