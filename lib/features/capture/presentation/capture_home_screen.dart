import 'package:flutter/material.dart';

import '../../../core/widgets/brand.dart';
import '../../../core/widgets/page_header.dart';

class CaptureHomeScreen extends StatelessWidget {
  const CaptureHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: pagePadding,
        children: const [PageHeader(title: 'Captura')],
      );
}
