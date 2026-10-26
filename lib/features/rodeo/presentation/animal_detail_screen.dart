import 'package:flutter/material.dart';

import '../../../core/widgets/brand.dart';
import '../../../core/widgets/page_header.dart';

class AnimalDetailScreen extends StatelessWidget {
  const AnimalDetailScreen({super.key, required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context) => ListView(
        padding: pagePadding,
        children: const [PageHeader(title: 'Animal')],
      );
}
