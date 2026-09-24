import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Wraps `flutter_local_notifications` for the app's one job: fire an
/// optional local reminder N minutes before something is due (a todo, a
/// loan instalment, a bill). Nothing here touches the network — reminders
/// work fully offline since they're scheduled on-device.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    } catch (_) {
      // Falls back to UTC if the timezone database lookup fails — reminders
      // still fire at the right *relative* offset either way.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    // Create the notification channel with custom sound
    const androidChannel = AndroidNotificationChannel(
      'daily_utility_reminders_v2', // Updated ID to ensure sound change is picked up
      'Reminders',
      description: 'Optional reminders you set inside Daily Utility',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );
    await androidImpl?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Deterministic small int id from a string, so the same todo/loan always
  /// maps to the same notification id and can be cancelled/rescheduled.
  static int idFromString(String key) => (key.hashCode & 0x7fffffff) % 100000;

  /// Schedules a single one-off reminder at [fireAt]. If [fireAt] is already
  /// in the past, nothing is scheduled (there's nothing useful to remind).
  /// Returns the notification id used, or null if it wasn't scheduled.
  static Future<int?> scheduleReminder({
    required String idKey,
    required String title,
    required String body,
    required DateTime fireAt,
    String channelId = 'daily_utility_reminders_v2',
    String channelName = 'Reminders',
  }) async {
    await init();
    if (fireAt.isBefore(DateTime.now())) return null;

    final id = idFromString(idKey);
    final tzTime = tz.TZDateTime.from(fireAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Optional reminders you set inside Daily Utility',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'notification_sound.mp3',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    return id;
  }

  static Future<void> cancel(int? notificationId) async {
    if (notificationId == null) return;
    await init();
    await _plugin.cancel(notificationId);
  }
}
