import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    if (u == null || u.isEmpty) {
      return errorWidget ?? _defaultError();
    }

    return Image.network(
      u,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder ?? _defaultPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _defaultError();
      },
    );
  }

  Widget _defaultPlaceholder() {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultError() {
    return const Center(
      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}

