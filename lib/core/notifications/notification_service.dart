import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _initIfNeeded() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _initIfNeeded();
    // If scheduledDate is in the past, show immediately
    final when = scheduledDate.isBefore(DateTime.now()) ? DateTime.now().add(const Duration(seconds: 1)) : scheduledDate;
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    const androidDetails = AndroidNotificationDetails('devent_reminders', 'Event Reminders', channelDescription: 'Reminders for booked events', importance: Importance.max, priority: Priority.high);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: null,
    );
  }

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await _initIfNeeded();
    const androidDetails = AndroidNotificationDetails(
      'devent_updates',
      'Event Updates',
      channelDescription: 'Live notifications for new events and updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
