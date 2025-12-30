import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiktok_tutorial/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Avoid plugin / platform channel issues during tests.
    SharedPreferences.setMockInitialValues({});

    // GetX: ensure a clean slate and avoid background work.
    Get.reset();
    Get.testMode = true;
  });

  testWidgets('App builds (smoke test)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // If there were build-time exceptions, the test would fail before this point.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
