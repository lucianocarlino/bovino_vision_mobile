import 'package:flutter/material.dart';

import '../../core/widgets/brand.dart';
import '../../core/widgets/page_header.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: pagePadding,
        children: const [PageHeader(title: 'Alertas')],
      );
}
