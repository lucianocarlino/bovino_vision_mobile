import 'package:flutter/material.dart';

import '../../core/widgets/brand.dart';
import '../../core/widgets/page_header.dart';

class PanelScreen extends StatelessWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: pagePadding,
        children: const [PageHeader(title: 'Panel del rodeo')],
      );
}
