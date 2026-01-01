import 'dart:io';

/// TEMP (hotfix): accept self-signed certificates.
///
/// WARNING: This disables TLS certificate validation globally.
/// Use only for test/staging and replace with proper CA certs for production.
void installInsecureHttpOverrides() {
  HttpOverrides.global = _InsecureHttpOverrides();
}

class _InsecureHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}

