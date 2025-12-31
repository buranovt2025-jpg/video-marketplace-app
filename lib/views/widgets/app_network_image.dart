import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
    
    // Flutter Web loads images via XHR which is subject to CORS.
    // Some external demo providers frequently fail (CORS/404) and spam console.
    // For prod stability, we skip known-bad hosts on web and show placeholder.
    if (kIsWeb) {
      final uri = Uri.tryParse(u);
      final host = uri?.host.toLowerCase();
      const blockedHosts = <String>{
        'images.unsplash.com',
        'unsplash.com',
        'i.pravatar.cc',
        'pravatar.cc',
        '0.gravatar.com',
        '1.gravatar.com',
        '2.gravatar.com',
        'gravatar.com',
      };
      if (host != null && blockedHosts.contains(host)) {
        return errorWidget ?? _defaultError();
      }
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

