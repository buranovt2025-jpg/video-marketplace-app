import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Centralized policy for remote image URLs on Flutter Web.
///
/// Some demo image hosts frequently fail (CORS/404) and spam the browser console.
/// On web we can proactively skip those hosts and render placeholders instead.
bool shouldLoadNetworkImageUrl(String? url) {
  final u = url?.trim();
  if (u == null || u.isEmpty) return false;

  if (!kIsWeb) return true;

  final uri = Uri.tryParse(u);
  final host = uri?.host.toLowerCase();
  if (host == null || host.isEmpty) return true;

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

  return !blockedHosts.contains(host);
}

/// Returns a [NetworkImage] provider if allowed by [shouldLoadNetworkImageUrl],
/// otherwise returns null (so callers can fall back to an icon/asset).
ImageProvider? networkImageProviderOrNull(String? url) {
  if (!shouldLoadNetworkImageUrl(url)) return null;
  return NetworkImage(url!.trim());
}

