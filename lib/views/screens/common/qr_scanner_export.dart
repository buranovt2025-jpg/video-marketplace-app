// Conditional export for QR scanner
// Uses stub on web, real implementation on mobile
export 'qr_scanner_screen_stub.dart'
    if (dart.library.io) 'qr_scanner_screen.dart';
