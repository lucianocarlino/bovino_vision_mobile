import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Step heading: 24 px medium text with a bold emphasized word, and a subtitle.
class StepTitle extends StatelessWidget {
  const StepTitle({super.key, required this.lead, required this.emphasis, this.subtitle});

  final String lead;
  final String emphasis;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.neutral800),
            children: [
              TextSpan(text: lead),
              TextSpan(
                text: emphasis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.neutral500)),
        ],
      ],
    );
  }
}

/// "Caravana 0042" with the tag in bold.
class TagLine extends StatelessWidget {
  const TagLine({super.key, required this.identifier});

  final String identifier;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 14, color: AppColors.neutral500),
        children: [
          const TextSpan(text: 'Caravana '),
          TextSpan(
            text: identifier,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.neutral800),
          ),
        ],
      ),
    );
  }
}
