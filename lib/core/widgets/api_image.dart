import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../theme/app_colors.dart';

/// Photo stored by the API (`GET /imagenes/{id}`), loaded with the session cookie.
class ApiImage extends StatelessWidget {
  const ApiImage({super.key, required this.imageId, this.fit = BoxFit.cover, this.width, this.height});

  final String? imageId;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final id = imageId;
    if (id == null) return _placeholder();
    final client = context.read<ApiClient>();
    return Image.network(
      client.imageUrl(id),
      headers: client.authHeaders,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(loading: true),
    );
  }

  Widget _placeholder({bool loading = false}) => Container(
        width: width,
        height: height,
        color: AppColors.green50,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.image_outlined, color: AppColors.green300, size: 32),
      );
}
