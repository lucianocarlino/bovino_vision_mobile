import 'package:flutter/material.dart';

import '../../../core/widgets/brand.dart';
import '../../../core/widgets/page_header.dart';

class LotsScreen extends StatelessWidget {
  const LotsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: pagePadding,
        children: const [PageHeader(title: 'Lotes')],
      );
}
