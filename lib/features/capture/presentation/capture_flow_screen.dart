import 'package:flutter/material.dart';

import '../../../core/widgets/brand.dart';
import '../../../core/widgets/page_header.dart';

class CaptureFlowScreen extends StatelessWidget {
  const CaptureFlowScreen({super.key, this.animalId});

  final String? animalId;

  @override
  Widget build(BuildContext context) => ListView(
        padding: pagePadding,
        children: const [PageHeader(title: 'Nueva captura')],
      );
}
