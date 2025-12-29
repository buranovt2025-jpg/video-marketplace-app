import 'package:http/http.dart' as http;

http.Client createHttpClient() {
  // On web, we use the standard http.Client
  // Self-signed certificates must be trusted by the browser
  return http.Client();
}
