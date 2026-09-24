import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_utility/main.dart';
import 'package:daily_utility/services/locale_service.dart';
import 'package:daily_utility/services/settings_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    await LocaleService.init();
  });

  testWidgets('App boots into splash', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyUtilityApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
