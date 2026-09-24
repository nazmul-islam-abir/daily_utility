import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/splash/splash_screen.dart';
import 'services/hive_service.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await SettingsService.init();
  await LocaleService.init();
  await NotificationService.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(const DailyUtilityApp());
}

class DailyUtilityApp extends StatelessWidget {
  const DailyUtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SettingsService.instance.revision,
      builder: (context, _, __) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleService.instance.notifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Daily Utility',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: SettingsService.instance.themeMode,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('bn')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
